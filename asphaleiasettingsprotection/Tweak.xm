#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import "../ASCommon.h"
#import <UIKit/UIKit.h>
#import "../ASPasscodeHandler.h"
#import "../PreferencesHandler.h"
#import "../NSTimer+Blocks.h"
@interface PSSpecifier ()
@property (assign,nonatomic) SEL controllerLoadAction;
@property (assign,nonatomic) Class detailControllerClass;
@end
@interface PrefsListController : PSListController
-(void)lazyLoadBundle:(PSSpecifier *)specifier;
-(id)table;
@end

BOOL useTouchID;
BOOL usePasscode;
NSDictionary *securedPanels;
UIAlertView *alertView;
ASCommonAuthenticationHandler authHandler;
NSString *origTitle;
void fingerDown(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    alertView.title = @"\n\nScanning finger...";
    [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
        alertView.title = origTitle;
    } repeats:NO];
}
void fingerScanFailed(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	alertView.title = origTitle;
}
void authSuccess(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.stopmonitoring"), NULL, NULL, YES);
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), observer, NULL, NULL);
	[alertView dismissWithClickedButtonIndex:-1 animated:YES];
	alertView = nil;
	authHandler(NO);
}

%hook PrefsListController

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![securedPanels[[[(PSTableCell *)[tableView cellForRowAtIndexPath:indexPath] specifier] identifier]] boolValue] || (!useTouchID && !usePasscode)) {
		%orig;
		return;
	}
	alertView = [[ASCommon sharedInstance] returnAuthenticationAlertOfType:ASAuthenticationAlertSettingsPanel delegate:(id<UIAlertViewDelegate>)self];
	if (alertView && useTouchID) {
		[[ASCommon sharedInstance] addSubview:[[ASCommon sharedInstance] valueForKey:@"alertViewAccessory"] toAlertView:alertView];
		origTitle = alertView.title;
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.startmonitoring"), NULL, NULL, YES);
		addObserver(authSuccess, "com.a3tweaks.asphaleia8.authsuccess");
		addObserver(fingerScanFailed, "com.a3tweaks.asphaleia8.authfailed");
		addObserver(fingerDown, "com.a3tweaks.asphaleia8.fingerdown");
	} else {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.showpasscodeview"), NULL, NULL, YES);
	}
	addObserver(authSuccess, "com.a3tweaks.asphaleia8.passcodeauthsuccess");
	authHandler = ^(BOOL wasCancelled){
		if (!wasCancelled) {
			%orig;
		} else {
			[[self table] deselectRowAtIndexPath:[[self table] indexPathForSelectedRow] animated:YES];
		}
	};
	if (alertView)
		[alertView show];
}

%new
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.stopmonitoring"), NULL, NULL, YES);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge void *)self, NULL, NULL);
    alertView = nil;
    if (buttonIndex == 1) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.showpasscodeview"), NULL, NULL, YES);
    } else if (buttonIndex == 0) {
        authHandler(YES);
    }
}

%end

void updatePrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPreferencesFilePath];
	useTouchID = [preferences[kTouchIDEnabledKey] boolValue];
	usePasscode = [preferences[kPasscodeEnabledKey] boolValue];
	securedPanels = preferences[kSecuredPanelsKey] ? preferences[kSecuredPanelsKey] : [[NSDictionary alloc] init];
}

%ctor {
	updatePrefs(NULL,NULL,NULL,NULL,NULL);
	addObserver(updatePrefs,"com.a3tweaks.asphaleia/ReloadPrefs");
}