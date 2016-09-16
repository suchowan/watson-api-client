# -*- coding: utf-8 -*-
require 'pp'
require 'watson-api-client'

Encoding.default_external = 'UTF-8'
Encoding.default_internal = 'UTF-8'

service = WatsonAPIClient::NaturalLanguageClassifier.new
if ARGV.empty?
  JSON.parse(service.getClassifiers.body).first[1].each do |classifier|
    service.delete(classifier_id:classifier['classifier_id']) if classifier['name'] == 'Blog thema'
  end
else
  service.delete(classifier_id:ARGV[0])
end

