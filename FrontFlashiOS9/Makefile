GO_EASY_ON_ME = 1
TARGET = iphone:9.0
ARCHS = armv7 arm64

include ../theos/makefiles/common.mk

TWEAK_NAME = FrontFlashiOS9
FrontFlashiOS9_FILES = ../ZKSwizzle.m Tweak.xm
#FrontFlashiOS9_FILES = Tweak.modern.xm
FrontFlashiOS9_FRAMEWORKS = CoreMedia #UIKit
FrontFlashiOS9_PRIVATE_FRAMEWORKS = Celestial
FrontFlashiOS9_INSTALL_PATH = /Library/Application Support/FrontFlash

include $(THEOS_MAKE_PATH)/tweak.mk
