VERSION=4.4.1
RPM_NAME=ibm-aspera-faspex-4.4.1.178477-0.x86_64.rpm
SOURCE_FOLDER=norepo/source/$(VERSION)
WATSON_CREDS_FILE=norepo/my_translation_service_creds
DOWNLOAD_CREDS_FILE=norepo/download_creds
RPM_URL=https://download.asperasoft.com/download/sw/faspex/$(VERSION)/$(RPM_NAME)
RPM_FILE=$(SOURCE_FOLDER)/$(RPM_NAME)
TARGET_LANGS=cs ja zh ru de es ar hi he el
TARGET_FILES=$(patsubst %,$(OUTPUT_FOLDER)/%.yml,$(TARGET_LANGS))
OUTPUT_FOLDER=translations/$(VERSION)

export RUBYLIB=../asperalm/lib

all:: $(RPM_FILE) $(WATSON_CREDS_FILE) $(TARGET_FILES)

$(DOWNLOAD_CREDS_FILE):
	@echo "put download credentials for https://download.asperasoft.com in:"
	@echo "$(DOWNLOAD_CREDS_FILE)"
	@echo "Example:"
	@echo "echo myusername:mypass > $(DOWNLOAD_CREDS_FILE)"
	@exit 1
$(WATSON_CREDS_FILE):
	@echo "put watson translation credentials in "$(WATSON_CREDS_FILE)
	@exit 1
# download RPM $(SOURCE_FOLDER) $(DOWNLOAD_CREDS_FILE)
$(RPM_FILE): $(DOWNLOAD_CREDS_FILE)
	mkdir -p $(SOURCE_FOLDER)
	curl --user $$(cat $(DOWNLOAD_CREDS_FILE)) -o $(RPM_FILE) $(RPM_URL)
# extract existing languages
$(SOURCE_FOLDER)/en.yml: $(RPM_FILE)
	cd $(SOURCE_FOLDER) && rpm2cpio $(RPM_NAME) | cpio -idv './opt/aspera/faspex/config/locales/*'
	mv $(SOURCE_FOLDER)/opt/aspera/faspex/config/locales/* $(SOURCE_FOLDER)
	rm -fr $(SOURCE_FOLDER)/opt
clean:
	echo rm -fr $(SOURCE_FOLDER)
$(OUTPUT_FOLDER)/%.yml: $(SOURCE_FOLDER)/en.yml $(WATSON_CREDS_FILE)
	mkdir -p $(OUTPUT_FOLDER)
	./faspex_translate.rb $(WATSON_CREDS_FILE) $(SOURCE_FOLDER)/en.yml $@
deploy: $(TARGET_FILES)
	#scp -P 33001 $(TARGET_FILES) laurent@eudemo.asperademo.com:
	#ssh -p 33001 laurent@eudemo.asperademo.com "sudo cp $(TARGET_FILES) /opt/aspera/faspex/config/locales;sudo asctl faspex:restart"
