Natural Language Classifier example
===================================


Preparation
-----------

###VCAP_SERVICES

Confirm that the Bluemix environment variable [VCAP_SERVICES](http://www.ibm.com/watson/developercloud/doc/getting_started/gs-variables.shtml#vcapServices) is set.

Otherwise, you should specify :user and :password parameters for each WatsonAPIClient::NaturalLanguageClassifier#new method call in all example scripts.

###Example dataset

Download the example dataset archive from [here](http://hosi.org/a/blog_text.zip) and extract it to examples/NaturalLanguageClassifier/blog_text/.


Training
--------

###Generate Natural Language Classifier object

```
(Example) $ ruby train.rb 2014 2015
```

At first, articles of year 2014 and 2015 are picked out from the dataset, and gathered in train.csv.

Next, an object of NaturalLanguageClassifier is generated and trained by this train.csv.

When all the arguments such as 2014 or 2015 are omitted, the train.csv, which already exists, is used for training as it is.

###Check Natural Language Classifier object status

```
$ ruby classify.rb
```

When classify.rb is called without arguments, the status of the generated classifier object is retrieved.

Please wait a moment until its status will be 'Available'.


Classification
--------------

```
(Example) $ ruby classify.rb '2016/08/*'
```

At this example, articles in August, 2016 are picked out from the dataset, and their themes are classified as follows by the classifier object which has been trained.

```
"top_class"=>"こよみ",
"classes"=>
 [{"class_name"=>"こよみ", "confidence"=>0.4464514057553849},
  {"class_name"=>"雑記", "confidence"=>0.31750749975306036},
  ...
```


Natural Language Classifier object deletion
-------------------------------------------

```
$ ruby delete.rb
```

All the objects that their name are "Blog thema" are deleted.

When classifier_id is specified as an argument, only the object with the specified classifier_id is deleted.


Note
----

According to ['Using your own data to train the Natural Language Classifier'](http://www.ibm.com/watson/developercloud/doc/nl-classifier/data_format.shtml), the maximum total length of a text value is 1024 characters.

However, in the case of multi-byte characters, more limits seem to be severe.

Even if the number of characters is within 1024, when the number of bytes exceeds 1200 or 1300, 'Bad Request' has happened by classification processing.

