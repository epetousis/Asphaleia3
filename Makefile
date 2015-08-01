ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libasphaleiaui
libasphaleiaui_FILES = ASCommon.mm UIAlertView+Blocks.m UIImage+ImageEffects.m NSTimer+Blocks.m ASActivatorListener.m ASControlPanel.mm PreferencesHandler.mm ASTouchIDController.mm ASPasscodeHandler.mm ASTouchWindow.m
libasphaleiaui_FRAMEWORKS = UIKit CoreGraphics Accelerate QuartzCore SystemConfiguration AudioToolbox CoreImage
libasphaleiaui_INSTALL_PATH = /usr/lib
libasphaleiaui_CFLAGS = -fobjc-arc

TWEAK_NAME = Asphaleia
Asphaleia_FILES = Tweak.xm
Asphaleia_FRAMEWORKS = UIKit CoreGraphics Accelerate QuartzCore SystemConfiguration AudioToolbox CoreImage
Asphaleia_LDFLAGS = -L$(THEOS_OBJ_DIR)
Asphaleia_LIBRARIES = asphaleiaui
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
