#import "../ASCommon.h"
#import "../ASPasscodeHandler.h"
#import "../PreferencesHandler.h"
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "../NSTimer+Blocks.h"

UIAlertView *alertView;
BOOL authenticated;
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

%hook UIImagePickerController

-(void)viewWillAppear:(BOOL)animated {
	if (authenticated || (!touchIDEnabled() && !passcodeEnabled()) || !shouldSecurePhotos()) {
		%orig;
		return;
	}
	alertView = [[ASCommon sharedInstance] returnAuthenticationAlertOfType:ASAuthenticationAlertPhotos delegate:(id<UIAlertViewDelegate>)self];
	if (alertView && touchIDEnabled()) {
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
			[self dismissViewControllerAnimated:YES completion:nil];
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

ALAssetsLibraryGroupsEnumerationResultsBlock block1;
ALAssetsLibraryAccessFailureBlock block2;
%hook ALAssetsLibrary

- (void)enumerateGroupsWithTypes:(unsigned int)arg1 usingBlock:(id /* block */)arg2 failureBlock:(id /* block */)arg3 {
	if (authenticated || (!touchIDEnabled() && !passcodeEnabled()) || !shouldSecurePhotos()) {
		%orig;
		return;
	}
	if (alertView)
		return;

	alertView = [[ASCommon sharedInstance] returnAuthenticationAlertOfType:ASAuthenticationAlertPhotos delegate:(id<UIAlertViewDelegate>)self];
	if (alertView && touchIDEnabled()) {
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
	block1 = [arg2 copy];
	block2 = [arg3 copy];
	authHandler = ^(BOOL wasCancelled){
		if (!wasCancelled) {
			authenticated = YES;
			%orig(arg1,block1,block2);
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

/*BOOL authenticated;
BOOL accessDenied;
UIAlertView *alertView;
typedef void (^PHAuthBlock)(PHAuthorizationStatus status);
PHAuthBlock authBlock;
void fingerScanned(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	authenticated = YES;
	[alertView dismissWithClickedButtonIndex:0 animated:YES];
	alertView = nil;
	if (authBlock)
		authBlock(PHAuthorizationStatusAuthorized);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.stopmonitoring"), NULL, NULL, YES);
}

%hook PHPhotoLibrary

+ (int)authorizationStatus {
	PHAuthorizationStatus status = %orig;
	if (status != PHAuthorizationStatusAuthorized) {
		accessDenied = YES;
		return status;
	}
	if (!authenticated)
		return PHAuthorizationStatusNotDetermined;
	return status;
}
+ (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))arg1 {
	if (alertView)
		return;

	if (accessDenied) {
		%orig;
		return;
	}
	authBlock = [arg1 copy];
	alertView = [[UIAlertView alloc] initWithTitle:@"\n\nPhoto Library"
                   message:@"Scan fingerprint for access."
                   delegate:nil
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];
	[alertView show];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.startmonitoring"), NULL, NULL, YES);
	addObserver(fingerScanned, "com.a3tweaks.asphaleia8.authsuccess");
}

%end*/

%ctor {
	if (NSClassFromString(@"ALAssetsLibrary") != nil || NSClassFromString(@"UIImagePickerController") != nil) {
		loadPreferences();
		addObserver(preferencesChangedCallback,kPrefsChangedNotification);
		%init;
	}
}