ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libasphaleiaui
libasphaleiaui_FILES = ASCommon.mm NSTimer+Blocks.m ASPreferences.mm
libasphaleiaui_FRAMEWORKS = UIKit CoreGraphics Accelerate QuartzCore SystemConfiguration AudioToolbox CoreImage LocalAuthentication Security
libasphaleiaui_INSTALL_PATH = /usr/lib
libasphaleiaui_LDFLAGS = -lrocketbootstrap
libasphaleiaui_CFLAGS = -fobjc-arc

TWEAK_NAME = Asphaleia
Asphaleia_FILES = Tweak.xm ASXPCHandler.mm ASTouchIDController.mm ASAuthenticationController.mm ASAuthenticationAlert.xm ASControlPanel.mm ASPasscodeHandler.mm ASTouchWindow.m ASActivatorListener.mm
Asphaleia_FRAMEWORKS = UIKit CoreGraphics Accelerate QuartzCore SystemConfiguration AudioToolbox CoreImage
Asphaleia_PRIVATE_FRAMEWORKS = AppSupport
Asphaleia_LDFLAGS = -L$(THEOS_OBJ_DIR)
Asphaleia_LIBRARIES = asphaleiaui rocketbootstrap
Asphaleia_CFLAGS = -fobjc-arc

BUNDLE_NAME = AsphaleiaAssets
AsphaleiaAssets_INSTALL_PATH = /Library/Application Support/Asphaleia

include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS)/makefiles/bundle.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += asphaleiaprefs
SUBPROJECTS += asphaleiaphotosprotection
SUBPROJECTS += asphaleiaflipswitch
SUBPROJECTS += asphaleiasettingsprotection
include $(THEOS_MAKE_PATH)/aggregate.mk
