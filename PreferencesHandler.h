#import <notify.h>
#import <objc/message.h>
#import <SystemConfiguration/CaptiveNetwork.h>

static NSString *const kPreferencesFilePath = @"/var/mobile/Library/Preferences/com.a3tweaks.asphaleia.plist";
#define kPrefsChangedNotification "com.a3tweaks.asphaleia/ReloadPrefs"
 
#define addObserver(c, n) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (c), CFSTR(n), NULL, CFNotificationSuspensionBehaviorCoalesce)
#define loadPreferences() preferencesChangedCallback(NULL, NULL, NULL, NULL, NULL)

#define kSecuredAppsKey @"securedApps"
#define kSecureSwitcherKey @"secureSwitcher"
#define kSecureAppArrangementKey @"preventAppDeletion"
#define kObscureAppContentKey @"obscureAppContent"
#define kUnsecureUnlockToAppKey @"easyUnlockIntoApp"
#define kWifiUnlockKey @"wifiUnlock"
#define kWifiUnlockNetworkKey @"wifiNetwork"
#define kSecureSpotlightKey @"secureSpotlight"
#define kSecurePowerDownKey @"preventPowerOff"
#define kSecureControlCentreKey @"secureCC"
#define kVibrateOnFailKey @"vibrateOnFail"
#define kProtectAllAppsKey @"globalAppSecurity"
#define kDynamicSelectionKey @"dynamicSelection"
#define kAppExitUnlockTimeKey @"timeInterval"
#define kResetAppExitTimerOnLockKey @"ResetTimerOnLock"
#define kDelayAfterLockKey @"delayAfterLock"
#define kDelayAfterLockTimeKey @"timeIntervalLock"

static NSDictionary *prefs = nil;
static BOOL asphaleiaDisabled = NO;
static BOOL appSecurityDisabled = NO;

void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	prefs = [[NSDictionary alloc] initWithContentsOfFile:kPreferencesFilePath];
}

BOOL shouldRequireAuthorisationOnWifi(void) {
	BOOL unlockOnWifi = [prefs objectForKey:kWifiUnlockKey] ? [[prefs objectForKey:kWifiUnlockKey] boolValue] : NO;
	NSString *unlockSSID = [prefs objectForKey:kWifiUnlockNetworkKey] ? [prefs objectForKey:kWifiUnlockNetworkKey] : @"";
	CFArrayRef interfaceArray = CNCopySupportedInterfaces();
	CFDictionaryRef networkInfoDictionary = CNCopyCurrentNetworkInfo((CFStringRef)CFArrayGetValueAtIndex(interfaceArray, 0));
	NSDictionary *ssidList = (__bridge NSDictionary*)networkInfoDictionary;
	NSString *currentSSID = [ssidList valueForKey:@"SSID"];

	if (unlockOnWifi && [currentSSID isEqualToString:unlockSSID])
		return NO;
    return YES;
}

NSInteger appSecurityDelayTimeInterval(void) {
    return [prefs objectForKey:kDelayAfterLockTimeKey] ? [[prefs objectForKey:kDelayAfterLockTimeKey] integerValue] : 10;
}

BOOL shouldDelayAppSecurity(void) {
    return [prefs objectForKey:kDelayAfterLockKey] ? [[prefs objectForKey:kDelayAfterLockKey] boolValue] : NO;
}

BOOL shouldResetAppExitTimerOnLock(void) {
    return [prefs objectForKey:kResetAppExitTimerOnLockKey] ? [[prefs objectForKey:kResetAppExitTimerOnLockKey] boolValue] : NO;
}

NSInteger appExitUnlockTimeInterval(void) {
    return [prefs objectForKey:kAppExitUnlockTimeKey] ? [[prefs objectForKey:kAppExitUnlockTimeKey] integerValue] : 0;
}

BOOL shouldUseDynamicSelection(void) {
	if (!shouldRequireAuthorisationOnWifi() || asphaleiaDisabled || appSecurityDisabled)
		return NO;
    return [prefs objectForKey:kDynamicSelectionKey] ? [[prefs objectForKey:kDynamicSelectionKey] boolValue] : NO;
}

BOOL shouldProtectAllApps(void) {
	if (!shouldRequireAuthorisationOnWifi() || asphaleiaDisabled || appSecurityDisabled)
		return NO;
    return [prefs objectForKey:kProtectAllAppsKey] ? [[prefs objectForKey:kProtectAllAppsKey] boolValue] : NO;
}

BOOL shouldVibrateOnIncorrectFingerprint(void) {
    return [prefs objectForKey:kVibrateOnFailKey] ? [[prefs objectForKey:kVibrateOnFailKey] boolValue] : NO;
}

BOOL shouldSecureControlCentre(void) {
	if (!shouldRequireAuthorisationOnWifi() || asphaleiaDisabled)
		return NO;
    return [prefs objectForKey:kSecureControlCentreKey] ? [[prefs objectForKey:kSecureControlCentreKey] boolValue] : NO;
}

BOOL shouldSecurePowerDownView(void) {
	if (!shouldRequireAuthorisationOnWifi() || asphaleiaDisabled)
		return NO;
    return [prefs objectForKey:kSecurePowerDownKey] ? [[prefs objectForKey:kSecurePowerDownKey] boolValue] : NO;
}

BOOL shouldSecureSpotlight(void) {
	if (!shouldRequireAuthorisationOnWifi() || asphaleiaDisabled)
		return NO;
    return [prefs objectForKey:kSecureSpotlightKey] ? [[prefs objectForKey:kSecureSpotlightKey] boolValue] : NO;
}

BOOL shouldUnsecurelyUnlockIntoApp(void) {
	if (!shouldRequireAuthorisationOnWifi() || asphaleiaDisabled || appSecurityDisabled)
		return YES;

    return [prefs objectForKey:kUnsecureUnlockToAppKey] ? [[prefs objectForKey:kUnsecureUnlockToAppKey] boolValue] : NO;
}

BOOL shouldObscureAppContent(void) {
	if (!shouldRequireAuthorisationOnWifi() || asphaleiaDisabled || appSecurityDisabled)
		return NO;
    return [prefs objectForKey:kObscureAppContentKey] ? [[prefs objectForKey:kObscureAppContentKey] boolValue] : YES;
}

BOOL shouldSecureSwitcher(void) {
	if (!shouldRequireAuthorisationOnWifi() || asphaleiaDisabled)
		return NO;
    return [prefs objectForKey:kSecureSwitcherKey] ? [[prefs objectForKey:kSecureSwitcherKey] boolValue] : NO;
}

BOOL shouldSecureAppArrangement(void) {
	if (!shouldRequireAuthorisationOnWifi() || asphaleiaDisabled)
		return NO;
    return [prefs objectForKey:kSecureAppArrangementKey] ? [[prefs objectForKey:kSecureAppArrangementKey] boolValue] : NO;
}

NSArray *getProtectedApps() {
	if (![prefs objectForKey:kSecuredAppsKey] || !shouldRequireAuthorisationOnWifi() || appSecurityDisabled || asphaleiaDisabled)
		return [NSArray array];

	NSMutableArray *protectedApps = [NSMutableArray array];
	for (NSString *app in [prefs objectForKey:kSecuredAppsKey]) {
		if ([[[prefs objectForKey:kSecuredAppsKey] objectForKey:app] boolValue])
			[protectedApps addObject:app];
	}
	return [NSArray arrayWithArray:protectedApps];
}