# IBM Aspera Faspex language pack

## Notice

This tool is not endorsed by IBM.

Using language pack produced by this tool may affect proper Faspex behaviour.

Use at your own risk only after proper testing.

Some translations are provided without warranty.

## Installation

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
faspex_language.rb <watson credential file> <in language file> <out language file>
```

The language file shall be: <2 letters>.yml


# Example

```
./faspex_language.rb my_creds /opt/aspera/faspex/config/locales/en.yml /opt/aspera/faspex/config/locales/cs.yml
```

So, for instance, to use pre-translated packs, copy them from this 
repository, using the appropriate version, to: `<faspex install dir>/config/locales` , example on Linux:

```
cp ja.yml /opt/aspera/faspex/config/locales
asctl faspex:restart
```

# Setup of IBM Cloud Watson translate

* create a translation service on IBM Cloud
* get tyranslation service URL and API Key
* it shows the "getting started"
* save credentials (full JSON) in a file name: my_watson_trans_creds

```
$ cat my_watson_trans_creds
{
  "apikey": "xxxxxxxxxxxxxx",
  "iam_apikey_description": "Auto-generated for key xxxxxxx",
  "iam_apikey_name": "Auto-generated service credentials",
  "iam_role_crn": "crn:v1:bluemix:public:iam::::serviceRole:Manager",
  "iam_serviceid_crn": "crn:v1:bluemix:public:iam-identity::xxxxxx::serviceid:ServiceId-xxxxxxxx",
  "url": "https://api.eu-gb.language-translator.watson.cloud.ibm.com/instances/xxxxxxx"
}
```

# Example of command line use of Watson

```
MY_KEY=xxxxxxxxxxxxxxxx
MY_KEY=$(jq -r .apikey < norepo/my_watson_trans_creds)
curl -u apikey:$MY_KEY -H 'Accept: application/json' -H 'Content-Type: application/json' 'https://gateway-lon.watsonplatform.net/language-translator/api/v3/translate?version=2018-05-01' -d '{"model_id":"en-cs","text":["There are MY_count_ users."]}'
```

