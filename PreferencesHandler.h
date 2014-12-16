#import <notify.h>
#import <objc/message.h>
#import <SystemConfiguration/CaptiveNetwork.h>

static NSString *const preferencesFilePath = @"/var/mobile/Library/Preferences/com.a3tweaks.asphaleia.plist";
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

static NSDictionary *prefs = nil;

static void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	prefs = [[NSDictionary alloc] initWithContentsOfFile:preferencesFilePath];
}

static BOOL shouldRequireAuthorisationOnWifi(void) {
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

static BOOL shouldSecurePowerDownView(void) {
	if (!shouldRequireAuthorisationOnWifi())
		return NO;
    return [prefs objectForKey:kSecurePowerDownKey] ? [[prefs objectForKey:kSecurePowerDownKey] boolValue] : NO;
}

static BOOL shouldSecureSpotlight(void) {
	if (!shouldRequireAuthorisationOnWifi())
		return NO;
    return [prefs objectForKey:kSecureSpotlightKey] ? [[prefs objectForKey:kSecureSpotlightKey] boolValue] : NO;
}

static BOOL shouldUnsecurelyUnlockIntoApp(void) {
	if (!shouldRequireAuthorisationOnWifi())
		return YES;

    return [prefs objectForKey:kUnsecureUnlockToAppKey] ? [[prefs objectForKey:kUnsecureUnlockToAppKey] boolValue] : NO;
}

static BOOL shouldObscureAppContent(void) {
	if (!shouldRequireAuthorisationOnWifi())
		return NO;
    return [prefs objectForKey:kObscureAppContentKey] ? [[prefs objectForKey:kObscureAppContentKey] boolValue] : YES;
}

static BOOL shouldSecureSwitcher(void) {
	if (!shouldRequireAuthorisationOnWifi())
		return NO;
    return [prefs objectForKey:kSecureSwitcherKey] ? [[prefs objectForKey:kSecureSwitcherKey] boolValue] : NO;
}

static BOOL shouldSecureAppArrangement(void) {
	if (!shouldRequireAuthorisationOnWifi())
		return NO;
    return [prefs objectForKey:kSecureAppArrangementKey] ? [[prefs objectForKey:kSecureAppArrangementKey] boolValue] : NO;
}

static NSArray *getProtectedApps() {
	if (![prefs objectForKey:kSecuredAppsKey] || !shouldRequireAuthorisationOnWifi())
		return [NSArray array];

	NSMutableArray *protectedApps = [NSMutableArray array];
	for (NSString *app in [prefs objectForKey:kSecuredAppsKey]) {
		if ([[[prefs objectForKey:kSecuredAppsKey] objectForKey:app] boolValue])
			[protectedApps addObject:app];
	}
	return [NSArray arrayWithArray:protectedApps];
}