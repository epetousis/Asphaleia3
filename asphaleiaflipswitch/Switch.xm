#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import "../PreferencesHandler.h"

@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

static NSString *nsNotificationString = @"com.a3tweaks.asphaleia/ReloadPrefs";

@interface AsphaleiaFlipswitchSwitch : NSObject <FSSwitchDataSource> {
	BOOL state;
}
@end

@implementation AsphaleiaFlipswitchSwitch

-(instancetype)init {
	AsphaleiaFlipswitchSwitch *flipswitch = [super init];
	if (flipswitch) {
		loadPreferences();
		addObserver(preferencesChangedCallback,kPrefsChangedNotification);
	}
	return flipswitch;
}

- (NSString *)titleForSwitchIdentifier:(NSString *)switchIdentifier {
	return @"Asphaleia 2";
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier {
	return (passcodeEnabled() || touchIDEnabled()) ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier {
	NSMutableDictionary *tempPrefs = [NSMutableDictionary dictionaryWithDictionary:[ASPreferencesHandler sharedInstance].prefs];
	switch (newState) {
	case FSSwitchStateIndeterminate:
		break;
	case FSSwitchStateOn:
        [tempPrefs setObject:[NSNumber numberWithBool:YES] forKey:kPasscodeEnabledKey];
        [tempPrefs setObject:[NSNumber numberWithBool:YES] forKey:kTouchIDEnabledKey];
        [[ASPreferencesHandler sharedInstance].prefs writeToFile:kPreferencesFilePath atomically:YES];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)nsNotificationString, NULL, NULL, YES);
		break;
	case FSSwitchStateOff:
        [tempPrefs setObject:[NSNumber numberWithBool:NO] forKey:kPasscodeEnabledKey];
        [tempPrefs setObject:[NSNumber numberWithBool:NO] forKey:kTouchIDEnabledKey];
        [[ASPreferencesHandler sharedInstance].prefs writeToFile:kPreferencesFilePath atomically:YES];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)nsNotificationString, NULL, NULL, YES);
		break;
	}
	return;
}

@end
