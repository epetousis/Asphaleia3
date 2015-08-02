#import "../ASCommon.h"
#import "../ASPasscodeHandler.h"
#import "../PreferencesHandler.h"
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "../NSTimer+Blocks.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <dlfcn.h>
#import <RocketBootstrap/RocketBootstrap.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

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
void increaseMessageCount() {
	NSMutableDictionary *tempPrefs = [NSMutableDictionary dictionaryWithDictionary:[ASPreferencesHandler sharedInstance].prefs];
	[tempPrefs setObject:[NSNumber numberWithInt:[tempPrefs[kPhotosMessageCount] intValue]+1] forKey:kPhotosMessageCount];
	[ASPreferencesHandler sharedInstance].prefs = [NSDictionary dictionaryWithDictionary:tempPrefs];
	[[ASPreferencesHandler sharedInstance].prefs writeToFile:kPreferencesFilePath atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(kPrefsChangedNotification), NULL, NULL, YES);
}

%hook UIImagePickerController

-(void)viewWillAppear:(BOOL)animated {
	if (authenticated || (!touchIDEnabled() && !passcodeEnabled()) || !shouldSecurePhotos()) {
		%orig;
		return;
	}
	if (alertView)
		return;
	alertView = [[ASCommon sharedInstance] returnAuthenticationAlertOfType:ASAuthenticationAlertPhotos delegate:(id<UIAlertViewDelegate>)self];
	alertView.tag = 4000; // UIImagePickerController tag
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
			if (shouldShowPhotosProtectMsg()) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia 2" message:@"You have allowed this app to access your photos until you close it. If no photos are shown, try opening this section of the app again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				increaseMessageCount();
			}
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

+ (int)authorizationStatus {
	return 0;
}

- (void)enumerateGroupsWithTypes:(unsigned int)arg1 usingBlock:(id /* block */)arg2 failureBlock:(id /* block */)arg3 {
	if (authenticated || (!touchIDEnabled() && !passcodeEnabled()) || !shouldSecurePhotos()) {
		%orig;
		return;
	}
	if (alertView)
		return;

	alertView = [[ASCommon sharedInstance] returnAuthenticationAlertOfType:ASAuthenticationAlertPhotos delegate:(id<UIAlertViewDelegate>)self];
	alertView.tag = 4001; // ALAssetsLibrary tag
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
			if (shouldShowPhotosProtectMsg()) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia 2" message:@"You have allowed this app to access your photos until you close it. If no photos are shown, try opening this section of the app again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				increaseMessageCount();
			}
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

BOOL accessDenied;
typedef void (^PHAuthBlock)(PHAuthorizationStatus status);
PHAuthBlock authBlock;

%hook PHPhotoLibrary

+ (int)authorizationStatus {
	PHAuthorizationStatus status = %orig;
	if (status != PHAuthorizationStatusAuthorized) {
		accessDenied = YES;
		return status;
	}
	accessDenied = NO;
	if (!authenticated)
		return PHAuthorizationStatusDenied;
	return status;
}
+ (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))arg1 {
	if (authenticated || (!touchIDEnabled() && !passcodeEnabled()) || !shouldSecurePhotos() || accessDenied || (alertView && alertView.tag != 4002)) {
		%orig;
		return;
	}
	if (alertView)
		return;

	alertView = [[ASCommon sharedInstance] returnAuthenticationAlertOfType:ASAuthenticationAlertPhotos delegate:(id<UIAlertViewDelegate>)self];
	alertView.tag = 4002; // PHPhotoLibrary tag
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
	authBlock = [arg1 copy];
	authHandler = ^(BOOL wasCancelled){
		if (!wasCancelled) {
			%orig(authBlock);
			authenticated = YES;
			if (shouldShowPhotosProtectMsg()) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia 2" message:@"You have allowed this app to access your photos until you close it. If no photos are shown, try opening this section of the app again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				increaseMessageCount();
			}
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

BOOL devicePasscodeSet() {
	// From http://pastebin.com/T9YwEjnL
	NSData* secret = [@"Device has passcode set?" dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *attributes = @{
	    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
	    (__bridge id)kSecAttrService: @"LocalDeviceServices",
	    (__bridge id)kSecAttrAccount: @"NoAccount",
	    (__bridge id)kSecValueData: secret,
	    (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
	};

	OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
	if (status == errSecSuccess) {
	    NSDictionary *query = @{
	        (__bridge id)kSecClass:  (__bridge id)kSecClassGenericPassword,
	        (__bridge id)kSecAttrService: @"LocalDeviceServices",
	        (__bridge id)kSecAttrAccount: @"NoAccount"
	    };
	
	    status = SecItemDelete((__bridge CFDictionaryRef)query);
	
	    return true;
	}

	if (status == errSecDecode) {
	    return false;
	}

	return false;
}

@interface CAMImageWell : UIButton
@end
%hook CAMImageWell
id origTarget;
SEL origSelector;

- (void)setThumbnailImage:(id)arg1 animated:(BOOL)arg2 {
	if (!authenticated)
		%orig(nil, arg2);
}
- (void)setThumbnailImage:(id)arg1 uuid:(id)arg2 animated:(BOOL)arg3 {
	if (!authenticated)
		%orig(nil, arg2, arg3);
}
-(void)willMoveToSuperview:(UIView *)view {
	%orig;
	origTarget = self.allTargets.allObjects[0];
	origSelector = NSSelectorFromString([self actionsForTarget:origTarget forControlEvent:UIControlEventTouchUpInside][0]);
	[self removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
	[self addTarget:self action:@selector(showAuthAlert:) forControlEvents:UIControlEventTouchUpInside];
}
%new
-(void)showAuthAlert:(id)sender {
	CPDistributedMessagingCenter *centre = [%c(CPDistributedMessagingCenter) centerNamed:@"com.a3tweaks.asphaleia2.xpc"];
	rocketbootstrap_distributedmessagingcenter_apply(centre);
	NSDictionary *reply = [centre sendMessageAndReceiveReplyName:@"com.a3tweaks.asphaleia2.xpc/CheckSlideUpControllerActive" userInfo:nil];

	if (authenticated || (!touchIDEnabled() && !passcodeEnabled()) || !shouldSecurePhotos() || ([reply[@"active"] boolValue] && devicePasscodeSet())) {
		[origTarget performSelectorOnMainThread:origSelector withObject:self waitUntilDone:NO];
		return;
	}
	if (alertView)
		return;

	alertView = [[ASCommon sharedInstance] returnAuthenticationAlertOfType:ASAuthenticationAlertPhotos delegate:(id<UIAlertViewDelegate>)self];
	alertView.tag = 4003; // CAMImageWell tag
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
			authenticated = YES;
			[origTarget performSelectorOnMainThread:origSelector withObject:self waitUntilDone:NO];
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

%ctor {
	if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.mobileslideshow"])
		return;
	if (NSClassFromString(@"PHPhotoLibrary") != nil || NSClassFromString(@"ALAssetsLibrary") != nil || NSClassFromString(@"UIImagePickerController") != nil) {
		loadPreferences();
		addObserver(preferencesChangedCallback,kPrefsChangedNotification);
		%init;
	}
}