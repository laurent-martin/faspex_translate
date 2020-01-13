# Faspex demo language pack

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

# Usage

```
faspex_language.rb <in folder> <out folder> <in language> <out language>
```

# Example

```
L=/opt/aspera/faspex/config/locales
./faspex_language.rb $L $L en fr
```

# Setup of IBM Cloud Watson translate

* create a translation service on IBM Cloud
* then get API Key and service URL
* then it shows the "getting started"
* save credentials (full JSON) in a file name: my_translation_service_creds

# Example of command line use of Watson

```
MY_KEY=xkMGjG_jQJ2S0ZZi_OhBoy-lAeJrwHCuu50Zox9QS0Gy
curl -u apikey:$MY_KEY -H 'Accept: application/json' -H 'Content-Type: application/json' 'https://gateway-lon.watsonplatform.net/language-translator/api/v3/translate?version=2018-05-01' -d '{"model_id":"en-cs","text":["There are MY_count_ users."]}'
```

