# -*- coding: utf-8 -*-
require 'pp'
require 'watson-api-client'

Encoding.default_external = 'UTF-8'
Encoding.default_internal = 'UTF-8'

service = WatsonAPIClient::NaturalLanguageClassifier.new
JSON.parse(service.getClassifiers.body).first[1].each do |classifier|
  next unless classifier['name'] == 'Blog thema'
  if ARGV.empty?
    pp JSON.parse(service.getStatus(classifier_id:classifier['classifier_id']).body)
  else
    Dir.glob('blog_text/'+ARGV[0]+'.txt') do |path|
      begin
        article  = open(path,'r',&:read).split(/$/)
        text     = article[1..-4].map {|line| line[1..-1].gsub(/<.+?>/,'')}.join("\\n")
        text.sub!(/.$/,'') while text.bytesize > 1024
        expected = article[-2].gsub(/<.+?>/,'').strip.split(/\s*\/\s*/)
        pp [JSON.parse(service.classify_get(classifier_id:classifier['classifier_id'], text:text).body), expected]
      rescue => e
        pp [e, path, text]
      end
    end
    break
  end
end

