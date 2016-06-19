GO_EASY_ON_ME = 1
TARGET = iphone:latest:9.0
ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FrontFlashiOS9
FrontFlashiOS9_FILES = ../ZKSwizzle.m Tweak.xm
FrontFlashiOS9_LIBRARIES = substrate
FrontFlashiOS9_INSTALL_PATH = /Library/Application Support/FrontFlash

include $(THEOS_MAKE_PATH)/library.mk
