SOURCE=source
OUT=.
WATSON_CREDS_FILE=my_translation_service_creds
DOWNLOAD_CREDS_FILE=download_creds
RPM_NAME=ibm-aspera-faspex-4.4.0.176785-0.x86_64.rpm
RPM_URL=https://download.asperasoft.com/download/sw/faspex/4.4.0/$(RPM_NAME)
RPM_FILE=$(SOURCE)/$(RPM_NAME)
TARGET_LANGS=cs ja zh ru de es ar hi he el
TARGET_FILES=$(patsubst %,%.yml,$(TARGET_LANGS))

$(SOURCE):
	mkdir $(SOURCE)
$(OUT):
	mkdir $(OUT)
$(DOWNLOAD_CREDS_FILE):
	@echo "put download credentials for https://download.asperasoft.com in $(DOWNLOAD_CREDS_FILE)"
	@echo "Example:"
	@echo "echo myusername:mypass > $(DOWNLOAD_CREDS_FILE)"
	@exit 1
$(WATSON_CREDS_FILE):
	@echo "put watson translation credentials in "$(WATSON_CREDS_FILE)
	@exit 1
# download RPM $(SOURCE) $(DOWNLOAD_CREDS_FILE)
$(RPM_FILE): 
	curl --user $$(cat $(DOWNLOAD_CREDS_FILE)) -o $(RPM_FILE) $(RPM_URL)
# extract existing languages
$(SOURCE)/en.yml: $(RPM_FILE)
	cd $(SOURCE) && rpm2cpio $(RPM_NAME) | cpio -idv './opt/aspera/faspex/config/locales/*'
	mv $(SOURCE)/opt/aspera/faspex/config/locales/* $(SOURCE)
	rm -fr $(SOURCE)/opt
deploy: $(TARGET_FILES)
	#scp -P 33001 $(TARGET_FILES) laurent@eudemo.asperademo.com:
	#ssh -p 33001 laurent@eudemo.asperademo.com "sudo cp $(TARGET_FILES) /opt/aspera/faspex/config/locales;sudo asctl faspex:restart"
clean:
	echo rm -fr $(SOURCE)
%.yml: $(WATSON_CREDS_FILE) $(SOURCE)/en.yml
	./faspex_language.rb $(WATSON_CREDS_FILE) $(SOURCE) $(OUT) en $@
