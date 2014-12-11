GO_EASY_ON_ME = 1
include theos/makefiles/common.mk

BUNDLE_NAME = AsphaleiaPrefs
AsphaleiaPrefs_FILES = AsphaleiaPrefs.mm AsphaleiaTitleCell.m AsphaleiaPrefsViewControllers.m asphaleiaTVC.m modalPinVC.m
AsphaleiaPrefs_INSTALL_PATH = /Library/PreferenceBundles
AsphaleiaPrefs_FRAMEWORKS = UIKit CoreGraphics AudioToolbox QuartzCore Twitter MessageUI SystemConfiguration
AsphaleiaPrefs_PRIVATE_FRAMEWORKS = Preferences BiometricKit
AsphaleiaPrefs_LDFLAGS = -lactivator -lapplist -L/Users/evanpetousis/theos/lib

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AsphaleiaPrefs.plist$(ECHO_END)
