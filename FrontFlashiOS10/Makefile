GO_EASY_ON_ME = 1
TARGET = iphone:latest
ARCHS = armv7s arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = FrontFlashiOS10
FrontFlashiOS10_FILES = Tweak.xm
FrontFlashiOS10_LIBRARIES = substrate
FrontFlashiOS10_INSTALL_PATH = /Library/Application Support/FrontFlash

include $(THEOS_MAKE_PATH)/library.mk
