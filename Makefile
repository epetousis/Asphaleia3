include $(THEOS)/makefiles/common.mk

ARCHS = armv7 armv7s arm64

TARGET = iphone:clang:latest:8.0

TWEAK_NAME = Asphaleia
Asphaleia_FILES = Tweak.xm BTTouchIDController.m ASCommon.m UIAlertView+Blocks.m UIImage+ImageEffects.m
Asphaleia_FRAMEWORKS = UIKit CoreGraphics Accelerate QuartzCore SystemConfiguration
SHARED_CFLAGS = -fobjc-arc

BUNDLE_NAME = AsphaleiaAssets
AsphaleiaAssets_INSTALL_PATH = /Library/Application Support/Asphaleia

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS)/makefiles/bundle.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += asphaleiaprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
