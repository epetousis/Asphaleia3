#import <notify.h>
#import <objc/message.h>
#import <SystemConfiguration/CaptiveNetwork.h>

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
#define kControlPanelInAppsKey @"controlPanelAllowedInApps"
#define kEnableControlPanelKey @"controlPanel"
#define kPasscodeKey @"passcode"
#define kPasscodeEnabledKey @"simplePasscode"
#define kTouchIDEnabledKey @"touchID"

static NSString *const kPreferencesFilePath = @"/var/mobile/Library/Preferences/com.a3tweaks.asphaleia8.plist";

void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
BOOL shouldRequireAuthorisationOnWifi(void);
BOOL isTouchIDDevice(void);
BOOL passcodeEnabled(void);
BOOL touchIDEnabled(void);
NSString *getPasscode(void);
BOOL shouldEnableControlPanel(void);
BOOL shouldAllowControlPanelInApps(void);
NSInteger appSecurityDelayTimeInterval(void);
BOOL shouldDelayAppSecurity(void);
BOOL shouldResetAppExitTimerOnLock(void);
NSInteger appExitUnlockTimeInterval(void);
BOOL shouldUseDynamicSelection(void);
BOOL shouldProtectAllApps(void);
BOOL shouldVibrateOnIncorrectFingerprint(void);
BOOL shouldSecureControlCentre(void);
BOOL shouldSecurePowerDownView(void);
BOOL shouldSecureSpotlight(void);
BOOL shouldUnsecurelyUnlockIntoApp(void);
BOOL shouldObscureAppContent(void);
BOOL shouldSecureSwitcher(void);
BOOL shouldSecureAppArrangement(void);
NSArray *getProtectedAppsNoBullshit(void);
NSArray *getProtectedApps(void);

@interface ASPreferencesHandler : NSObject
@property (retain) NSMutableDictionary *prefs;
@property BOOL asphaleiaDisabled;
@property BOOL appSecurityDisabled;
+(instancetype)sharedInstance;
@end