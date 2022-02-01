# Faspex version
VERSION=4.4.1
# name of RPM package for Faspex 4
RPM_NAME=ibm-aspera-faspex-4.4.1.178477-0.x86_64.rpm
# where extracted language files will be
SOURCE_FOLDER=local/source/$(VERSION)
# where downloaded RPM shall be placed
RPM_FILE=$(SOURCE_FOLDER)/$(RPM_NAME)
# reference language file
REF_LANGUAGE_FILE=$(SOURCE_FOLDER)/en.yml
# see README
WATSON_CREDS_FILE=local/my_translation_service_creds.json
# languages to generate
TARGET_LANGS=cs ja zh ru de es ar hi he el
TARGET_FILES=$(patsubst %,$(OUTPUT_FOLDER)/%.yml,$(TARGET_LANGS))
OUTPUT_FOLDER=translations/$(VERSION)

# set location of aspera-cli gem if you did not install with gem install
export RUBYLIB=../aspera-cli/lib

all:: $(RPM_FILE) $(WATSON_CREDS_FILE) $(TARGET_FILES)

$(WATSON_CREDS_FILE):
	@echo "Place your Watson translation credentials in:"
	@echo "$(WATSON_CREDS_FILE)"
	@exit 1
$(RPM_FILE):
	@echo "Download Faspex RPM and place here:"
	@echo "$(RPM_FILE)"
	@exit 1
# extract existing languages
$(REF_LANGUAGE_FILE): $(RPM_FILE)
	rpm2cpio $(RPM_FILE) | cpio -idv './opt/aspera/faspex/config/locales/*'
	mv ./opt/aspera/faspex/config/locales/* $(SOURCE_FOLDER)
	rm -fr ./opt
clean:
	echo rm -fr $(SOURCE_FOLDER)
$(OUTPUT_FOLDER)/%.yml: $(REF_LANGUAGE_FILE) $(WATSON_CREDS_FILE)
	mkdir -p $(OUTPUT_FOLDER)
	./faspex_translate.rb $(WATSON_CREDS_FILE) $(REF_LANGUAGE_FILE) $@
deploy: $(TARGET_FILES)
	#scp -P 33001 $(TARGET_FILES) laurent@eudemo.asperademo.com:
	#ssh -p 33001 laurent@eudemo.asperademo.com "sudo cp $(TARGET_FILES) /opt/aspera/faspex/config/locales;sudo asctl faspex:restart"
