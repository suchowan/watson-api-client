require 'json'
require 'openssl'
require 'open-uri'
require 'rest-client'
require 'pp' if __FILE__ == $PROGRAM_NAME

class WatsonAPIClient

  VERSION = '0.0.3'

  class << self

    private

    def retrieve_doc(doc_urls)
      apis  = {}

      # Watson API Explorer
      host1 = doc_urls[:doc_base1][/^https?:\/\/[^\/]+/]
      open(doc_urls[:doc_base1], Options, &:read).scan(/<a class="swagger-list--item-link" href="\/(.+?)".*?>\s*(.+?)\s*<\/a>/i) do
        api = {'path'=>doc_urls[:doc_base1] + $1, 'title'=>$2.sub(/\s*\(.+?\)$/,'')}
        open(api['path'], Options, &:read).scan(/url:\s*'(.+?)'/) do
          api['path'] = host1 + $1
        end
        apis[api['title']] = api
      end
      
      # Watson Developercloud
      host2 = doc_urls[:doc_base2][/^https?:\/\/[^\/]+/]
      open(doc_urls[:doc_base2], Options, &:read).scan(/<li>\s*<img.+data-src=.+?>\s*<h2><a href="(.+?)".*?>\s*(.+?)\s*<\/a><\/h2>\s*<p>(.+?)<\/p>\s*<\/li>/) do
        api = {'path'=>$1, 'title'=>$2, 'description'=>$3}
        next if api['path'] =~ /\.\./
        if apis.key?(api['title'])
          apis[api['title']]['description'] = api['description']
        else
          # Only for Relationship Extraction
          open(doc_urls[:doc_base2] + api['path'], Options, &:read).scan(/<li><a href="(.+?)".*?>API\s+explorer<\/a><\/li>/i) do
            ref = host2 + $1
            open(ref, Options, &:read).scan(/getAbsoluteUrl\("(.+?)"\)/) do
              api['path'] = ref.split('/')[0..-2].join('/') + '/' + $1
            end
          end
          apis[api['title']] = api
        end
      end

      apis
    end

    # for Swagger 2.0
    def listings(apis)
      methods = {}
      digest  = {}
      apis['paths'].each_pair do |path, operations|
        operations.each_pair do |method, operation|
          body = nil
          (operation['parameters']||[]).each do |parameter|
            next unless parameter['in'] == 'body'
            body = parameter['name']
            break
          end
          if operation['operationId'].nil?
            nickname = path
          else  
            nickname = operation['operationId'].sub(/(.)/) {$1.downcase}
          end
          methods[nickname] = {'method'=>method, 'path'=>path, 'operation'=>operation, 'body'=>body}
          digest[nickname]  = {'method'=>method, 'path'=>path, 'summary'=>operation['summary']}
        end
      end
      {'apis'=>apis, 'methods'=>methods, 'digest'=>digest}
    end
  end

  api_docs = {
    :gateway   => 'https://gateway.watsonplatform.net',
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

  Gateway  = api_docs.delete(:gateway)
  Options  = api_docs
  Services = JSON.parse(ENV['VCAP_SERVICES'] || '{}')
  AvailableAPIs = []

  retrieve_doc(doc_urls).each_value do |list|
    AvailableAPIs << list['title'].gsub(/\s+(.)/) {$1.upcase}
    module_eval %Q{
      class #{list['title'].gsub(/\s+(.)/) {$1.upcase}} < self
        Service = superclass::Services['#{list['title'].sub(/\s+/,'_').downcase}']
        RawDoc  = "#{list['path']}"

        class << self
          alias :_const_missing :const_missing

          def const_missing(constant)
            if constant == :API
              const_set(:API, listings(JSON.parse(open(RawDoc, superclass::Options, &:read))))
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
  # @option options [String] :username     USER ID (default: the username described in VCAP_SERVICES)
  # @option options [String] :password     USER Password (default: the password described in VCAP_SERVICES)
  # @option options [Object] other_options Other options are passed to RestClient::Resource.new[http://www.rubydoc.info/gems/rest-client/RestClient/Resource] as it is. 
  #
  # @note VCAP_SERVICES[http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/doc/getting_started/gs-bluemix.shtml#vcapViewing] is IBM Bluemix™ environment variable.
  #
  def initialize(options={})
    self.class::API['methods'].each_pair do |method, definition|
      self.class.module_eval %Q{define_method("#{method}",
        Proc.new {|options={}| rest_access_#{definition['body'] ? 'with' : 'without'}_body("#{method}", options)}
      )} unless respond_to?(method)
    end
    credential = self.class::Service ? self.class::Service.first['credentials'] : {}
    if options[:url]
      @url   = options.delete(:url)
    elsif credential['url']
      @url   = credential['url']
    else
      @url   = Gateway + self.class::API['apis']['basePath']
    end
    @options = {:user=>credential['username'], :password=>credential['password']}.merge(options)
    @service = RestClient::Resource.new(@url, @options)
  end

  private

  def rest_access_without_body(method, options={})
    path, access = swagger_info(method, options)
    @service[path].send(access, options)
  end

  def rest_access_with_body(method, options={})
    path, access = swagger_info(method, options)
    body = options.delete(self.class::API['methods'][method.to_s]['body'])
    @service[path].send(access, body, options)
  end

  def swagger_info(method, options)
    spec   = self.class::API['methods'][method.to_s]
    lacked = []
    spec['operation']['parameters'].each do |parameter|
      lacked << parameter['name'] if parameter['required'] && !options[parameter['name']]
    end
    raise ArgumentError, "Parameter(s) '#{lacked.join(', ')}' required, see #{self.class::RawDoc}." unless lacked.empty?
    [spec['path'].gsub(/\{(.+?)\}/) {options.delete($1)}, spec['method']]
  end
end
