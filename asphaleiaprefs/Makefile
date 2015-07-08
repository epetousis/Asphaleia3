ARCHS = armv7 armv7s arm64
GO_EASY_ON_ME = 1
include theos/makefiles/common.mk

BUNDLE_NAME = AsphaleiaPrefs
AsphaleiaPrefs_FILES = AsphaleiaPrefs.mm AsphaleiaTitleCell.m AsphaleiaPrefsViewControllers.mm asphaleiaTVC.m modalPinVC.mm TouchIDInfo.mm
AsphaleiaPrefs_INSTALL_PATH = /Library/PreferenceBundles
AsphaleiaPrefs_FRAMEWORKS = UIKit CoreGraphics AudioToolbox QuartzCore Twitter MessageUI SystemConfiguration
AsphaleiaPrefs_PRIVATE_FRAMEWORKS = Preferences BiometricKit
AsphaleiaPrefs_LDFLAGS = -lapplist -L/Users/evanpetousis/theos/lib -lmobilegestalt

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AsphaleiaPrefs.plist$(ECHO_END)
