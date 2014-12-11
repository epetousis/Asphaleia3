GO_EASY_ON_ME = 1
ARCHS = armv7 arm64
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Asphaleia
Asphaleia_LIBRARIES = applist activator mobilegestalt
Asphaleia_FILES = Asphaleia.mm modalPinVC.m asphaleiaTVC.m
Asphaleia_INSTALL_PATH = /Library/PreferenceBundles
Asphaleia_FRAMEWORKS = UIKit CoreGraphics AudioToolbox QuartzCore Twitter MessageUI SystemConfiguration
Asphaleia_PRIVATE_FRAMEWORKS = Preferences BiometricKit
Asphaleia_LDFLAGS = -lactivator -lapplist -L/opt/theos/lib

ADDITIONAL_OBJCFLAGS = -fobjc-arc

include /opt/theos/makefiles/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Asphaleia.plist$(ECHO_END)
