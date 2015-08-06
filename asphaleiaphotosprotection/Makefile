ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AsphaleiaPhotosProtection
AsphaleiaPhotosProtection_FILES = Tweak.xm
AsphaleiaPhotosProtection_FRAMEWORKS = UIKit Security
AsphaleiaPhotosProtection_PRIVATE_FRAMEWORKS = AppSupport
AsphaleiaPhotosProtection_CFLAGS = -fobjc-arc
AsphaleiaPhotosProtection_LDFLAGS = -L"../.theos/obj/debug"
AsphaleiaPhotosProtection_LIBRARIES = asphaleiaui rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk
