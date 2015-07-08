include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AsphaleiaPhotosProtection
AsphaleiaPhotosProtection_FILES = Tweak.xm
AsphaleiaPhotosProtection_CFLAGS = -fobjc-arc
AsphaleiaPhotosProtection_LDFLAGS = -L"../.theos/obj"
AsphaleiaPhotosProtection_LIBRARIES = asphaleiaui

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 b-"
