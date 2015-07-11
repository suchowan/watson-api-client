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
Instead, you can output to the standard output the actual those list of classes and methods when you run the lib/watson-api-client.rb directly.


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

Let's use the 'Relationship Extraction' service.

    require 'watson-api-client'
    service = WatsonAPIClient::RelationshipExtraction.new(:user=>"xxxxxx",
                                                          :password=>"yyyyy",
                                                          :verify_ssl=>OpenSSL::SSL::VERIFY_NONE)
    result = service.extract('rt'  => 'json',
                             'sid' => 'ie-en-news',
                             'txt' => 'John Smith lives in New York, and he has been living there since 2001.')
    p JSON.parse(result.body)

####The generation of the RelationshipExtraction service object
First of all, the instance of the RelationshipExtraction class has to be generated. 
The constructor argument is passed to the constructor of [RestClient::Resource](http://www.rubydoc.info/gems/rest-client/RestClient/Resource) class.
Please refer to the document of the rest-client for the details of this hash argument.

Class name called RelationshipExtraction is the camel case-ized service name of [Watson API Reference](http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/apis/).
:user and :password are the 'username' and the 'password' picked out from environment variable VCAP_SERVICES.
Please refer to '[Viewing Bluemix environment variables](http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/doc/getting_started/gs-bluemix.shtml#vcapViewing)' for the details of VCAP_SERVICES.

However, when no server application associated with the service exists, 'Show Credentials' link does not appear on the console window.
Therefore, it is necessary to start up a server application even if it is a dummy.

If the server application is a Ruby on Rails application that require 'watson-api-client', and if it is deployed on the Cloud Foundry, the watson-api-client can read environment variable VCAP_SERVICES directly.
In this case, the specification of :user and :password is omissible.

####The extraction of relationship in an example sentence using RelationshipExtraction#extract
Next, by the 'extract' method of the RelationshipExtraction class, we try to extract relationship in an example sentence.
How to set the argument can be seen by clicking on the 'Expand Operations' link of the Watson API Reference 'Relationship Extraction'.
The method name called 'extract' is the nickname corresponding to 'POST /v1/sire/0'.
This can be seen by opening the JSON code of Swagger by clicking on the '[Raw](http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/apis/listings/relationship-extraction)' link of the 'Relationship Extraction' of API Reference window.

The list of the method of the RelationshipExtraction class can be seen even by using the following script.

    p WatsonAPIClient::RelationshipExtraction::API['digest']

Since 'json' is specified as Return type ('rt') in this example, the JSON string is stored in the body of the 'extract' method response.
When converting this JSON string to a hash object using JSON.parse method, the result of Relationship Extraction can be used variously by your client programs.

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

The class name, the method name, and the argument setting rules are the same as that of the case of 'Relationship Extraction' almost.
The rest-client and the watson-api-client judge which of path, query, header, body each argument is used for automatically.


More
-------
At present this gem is an α version and only the normal behavior of RelationshipExtraction and PersonalityInsights are confirmed.
It is welcome when you can cooperate with the confirmation of other various functions.


Credits
-------
Copyright (c) 2015 [Takashi SUGA](http://hosi.org/TakashiSuga.ttl)


Legal
-------
The watson-api-client is released under the MIT license, see [LICENSE](https://github.com/suchowan/watson-api-client/blob/master/LICENSE) for details.

IBM Watson™ and IBM Bluemix™ are trade marks of the IBM corporation.
