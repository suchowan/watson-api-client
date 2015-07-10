# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'watson-api-client'

Gem::Specification.new do |s|
  s.name        = 'watson-api-client'
  s.version     = WatsonAPIClient::VERSION
  s.authors     = ['Takashi SUGA']
  s.email       = ['suchowan@box.email.ne.jp']
  s.homepage    = 'https://github.com/suchowan/watson-api-client'
  s.license     = 'MIT'
  s.summary     = %q{An IBM Watson™ API client}
  s.description = %q{The watson-api-client is a gem to use REST API on the IBM Watson™ Developer Cloud. It wraps the rest-client REST API using Swagger documents retrievable from the Watson API Reference.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 1.9.3'

  # specify any dependencies here; for example:
  # s.add_development_dependency 'rspec'
  s.add_runtime_dependency 'rest-client'
end
