GO_EASY_ON_ME = 1
SDKVERSION = 7.0
ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = FrontFlash
FrontFlash_FILES = Tweak.xm
FrontFlash_FRAMEWORKS = UIKit
FrontFlash_PRIVATE_FRAMEWORKS = GraphicsServices

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = FrontFlashSettings
FrontFlashSettings_FILES = FrontFlashPreferenceController.m NKOColorPickerView.m
FrontFlashSettings_INSTALL_PATH = /Library/PreferenceBundles
FrontFlashSettings_PRIVATE_FRAMEWORKS = Preferences
FrontFlashSettings_FRAMEWORKS = CoreGraphics UIKit

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/FrontFlash.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
