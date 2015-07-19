#include <sys/sysctl.h>
#import "PreferencesHandler.h"
#import "Asphaleia.h"
#import <FlipSwitch/FlipSwitch.h>

void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[ASPreferencesHandler sharedInstance].prefs = [NSDictionary dictionaryWithContentsOfFile:kPreferencesFilePath];
	[ASPreferencesHandler sharedInstance].asphaleiaDisabled = !passcodeEnabled() && !touchIDEnabled();
	if ([[objc_getClass("FSSwitchPanel") sharedPanel] stateForSwitchIdentifier:@"com.a3tweaks.asphaleiaflipswitch"] == FSSwitchStateOff)
		[ASPreferencesHandler sharedInstance].asphaleiaDisabled = YES;
	[ASPreferencesHandler sharedInstance].appSecurityDisabled = !passcodeEnabled() && !touchIDEnabled();
}

BOOL shouldRequireAuthorisationOnWifi(void) {
	BOOL unlockOnWifi = [[ASPreferencesHandler sharedInstance].prefs objectForKey:kWifiUnlockKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kWifiUnlockKey] boolValue] : NO;
	NSString *unlockSSIDValue = [[ASPreferencesHandler sharedInstance].prefs objectForKey:kWifiUnlockNetworkKey] ? [[ASPreferencesHandler sharedInstance].prefs objectForKey:kWifiUnlockNetworkKey] : @"";
	NSArray *unlockSSIDs = [unlockSSIDValue componentsSeparatedByString:@", "];
	CFArrayRef interfaceArray = CNCopySupportedInterfaces();
	CFDictionaryRef networkInfoDictionary = CNCopyCurrentNetworkInfo((CFStringRef)CFArrayGetValueAtIndex(interfaceArray, 0));
	NSDictionary *ssidList = (__bridge NSDictionary*)networkInfoDictionary;
	NSString *currentSSID = [ssidList valueForKey:@"SSID"];

	for (NSString *SSID in unlockSSIDs) {
		if (unlockOnWifi && [currentSSID isEqualToString:SSID])
			return NO;
	}
    return YES;
}

BOOL isTouchIDDevice(void) {
    int sysctlbyname(const char *, void *, size_t *, void *, size_t);

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);

    char *answer = (char *)malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);

    NSArray *touchIDModels = @[ @"iPhone6,1", @"iPhone6,2", @"iPhone7,1", @"iPhone7,2", @"iPad5,3", @"iPad5,4", @"iPad4,7", @"iPad4,8", @"iPad4,9" ];

    return [touchIDModels containsObject:results] && [[[objc_getClass("BiometricKit") manager] identities:nil] count] > 0;
}

BOOL passcodeEnabled(void) {
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kPasscodeEnabledKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kPasscodeEnabledKey] boolValue] : NO;
}

BOOL touchIDEnabled(void) {
    return ([[ASPreferencesHandler sharedInstance].prefs objectForKey:kTouchIDEnabledKey] && isTouchIDDevice()) ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kTouchIDEnabledKey] boolValue] : NO;
}

NSString *getPasscode(void) {
	return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kPasscodeKey] ? [[ASPreferencesHandler sharedInstance].prefs objectForKey:kPasscodeKey] : @"0000";
}

BOOL shouldEnableControlPanel(void) {
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kEnableControlPanelKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kEnableControlPanelKey] boolValue] : NO;
}

BOOL shouldAllowControlPanelInApps(void) {
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kControlPanelInAppsKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kControlPanelInAppsKey] boolValue] : NO;
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

BOOL shouldObscureNotifications(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kObscureBannerKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kObscureBannerKey] boolValue] : YES;
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

BOOL shouldSecurePhotos(void) {
	if (!shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return NO;
    return [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecurePhotosKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecurePhotosKey] boolValue] : NO;
}

NSArray *getProtectedAppsNoBullshit(void) {
	NSMutableArray *protectedApps = [NSMutableArray array];
	for (NSString *app in [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey]) {
		if ([[[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey] objectForKey:app] boolValue])
			[protectedApps addObject:app];
	}
	return [NSArray arrayWithArray:protectedApps];
}

NSArray *getProtectedApps(void) {
	if (![[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey] || !shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].appSecurityDisabled || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return [NSArray array];

	NSMutableArray *protectedApps = [NSMutableArray array];
	for (NSString *app in [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey]) {
		if ([[[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey] objectForKey:app] boolValue])
			[protectedApps addObject:app];
	}
	return [NSArray arrayWithArray:protectedApps];
}

NSArray *getProtectedFolders(void) {
	if (![[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredFoldersKey] || !shouldRequireAuthorisationOnWifi() || [ASPreferencesHandler sharedInstance].appSecurityDisabled || [ASPreferencesHandler sharedInstance].asphaleiaDisabled)
		return [NSArray array];

	NSMutableArray *protectedFolders = [NSMutableArray array];
	for (NSString *folder in [[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredFoldersKey]) {
		if ([[[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredFoldersKey] objectForKey:folder] boolValue])
			[protectedFolders addObject:folder];
	}
	return [NSArray arrayWithArray:protectedFolders];
}

@implementation ASPreferencesHandler

+(instancetype)sharedInstance {
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

@end