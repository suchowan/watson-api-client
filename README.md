watson-api-client - An IBM Watson™ API client
================================================================

[![Gem Version](https://badge.fury.io/rb/watson-api-client.svg)](http://badge.fury.io/rb/watson-api-client)

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

###VisualRecognition example

Last, let's use 'Visual Recognition' service.

    service = WatsonAPIClient::VisualRecognition.new(:version=>'2018-03-19', :user=>'apikey', :password=>'......')
    [
      service.getDetectFaces('url' => 'https://.....'),
      service.detectFaces('images_file' => open('.....jpg','rb'))
    ].each do |result|
      pp JSON.parse(result.body)
    end

####Generation of the VisualRecognition service object
First of all, the instance of the VisualRecognition class has to be generated.
All constructor arguments are passed to the constructor of [RestClient::Resource](http://www.rubydoc.info/gems/rest-client/RestClient/Resource) class except for :version.
Please refer to the document of the rest-client for the details of this hash argument.

Class name called VisualRecognition is the camel case-ized service name of [Watson API Reference](http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/apis/).
:password is the 'apikey' picked out from environment variable VCAP_SERVICES.
Please refer to '[Viewing Bluemix environment variables](https://console.bluemix.net/docs/services/watson/getting-started-variables.html#vcapServices)' for the details of VCAP_SERVICES.

####Visual recognition using VisualRecognition#getDetectFaces and VisualRecognition#detectFaces
Next, by the 'getDetectFaces' and 'detectFaces' method of the VisualRecognition class, we try to recognize examples.
How to set the arguments can be seen at VisualRecognition's [API Reference](https://www.ibm.com/watson/developercloud/visual-recognition/api/v3/curl.html?curl).

This can be seen by opening the [JSON code of Swagger](https://watson-api-explorer.mybluemix.net/listings/alchemy-language-v1.json).

The list of the method of the VisualRecognition class can be seen even by using the following script.

    p WatsonAPIClient::VisualRecognition::API['digest']

The JSON string is stored in the body of the 'getDetectFaces' and 'detectFaces' method response.
When converting this JSON string to a hash object using JSON.parse method, the result of thesemethods can be used variously by your client programs.

###Discovery example

Last, let's use 'Discovery' service.

    service = WatsonAPIClient::Discovery.new(:version=>'2018-08-01', :user=>".....", :password=>".....")

    result = service.listEnvironments()
    pp JSON.parse(result.body)

    result = service.updateEnvironment(
      'environment_id' => '.......',
      'body' => JSON.generate({'name' => 'Tutorial', 'description' => 'description of Tutorial'})
    )
    pp JSON.parse(result.body)

If the server application is a Ruby on Rails application that require 'watson-api-client', and if it is deployed on the Cloud Foundry, the watson-api-client can read environment variable VCAP_SERVICES directly. In this case, the specification of :user and :password are omissible.

###Natural Language Classifier example

Please see [examples/NaturalLanguageClassifier/README.md](https://github.com/suchowan/watson-api-client/tree/master/examples/NaturalLanguageClassifier/README.md).


Additional note
-------
At present this gem is an alpha version and only the normal behavior of a few services are confirmed.
It is welcome when you can cooperate with the confirmation of other various functions.


Credits
-------
Copyright (c) 2015-2018 [Takashi SUGA](http://hosi.org/TakashiSuga.ttl)


Legal
-------
The watson-api-client is released under the MIT license, see [LICENSE](https://github.com/suchowan/watson-api-client/blob/master/LICENSE) for details.

IBM Watson™ and IBM Bluemix™ are trade marks of the IBM corporation.
