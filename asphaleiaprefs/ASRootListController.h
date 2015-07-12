#import <Preferences/PSListController.h>
#import "modalPinVC.h"
#define kPreferencesPath @"/var/mobile/Library/Preferences/com.a3tweaks.asphaleia8.plist"
#define kBundlePath @"/Library/PreferenceBundles/AsphaleiaPrefs.bundle"

#define kPreferencesTemplatePath @"/private/var/mobile/Library/Preferences/%@.plist"
#define PreferencesPath [NSString stringWithFormat:kPreferencesTemplatePath,specifier.properties[@"defaults"]]

@interface ASRootListController : PSListController {
	BOOL _enteredCorrectly;
	modalPinVC *pinVC;
	NSDate *_resignDate;
}
@property BOOL passcodeViewIsTransitioning;
@property BOOL alreadyAnimatedOnce;
@end
