require 'json'
require 'openssl'
require 'open-uri'
require 'rest-client'
require 'pp' if __FILE__ == $PROGRAM_NAME

class WatsonAPIClient

  VERSION = '0.0.6'

  class Alchemy < self; end

  class << self

    private

    def retrieve_doc(doc_urls)
      apis  = {}

      # Watson API Explorer
      host1 = doc_urls[:doc_base1][/^https?:\/\/[^\/]+/]
      open(doc_urls[:doc_base1], Options, &:read).scan(/<a class="swagger-list--item-link" href="\/(.+?)".*?>\s*(.+?)\s*<\/a>/i) do
        begin
          api = {'path'=>doc_urls[:doc_base1] + $1, 'title'=>$2.sub(/\s*\(.+?\)$/,'')}
          open(api['path'], Options, &:read).scan(/url:\s*'(.+?)'/) do
            api['path'] = host1 + $1
          end
          apis[api['title']] = api
        rescue OpenURI::HTTPError
        end
      end

      # Watson Developercloud
      host2 = doc_urls[:doc_base2][/^https?:\/\/[^\/]+/]
      open(doc_urls[:doc_base2], Options, &:read).scan(/<li>\s*<img.+data-src=.+?>\s*<h2><a href="(.+?)".*?>\s*(.+?)\s*<\/a><\/h2>\s*<p>(.+?)<\/p>\s*<\/li>/) do
        api = {'path'=>$1, 'title'=>$2, 'description'=>$3}
        apis[api['title']]['description'] = api['description'] if api['path'] !~ /\.\./ && apis.key?(api['title'])
      end

      apis
    end

    # for Swagger 2.0
    def listings(apis)
      methods = Hash.new {|h,k| h[k] = {}}
      digest  = Hash.new {|h,k| h[k] = {}}
      apis['paths'].each_pair do |path, operations|
        operations.each_pair do |accsess, operation|
          body = nil
          (operation['parameters']||[]).each do |parameter|
            next unless parameter['in'] == 'body'
            body = parameter['name']
            break
          end
          nickname = (operation['operationId'] || path.split('/').last) #.sub(/(.)/) {$1.downcase}
          nickname = 'delete' unless nickname =~ /\A[_a-z]/i
          methods[nickname][accsess.downcase] = {'path'=>path, 'operation'=>operation, 'body'=>body}
          digest[nickname][accsess.downcase]  = {'path'=>path, 'summary'=>operation['summary']}
        end
      end
      {'apis'=>apis, 'methods'=>methods, 'digest'=>digest}
    end
  end

  api_docs = {
    :gateway   => 'https://gateway.watsonplatform.net',
    :gateway_a => 'https://gateway-a.watsonplatform.net',
    :doc_base1 => 'https://watson-api-explorer.mybluemix.net/',
    :doc_base2 => 'http://www.ibm.com/watson/developercloud/doc/',
    :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
  }
  JSON.parse(ENV['WATSON_API_DOCS'] || '{}').each_pair do |key, value|
    api_docs[key.to_sym] = value
  end
  doc_urls = {
    :doc_base1 => api_docs.delete(:doc_base1),
    :doc_base2 => api_docs.delete(:doc_base2)
  }
  Gateways = {
    :gateway   => api_docs.delete(:gateway),
    :gateway_a => api_docs.delete(:gateway_a)
  }
  Options  = api_docs
  Services = JSON.parse(ENV['VCAP_SERVICES'] || '{}')
  DefaultParams = {:user=>'username', :password=>'password'}
  AvailableAPIs = []

  retrieve_doc(doc_urls).each_value do |list|
    AvailableAPIs << list['title'].gsub(/\s+(.)/) {$1.upcase}
    klass, env =
      case list['title']
      when /^Alchemy/; ['Alchemy',         'alchemy_api'                        ]
      when /^Visual/ ; ['Alchemy',         'watson_vision_combined'             ]
      else           ; ['WatsonAPIClient', list['title'].sub(/\s+/,'_').downcase]
      end
    module_eval %Q{
      class #{list['title'].gsub(/\s+(.)/) {$1.upcase}} < #{klass}
        Service = WatsonAPIClient::Services['#{env}']
        RawDoc  = "#{list['path']}"

        class << self
          alias :_const_missing :const_missing

          def const_missing(constant)
            if constant == :API
              const_set(:API, listings(JSON.parse(open(RawDoc, WatsonAPIClient::Options, &:read))))
            else
              _const_missing(constant)
            end
          end
        end
        pp [self, 'See ' + RawDoc, API['digest']] if '#{__FILE__}' == '#{$PROGRAM_NAME}'
      end
    }
  end

  # All subclass constructors use following hash parameter - 
  #
  # @param [Hash] options See following..
  # @option options [String] :url          API URL (default: the url described in listings or VCAP_SERVICES)
  # @option options [String] :user         USER ID (default: the username described in VCAP_SERVICES)
  # @option options [String] :password     USER Password (default: the password described in VCAP_SERVICES)
  # @option options [Object] other_options Other options are passed to RestClient::Resource.new[http://www.rubydoc.info/gems/rest-client/RestClient/Resource] as it is. 
  #
  # @note VCAP_SERVICES[http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/doc/getting_started/gs-bluemix.shtml#vcapViewing] is IBM Bluemix™ environment variable.
  #
  def initialize(options={})
    set_variables(options)
    @url   ||= Gateways[:gateway] + self.class::API['apis']['basePath']
    @options = {}
    self.class.superclass::DefaultParams.each_pair do |sym, key|
      @options[sym] = @credential[key] if @credential.key?(key)
    end
    @options.update(options)
    @service = RestClient::Resource.new(@url, @options)
  end

  private

  def set_variables(options)
    self.class::API['methods'].each_pair do |method, definition|
      self.class.module_eval %Q{define_method("#{method}",
        Proc.new {|options={}| rest_access_#{definition[definition.keys.first]['body'] ? 'with' : 'without'}_body("#{method}", options)}
      )} unless respond_to?(method)
    end
    @credential = self.class::Service ? self.class::Service.first['credentials'] : {}
    if options.key?(:url)
      @url = options.delete(:url)
    elsif @credential.key?('url')
      @url = @credential['url']
    end
  end

  def rest_access_without_body(method, options={})
    path, access = swagger_info(method, options)
    options = { :params => options } if access == 'get'
    @service[path].send(access, options)
  end

  def rest_access_with_body(method, options={})
    path, access, definition = swagger_info(method, options)
    body = options.delete(definition[definition.keys.first]['body'])
    @service[path].send(access, body, options)
  end

  def swagger_info(method, options)
    definition = self.class::API['methods'][method.to_s]
    spec   = definition[definition.keys.first]
    lacked = []
    spec['operation']['parameters'].each do |parameter|
      lacked << parameter['name'] if parameter['required'] && !options[parameter['name']]
    end
    raise ArgumentError, "Parameter(s) '#{lacked.join(', ')}' required, see #{self.class::RawDoc}." unless lacked.empty?
    [spec['path'].gsub(/\{(.+?)\}/) {options.delete($1)}, definition.keys.first, definition]
  end

  #
  # for Alchemy API
  #
  class Alchemy < self

    DefaultParams  = %w(apikey api_key)

    def initialize(options={})
      set_variables(options)
      @url ||= (Gateways[:gateway_a] + self.class::API['apis']['basePath']).sub('/alchemy-api','')
      @apikey = {}
      self.class.superclass::DefaultParams.each do |key|
        @apikey[key] = @credential[key] if @credential.key?(key)
        @apikey[key] = options.delete(key.to_sym) if options.key?(key.to_sym)
      end
      @options = options
      @service = RestClient::Resource.new(@url, @options)
    end

    private

    def swagger_info(method, options)
      definition = self.class::API['methods'][method.to_s]
      access = (options.delete(:access) || definition.keys.first).downcase
      options.update(@apikey)
      [definition[access]['path'].gsub(/\{(.+?)\}/) {options.delete($1)}, access, definition]
    end
  end
end
