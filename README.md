watson-api-client - An IBM Watson™ API client
================================================================

[![Gem Version](https://badge.fury.io/rb/watson-api-client.svg)](http://badge.fury.io/rb/watson-api-client)
[![Build Status](https://travis-ci.org/blueboxjesse/watson-api-client.svg?branch=master)](https://travis-ci.org/blueboxjesse/watson-api-client)

The [watson-api-client](http://rubygems.org/gems/watson-api-client) is a gem to use REST API on the IBM Watson™ Developer Cloud.

It wraps the [rest-client](https://rubygems.org/gems/rest-client) REST API using [Swagger](http://swagger.io/) documents retrievable from the [Watson API Reference](https://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/apis/).


Installation
------------

The watson-api-client gem can be installed by running:

    gem install watson-api-client

Since watson-api-client is dependent on the rest-client, when the rest-client is not installed, the rest-client is also installed automatically.


Documentation
-------------

The simple API documentation for the watson-api-client is available on [RubyDoc.info](http://rubydoc.info/gems/watson-api-client).

However, most of the classes and methods of this gem are not described in the above document because they are dynamically defined.
Instead, you can output to the standard output the actual those list of classes and methods when you run the lib/watson-api-client.rb directly, or
you can also use the following method to view a list of known APIs:

```
require 'watson-api-client'

puts WatsonAPIClient::AvailableAPIs
```

Source Code
-----------

The source code for the watson-api-client is available on [GitHub](https://github.com/suchowan/watson-api-client).


Example Usage
-------------

###Preparation

The watson-api-client is a gem to use REST API on the IBM Watson™ Developer Cloud.
To enable these API, you have to do the user registration to the IBM Bluemix™ beforehand, make the services effective, and be relating them to your application.
For more information, refer to 'Getting Started' in '[Table of Contents for Services Documentation](http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/doc/)'.

###Relationship Extraction example

The Watson Relationship Extraction Beta was deprecated on July 27th, 2016, and Relationship Extraction functionality has been merged into AlchemyLanguage.

Let's use the [Relationship Extraction functionality in 'AlchemyLanguage'](https://www.ibm.com/watson/developercloud/doc/alchemylanguage/migration.shtml) service.

    require 'watson-api-client'
    service = WatsonAPIClient::AlchemyLanguage.new(:apikey=>"......",
                                                   :verify_ssl=>OpenSSL::SSL::VERIFY_NONE)
    result = service.URLGetTypedRelations('model'      => 'en-news',      # model:      'en-news',
                                          'url'        => 'www.cnn.com',  # url:        'www.cnn.com',
                                          'outputMode' => 'json')         # outputMode: 'json')
    p JSON.parse(result.body)

####Generation of the AlchemyLanguage service object
First of all, the instance of the AlchemyLanguage class has to be generated. 
The constructor argument is passed to the constructor of [RestClient::Resource](http://www.rubydoc.info/gems/rest-client/RestClient/Resource) class.
Please refer to the document of the rest-client for the details of this hash argument.

Class name called AlchemyLanguage is the camel case-ized service name of [Watson API Reference](http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/apis/).
:apikey is the 'apikey' picked out from environment variable VCAP_SERVICES.
Please refer to '[Viewing Bluemix environment variables](http://www.ibm.com/watson/developercloud/doc/getting_started/gs-variables.shtml#vcapServices)' for the details of VCAP_SERVICES.

If the server application is a Ruby on Rails application that require 'watson-api-client', and if it is deployed on the Cloud Foundry, the watson-api-client can read environment variable VCAP_SERVICES directly.
In this case, the specification of :apikey is omissible.

####Extraction of relationship in an example site using AlchemyLanguage#URLGetTypedRelations
Next, by the 'URLGetTypedRelations' method of the AlchemyLanguage class, we try to extract relationship in an example site.
How to set the arguments can be seen at Alchemy's [API Reference](https://www.ibm.com/watson/developercloud/alchemy-language/api/v1/#relations).

This can be seen by opening the [JSON code of Swagger](https://watson-api-explorer.mybluemix.net/listings/alchemy-language-v1.json).

The list of the method of the AlchemyLanguage class can be seen even by using the following script.

    p WatsonAPIClient::AlchemyLanguage::API['digest']

Since 'json' is specified as output mode type ('outputMode') in this example, the JSON string is stored in the body of the 'URLGetTypedRelations' method response.
When converting this JSON string to a hash object using JSON.parse method, the result of URLGetTypedRelations can be used variously by your client programs.

###Personality Insights example

Next, let's use 'Personality Insights'.

    service = WatsonAPIClient::PersonalityInsights.new(:user=>"xxxxxx",
                                                       :password=>"yyyyy",
                                                       :verify_ssl=>OpenSSL::SSL::VERIFY_NONE)
    result = service.profile(
      'Content-Type'     => "text/plain",
      'Accept'           => "application/json",
      'Accept-Language'  => "en",
      'Content-Language' => "en",
      'body'             => open('https://raw.githubusercontent.com/suchowan/watson-api-client/master/LICENSE',
                                 :ssl_verify_mode=>OpenSSL::SSL::VERIFY_NONE))
    p JSON.parse(result.body)

The class name, the method name, and the argument setting rules are the same as that of the case of 'AlchemyLanguage' almost.
The rest-client and the watson-api-client judge which of path, query, header, body each argument is used for automatically.

###Visual Recognition example

Last, let's use 'Visual Recognition'.

    service = WatsonAPIClient::VisualRecognition.new(:api_key=>"...", :version=>'2016-05-20')
    [
      service.detect_faces('url'=>'https://example.com/example.jpg'),
      service.detect_faces('url'=>'https://example.com/example.jpg', :access=>'get'),
      service.detect_faces_get('url'=>'https://example.com/example.jpg'),
      service.detect_faces('image_file' => open('face.png','rb')),
      service.detect_faces('image_file' => open('face.png','rb'), :access=>'post'),
      service.detect_faces_post('image_file' => open('face.png','rb'))
    ].each do |result|
      pp JSON.parse(result.body)
    end

Please be careful about the difference in the spellings of :apikey and :api_key.

The 'detect_faces' method comes to work in both 'get' access and 'post' access.
When being ambiguous, it's judged by the kind of designated parameters automatically.


Additional note at the release of the version 0.0.3
-------
The documents which 'watson-api-client' referred to have changed in [February 2016](https://github.com/suchowan/watson-api-client/issues/1).


(1) The JSON file which held the list of APIs emptied.

(2) The version of Swagger which describes API specifications went up from 1.2 to 2.0.


They may be linked to the release of the IBM Watson for Japanese language.

The new version 0.0.3 corresponding to them was released provisionally.
Concerning about (1) in the version 0.0.3, the locations of JSON files which describe API specification are acquired from contents of web pages for human using regular expressions.

Essentially, as well as former versions, the location of the API documents should be readable with JSON file.
I will request to the IBM to revive the JSON file which held the list of APIs.

At present this gem is an alpha version and only the normal behavior of RelationshipExtraction(functionality), PersonalityInsights, and VisualRecognition are confirmed.
It is welcome when you can cooperate with the confirmation of other various functions.


Credits
-------
Copyright (c) 2015-2016 [Takashi SUGA](http://hosi.org/TakashiSuga.ttl)


Legal
-------
The watson-api-client is released under the MIT license, see [LICENSE](https://github.com/suchowan/watson-api-client/blob/master/LICENSE) for details.

IBM Watson™ and IBM Bluemix™ are trade marks of the IBM corporation.
