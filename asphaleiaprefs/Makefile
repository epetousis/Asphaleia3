GO_EASY_ON_ME = 1
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AsphaleiaPrefs
AsphaleiaPrefs_FILES = ASRootListController.mm AsphaleiaTitleCell.m ASCreatorsListController.mm ASPasscodeOptionsListController.mm ASAdvancedOptionsListController.mm ASControlPanelListController.mm ASAdvancedSecurityListController.mm ASSecuredItemsListController.mm ASSecuredFoldersListController.mm ASSecuredAppsListController.mm ASSecuredSettingsListController.mm asphaleiaTVC.m modalPinVC.mm TouchIDInfo.mm
AsphaleiaPrefs_INSTALL_PATH = /Library/PreferenceBundles
AsphaleiaPrefs_FRAMEWORKS = UIKit CoreGraphics AudioToolbox QuartzCore Twitter MessageUI SystemConfiguration
AsphaleiaPrefs_PRIVATE_FRAMEWORKS = Preferences
AsphaleiaPrefs_LDFLAGS = -lapplist -lmobilegestalt

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AsphaleiaPrefs.plist$(ECHO_END)
