TARGET = iphone:clang:9.0:8.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FrontFlashiOS8
FrontFlashiOS8_FILES = Tweak.xm
FrontFlashiOS8_FRAMEWORKS = UIKit
FrontFlashiOS8_PRIVATE_FRAMEWORKS = GraphicsServices
FrontFlashiOS8_EXTRA_FRAMEWORKS = CydiaSubstrate
FrontFlashiOS8_INSTALL_PATH = /Library/Application Support/FrontFlash

include $(THEOS_MAKE_PATH)/library.mk
