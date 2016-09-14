# -*- coding: utf-8 -*-
require 'pp'
require 'watson-api-client'
require './file2csv' unless ARGV.empty?

Encoding.default_external = 'UTF-8'
Encoding.default_internal = 'UTF-8'

service = WatsonAPIClient::NaturalLanguageClassifier.new
pp JSON.parse(service.create(training_metadata: JSON.generate(language: 'ja', name: 'Blog thema'),
                             training_data: open('train.csv', 'r')).body)
