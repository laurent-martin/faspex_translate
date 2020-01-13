SOURCE=source
RPM_NAME=ibm-aspera-faspex-4.4.0.176785-0.x86_64.rpm
RPM_URL=https://download.asperasoft.com/download/sw/faspex/4.4.0/$(RPM_NAME)
RPM_FILE=$(SOURCE)/$(RPM_NAME)

$(SOURCE):
	mkdir $(SOURCE)
download_creds:
	@echo "put download credentials for https://download.asperasoft.com in download_creds"
	@echo "Example:"
	@echo "echo myusername:mypass > download_creds"
	@exit 1
# download RPM
$(RPM_FILE): $(SOURCE) download_creds
	curl --user $$(cat download_creds) -o $(RPM_FILE) $(RPM_URL)
# extract existing languages
$(SOURCE)/en.yml: $(RPM_FILE)
	rm -fr $(SOURCE)
	mkdir -p $(SOURCE)
	rpm2cpio $(RPM_NAME) | (cd $(SOURCE) && cpio -idv './opt/aspera/faspex/config/locales/*')
	mv $(SOURCE) $(SOURCE)/* $(SOURCE)
	rm -fr $(SOURCE)/opt
deploy:
	scp -P 33001 cs.yml ja.yml zh.yml ru.yml de.yml es.yml ar.yml hi.yml he.yml el.yml laurent@eudemo.asperademo.com:
	ssh -p 33001 laurent@eudemo.asperademo.com "sudo cp cs.yml ja.yml zh.yml ru.yml de.yml es.yml ar.yml hi.yml he.yml el.yml /opt/aspera/faspex/config/locales;sudo asctl faspex:restart"
clean:
	rm -fr $(SOURCE)
t:
	./faspex_language.rb $(SOURCE) $(SOURCE) en cs
	./faspex_language.rb $(SOURCE) $(SOURCE) en ja
	./faspex_language.rb $(SOURCE) $(SOURCE) en zh
	./faspex_language.rb $(SOURCE) $(SOURCE) en ru
	./faspex_language.rb $(SOURCE) $(SOURCE) en de
	./faspex_language.rb $(SOURCE) $(SOURCE) en es
	./faspex_language.rb $(SOURCE) $(SOURCE) en ar
	./faspex_language.rb $(SOURCE) $(SOURCE) en hi
	./faspex_language.rb $(SOURCE) $(SOURCE) en he
	./faspex_language.rb $(SOURCE) $(SOURCE) en el
