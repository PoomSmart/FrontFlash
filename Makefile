GO_EASY_ON_ME = 1
TARGET = iphone:latest:6.0
DEBUG = 0
PACKAGE_VERSION = 1.6-7

include $(THEOS)/makefiles/common.mk

AGGREGATE_NAME = FrontFlash
SUBPROJECTS = FrontFlashiOS456 FrontFlashiOS7 FrontFlashiPadiOS7 FrontFlashiOS8 FrontFlashiPadiOS8 FrontFlashiOS9 FrontFlashiPadiOS9

include $(THEOS_MAKE_PATH)/aggregate.mk

TWEAK_NAME = FrontFlash
FrontFlash_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = FrontFlashSettings
FrontFlashSettings_FILES = FrontFlashPreferenceController.m NKOColorPickerView.m
FrontFlashSettings_INSTALL_PATH = /Library/PreferenceBundles
FrontFlashSettings_PRIVATE_FRAMEWORKS = Preferences
FrontFlashSettings_FRAMEWORKS = CoreGraphics Social UIKit

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/FrontFlash.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
