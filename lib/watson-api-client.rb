require 'json'
require 'openssl'
require 'open-uri'
require 'rest-client'
require 'pp' if __FILE__ == $PROGRAM_NAME

class WatsonAPIClient

  VERSION = '0.0.1'

  api_docs = {
    :base => 'https://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/apis/',
    :path => 'listings/api-docs.json',
    :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
  }
  JSON.parse(ENV['WATSON_API_DOCS'] || '{}').each_pair do |key, value|
    api_docs[key.to_sym] = value
  end

  Services = JSON.parse(ENV['VCAP_SERVICES'] || '{}')
  Base     = api_docs.delete(:base)
  path     = api_docs.delete(:path)
  Options  = api_docs
  listings = JSON.parse(open(Base + path, Options).read)

  listings['apis'].each do |list|
    module_eval %Q{
      class #{list['path'].gsub(/[-_\/](.)/) {$1.upcase}} < self
        Service = superclass::Services['#{list['path'][1..-1].gsub(/-/, '_')}']
        RawDoc  = "#{Base + listings['basePath'] + list['path']}"

        class << self
          alias :_const_missing :const_missing

          def const_missing(constant)
            if constant == :API
              const_set(:API, listings(JSON.parse(open(RawDoc, superclass::Options).read)))
            else
              _const_missing(constant)
            end
          end
        end
        pp [self, 'See ' + RawDoc, API['digest']] if '#{__FILE__}' == '#{$PROGRAM_NAME}'
      end
    }
  end

  class << self
    def listings(apis)
      methods = {}
      digest  = {}
      apis['apis'].each do |api|
        api['operations'].each do |operation|
          body = nil
          (operation['parameters']||[]).each do |parameter|
            next unless parameter['paramType'] == 'body'
            body = parameter['name']
            break
          end
          nickname = operation['nickname'].sub(/(.)/) {$1.downcase}
          methods[nickname] = {'path'=>api['path'], 'operation'=>operation, 'body'=>body}
          digest[nickname]  = {'method'=>operation['method'], 'path'=>api['path'], 'summary'=>operation['summary']}
        end
      end
      {'apis'=>apis, 'methods'=>methods, 'digest'=>digest}
    end
    private :listings
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
    credential = self.class::Service ? self.class::Service.first['credentials'] : {}
    if options[:url]
      @url   = options.delete(:url)
    elsif credential['url']
      @url   = credential['url']
    else
      @url   = self.class::API['apis']['basePath']
      @url  += self.class::API['apis']['resourcePath'] unless @url.index(self.class::API['apis']['resourcePath'])
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
    [spec['path'].gsub(/\{(.+?)\}/) {options.delete($1)}, spec['operation']['method'].downcase]
  end

  alias :_method_missing :method_missing

  def method_missing(method, *args, &block)
    definition = self.class::API['methods'][method.to_s]
    if definition
      self.class.module_eval %Q{
        def #{method}(options={})
          rest_access_#{definition['body'] ? 'with' : 'without'}_body("#{method}", options)
        end
      }
      send(method, *args, &block)
    else
      _method_missing(method, *args, &block)
    end
  end
end
