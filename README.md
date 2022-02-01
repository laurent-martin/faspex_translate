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
gem install aspera-cli
```

# Usage

```
faspex_language.rb <watson credential file> <in language file> <out language file>
```

The language file shall be: <2 letters>.yml

The 2 letters are based on watson model:
https://cloud.ibm.com/docs/language-translator?topic=language-translator-translation-models

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

* If you do not already have one, create an account on: [IBM Cloud](https://www.ibm.com/cloud) (There is a free tier)
* Navigate to the [Translation Service](https://cloud.ibm.com/catalog/services/language-translator)
* Create a translation service
* Navigate to `Service credentials`
* save credentials (JSON) in file: `local/my_translation_service_creds.json`

(The script uses the API Key and URL from the credential file)

```bash
cat local/my_translation_service_creds.json
```

```output
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
LANGUAGE_TRANSLATOR_APIKEY=$(jq -r .apikey < local/my_translation_service_creds.json)
LANGUAGE_TRANSLATOR_URL=$(jq -r .url < local/my_translation_service_creds.json)
curl -u apikey:$LANGUAGE_TRANSLATOR_APIKEY -H 'Accept: application/json' -H 'Content-Type: application/json' ${LANGUAGE_TRANSLATOR_URL}'/v3/translate?version=2018-05-01' -d '{"model_id":"en-cs","text":["There are MY_count_ users."]}'
```

