This is not an official tool.
This shall not be used in a production environment.
Provided to ease Sales when language is required, for demo of what's possible.

requires ruby > 2.0

```
yum install ruby ruby-devel rubygems gcc
```

or on Faspex do: 

```
export PATH=/opt/aspera/faspex/vendor/ruby/bin:$PATH
```

then:

```
gem install asperalm
```

Usage:

```
./faspex_language.rb /opt/aspera/faspex/config/locales en fr
```

To use IBM Cloud Watson translate:

* create a translation service on IBM Cloud
* then get API Key and service URL
* then it shows the "getting started"
* save credentials (full JSON) in a file name: my_translation_service_creds
