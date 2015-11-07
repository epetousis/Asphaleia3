ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AsphaleiaSettingsProtection
AsphaleiaSettingsProtection_FILES = Tweak.xm
AsphaleiaSettingsProtection_FRAMEWORKS = UIKit
AsphaleiaSettingsProtection_CFLAGS = -fobjc-arc
AsphaleiaSettingsProtection_LDFLAGS = -L"../.theos/obj/debug"
AsphaleiaSettingsProtection_LIBRARIES = asphaleiaui

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences"
