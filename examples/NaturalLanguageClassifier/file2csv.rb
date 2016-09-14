# -*- coding: utf-8 -*-
require 'fileutils'
require 'csv'

Encoding.default_external = 'UTF-8'
Encoding.default_internal = 'UTF-8'

train_csv = CSV.generate do |csv|
  ARGV.each do |year|
    Dir.glob("blog_text/#{year}/**/*.txt") do |path|
      article = open(path, 'r', &:read).split(/$/)
      text    = article[1..-4].map {|line| line[1..-1].gsub(/<.+?>/,'')}.join("\\n")
      text.sub!(/.$/,'') while text.bytesize > 1024
      klass   = article[-2].gsub(/<.+?>/,'').split(/\s*\/\s*/).last.strip
      csv << [text, klass]
    end
  end
end

File.open('train.csv', 'w') do |file|
  file.write(train_csv)
end
