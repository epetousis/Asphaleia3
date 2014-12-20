#import "PreferencesHandler.h"

void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[ASPreferencesHandler sharedInstance].prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:kPreferencesFilePath];
}

BOOL shouldRequireAuthorisationOnWifi(void) {
	BOOL unlockOnWifi = [[ASPreferencesHandler sharedInstance].prefs objectForKey:kWifiUnlockKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kWifiUnlockKey] boolValue] : NO;
	NSString *unlockSSID = [[ASPreferencesHandler sharedInstance].prefs objectForKey:kWifiUnlockNetworkKey] ? [[ASPreferencesHandler sharedInstance].prefs objectForKey:kWifiUnlockNetworkKey] : @"";
	CFArrayRef interfaceArray = CNCopySupportedInterfaces();
	CFDictionaryRef networkInfoDictionary = CNCopyCurrentNetworkInfo((CFStringRef)CFArrayGetValueAtIndex(interfaceArray, 0));
	NSDictionary *ssidList = (__bridge NSDictionary*)networkInfoDictionary;
	NSString *currentSSID = [ssidList valueForKey:@"SSID"];

	if (unlockOnWifi && [currentSSID isEqualToString:unlockSSID])
		return NO;
    return YES;
}

NSInteger appSecurityDelayTimeInterval(void) {
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kDelayAfterLockTimeKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kDelayAfterLockTimeKey] integerValue] : 10;
}

BOOL shouldDelayAppSecurity(void) {
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kDelayAfterLockKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kDelayAfterLockKey] boolValue] : NO;
}

BOOL shouldResetAppExitTimerOnLock(void) {
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kResetAppExitTimerOnLockKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kResetAppExitTimerOnLockKey] boolValue] : NO;
}

NSInteger appExitUnlockTimeInterval(void) {
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kAppExitUnlockTimeKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kAppExitUnlockTimeKey] integerValue] : 0;
}

BOOL shouldUseDynamicSelection(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kDynamicSelectionKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kDynamicSelectionKey] boolValue] : NO;
}

BOOL shouldProtectAllApps(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kProtectAllAppsKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kProtectAllAppsKey] boolValue] : NO;
}

BOOL shouldVibrateOnIncorrectFingerprint(void) {
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] boolValue] : NO;
}

BOOL shouldSecureControlCentre(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecureControlCentreKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecureControlCentreKey] boolValue] : NO;
}

BOOL shouldSecurePowerDownView(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecurePowerDownKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecurePowerDownKey] boolValue] : NO;
}

BOOL shouldSecureSpotlight(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecureSpotlightKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecureSpotlightKey] boolValue] : NO;
}

BOOL shouldUnsecurelyUnlockIntoApp(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled)
		return YES;

    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kUnsecureUnlockToAppKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kUnsecureUnlockToAppKey] boolValue] : NO;
}

BOOL shouldObscureAppContent(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kObscureAppContentKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kObscureAppContentKey] boolValue] : YES;
}

BOOL shouldSecureSwitcher(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecureSwitcherKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecureSwitcherKey] boolValue] : NO;
}

BOOL shouldSecureAppArrangement(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecureAppArrangementKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecureAppArrangementKey] boolValue] : NO;
}

NSArray *getProtectedApps() {
	if (![[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey] || !shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].appSecurityDisabled || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return [NSArray array];

	NSMutableArray *protectedApps = [NSMutableArray array];
	for (NSString *app in [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey]) {
		if ([[[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey] objectForKey:app] boolValue])
			[protectedApps addObject:app];
	}
	return [NSArray arrayWithArray:protectedApps];
}

@implementation ASPreferencesHandler

static ASPreferencesHandler *sharedCommonObj;

+(instancetype)sharedInstance {
    @synchronized(self) {
        if (!sharedCommonObj)
            sharedCommonObj = [[ASPreferencesHandler alloc] init];
    }

    return sharedCommonObj;
}

@end