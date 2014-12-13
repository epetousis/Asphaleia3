#import <notify.h>
#import <objc/message.h>

static NSString *const preferencesFilePath = @"/var/mobile/Library/Preferences/com.a3tweaks.asphaleia.plist";
#define kPrefsChangedNotification "com.a3tweaks.asphaleia/ReloadPrefs"
 
#define addObserver(c, n) CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (c), CFSTR(n), NULL, CFNotificationSuspensionBehaviorCoalesce)
#define loadPreferences() preferencesChangedCallback(NULL, NULL, NULL, NULL, NULL)

#define kSecuredAppsKey @"securedApps"
#define kSecureSwitcherKey @"secureSwitcher"
#define kSecureAppArrangementKey @"preventAppDeletion"

static NSDictionary *prefs = nil;

static void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	prefs = [[NSDictionary alloc] initWithContentsOfFile:preferencesFilePath];
}

/*static BOOL shouldSecureSwitcher(void) {
    return [prefs objectForKey:kSecureSwitcherKey] ? [[prefs objectForKey:kSecureSwitcherKey] boolValue] : NO;
}*/

static BOOL shouldSecureAppArrangement(void) {
    return [prefs objectForKey:kSecureAppArrangementKey] ? [[prefs objectForKey:kSecureAppArrangementKey] boolValue] : NO;
}

static NSArray *getProtectedApps() {
	if (![prefs objectForKey:kSecuredAppsKey])
		return [NSArray array];

	NSMutableArray *protectedApps = [NSMutableArray array];
	for (NSString *app in [prefs objectForKey:kSecuredAppsKey]) {
		if ([[[prefs objectForKey:kSecuredAppsKey] objectForKey:app] boolValue] == true)
			[protectedApps addObject:app];
	}
	return [NSArray arrayWithArray:protectedApps];
}