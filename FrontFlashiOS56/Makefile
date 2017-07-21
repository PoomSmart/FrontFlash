TARGET = iphone:clang:latest:5.0
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FrontFlashiOS56
FrontFlashiOS56_FILES = Tweak.xm
FrontFlashiOS56_FRAMEWORKS = UIKit
FrontFlashiOS56_EXTRA_FRAMEWORKS = CydiaSubstrate
FrontFlashiOS56_INSTALL_PATH = /Library/Application Support/FrontFlash

include $(THEOS_MAKE_PATH)/library.mk
