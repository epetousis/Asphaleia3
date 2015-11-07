ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AsphaleiaPhotosProtection
AsphaleiaPhotosProtection_FILES = Tweak.xm
AsphaleiaPhotosProtection_FRAMEWORKS = UIKit
AsphaleiaPhotosProtection_PRIVATE_FRAMEWORKS = AppSupport
AsphaleiaPhotosProtection_CFLAGS = -fobjc-arc
AsphaleiaPhotosProtection_LDFLAGS = -L"../.theos/obj/debug"
AsphaleiaPhotosProtection_LIBRARIES = asphaleiaui rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk
