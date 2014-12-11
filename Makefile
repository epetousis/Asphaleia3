include $(THEOS)/makefiles/common.mk

ARCHS = armv7 armv7s arm64

TARGET = iphone:clang:latest:8.0

TWEAK_NAME = Asphaleia
Asphaleia_FILES = Tweak.xm BTTouchIDController.m ASCommon.m
Asphaleia_FRAMEWORKS = UIKit CoreGraphics
SHARED_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
