RPM=ibm-aspera-faspex-4.4.0.176785-0.x86_64.rpm

get: $(RPM)
	curl --user asperainternal:heyinternalonly -o $(RPM) https://download.asperasoft.com/download/sw/faspex/4.4.0/ibm-aspera-faspex-4.4.0.176785-0.x86_64.rpm
x:
	rm -fr source
	mkdir -p source
	rpm2cpio $(RPM) | (cd source && cpio -idv './opt/aspera/faspex/config/locales/*')
deploy:
	scp -P 33001 cs.yml ja.yml zh.yml ru.yml de.yml es.yml ar.yml hi.yml he.yml el.yml laurent@eudemo.asperademo.com:
	ssh -p 33001 laurent@eudemo.asperademo.com "sudo cp cs.yml ja.yml zh.yml ru.yml de.yml es.yml ar.yml hi.yml he.yml el.yml /opt/aspera/faspex/config/locales;sudo asctl faspex:restart"
clean:
	rm -fr source
	rm -f faspex.loc faspex_template.po
t:
	./faspex_language.rb source/opt/aspera/faspex/config/locales en cs
	./faspex_language.rb source/opt/aspera/faspex/config/locales en ja
	./faspex_language.rb source/opt/aspera/faspex/config/locales en zh
	./faspex_language.rb source/opt/aspera/faspex/config/locales en ru
	./faspex_language.rb source/opt/aspera/faspex/config/locales en de
	./faspex_language.rb source/opt/aspera/faspex/config/locales en es
	./faspex_language.rb source/opt/aspera/faspex/config/locales en ar
	./faspex_language.rb source/opt/aspera/faspex/config/locales en hi
	./faspex_language.rb source/opt/aspera/faspex/config/locales en he
	./faspex_language.rb source/opt/aspera/faspex/config/locales en el
# curl -H 'Accept: application/json' -H 'Content-Type: application/json' -u apikey:xkMGjG_jQJ2S0ZZi_zxOyI-lAeJrwHCuu50Zox9QS0Gy https://gateway-lon.watsonplatform.net/'language-translator/api/v3/translate?version=2018-05-01' -d '{"model_id":"en-cs","text":["There are MY_count_ users."]}'
# https://cloud.ibm.com/docs/services/language-translator?topic=language-translator-translation-models
