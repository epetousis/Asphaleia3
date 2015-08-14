#import "../ASCommon.h"
#import "../ASPasscodeHandler.h"
#import "../ASPreferences.h"
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "../NSTimer+Blocks.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <dlfcn.h>
#import <RocketBootstrap/RocketBootstrap.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "../Asphaleia.h"

UIAlertView *alertView;
BOOL authenticated;
BOOL authenticating;
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
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos] || authenticating) {
		%orig;
		return;
	}
	if ([ASCommon sharedInstance].currentAuthAlert)
		return;
	authenticating = YES;
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertPhotos dismissedHandler:^(BOOL wasCancelled){
		authenticating = NO;
		if (!wasCancelled) {
			%orig;
		} else {
			[self dismissViewControllerAnimated:YES completion:nil];
			if ([[ASPreferences sharedInstance] showPhotosProtectMessage]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia 2" message:@"You have allowed this app to access your photos until you close it. If no photos are shown, try opening this section of the app again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				[[ASPreferences sharedInstance] increasePhotosProtectMessageCount];
			}
		}
	}];
}

%end

ALAssetsLibraryGroupsEnumerationResultsBlock block1;
ALAssetsLibraryAccessFailureBlock block2;
%hook ALAssetsLibrary

+ (int)authorizationStatus {
	if (!authenticated && [[ASPreferences sharedInstance] securePhotos])
		return 0;

	return %orig;
}

- (void)enumerateGroupsWithTypes:(unsigned int)arg1 usingBlock:(id)arg2 failureBlock:(id)arg3 {
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos] || authenticating) {
		if (!authenticating)
			%orig;
		return;
	}
	if ([ASCommon sharedInstance].currentAuthAlert)
		return;
	authenticating = YES;

	block1 = [arg2 copy];
	block2 = [arg3 copy];
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertPhotos dismissedHandler:^(BOOL wasCancelled){
		authenticating = NO;
		if (!wasCancelled) {
			authenticated = YES;
			%orig(arg1,block1,block2);
			if ([[ASPreferences sharedInstance] showPhotosProtectMessage]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia 2" message:@"You have allowed this app to access your photos until you close it. If no photos are shown, try opening this section of the app again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				[[ASPreferences sharedInstance] increasePhotosProtectMessageCount];
			}
		}
	}];
}

%end

BOOL accessDenied;
typedef void (^PHAuthBlock)(PHAuthorizationStatus status);
PHAuthBlock authBlock;

%hook PHPhotoLibrary

+ (int)authorizationStatus {
	PHAuthorizationStatus status = %orig;
	if (status != PHAuthorizationStatusAuthorized && [[ASPreferences sharedInstance] securePhotos]) {
		accessDenied = YES;
		return status;
	}
	accessDenied = NO;
	if (!authenticated && [[ASPreferences sharedInstance] securePhotos])
		return PHAuthorizationStatusNotDetermined;
	return status;
}
+ (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))arg1 {
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos] || accessDenied || authenticating) {
		if (!authenticating)
			%orig;
		return;
	}
	if ([ASCommon sharedInstance].currentAuthAlert)
		return;
	authenticating = YES;

	authBlock = [arg1 copy];
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertPhotos dismissedHandler:^(BOOL wasCancelled){
			authenticating = NO;
			if (!wasCancelled) {
				%orig(authBlock);
				authenticated = YES;
				if ([[ASPreferences sharedInstance] showPhotosProtectMessage]) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia 2" message:@"You have allowed this app to access your photos until you close it. If no photos are shown, try opening this section of the app again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alert show];
					[[ASPreferences sharedInstance] increasePhotosProtectMessageCount];
				}
			}
		}];
}

%end

%hook PHFetchResult

-(NSUInteger)count {
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos])
		return %orig;

	return 0;
}

- (id)objectAtIndexedSubscript:(unsigned int)arg1 {
	if (authenticated || ![[ASPreferences sharedInstance] securePhotos])
		return %orig;

	return nil;
}

%end

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

	if (authenticated || ![[ASPreferences sharedInstance] securePhotos] || ([reply[@"active"] boolValue] && [ASPreferences devicePasscodeSet]) || authenticating) {
		[origTarget performSelectorOnMainThread:origSelector withObject:self waitUntilDone:NO];
		return;
	}
	if (alertView)
		return;
	authenticating = YES;

	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertPhotos dismissedHandler:^(BOOL wasCancelled){
		authenticating = NO;
		if (!wasCancelled) {
			authenticated = YES;
			[origTarget performSelectorOnMainThread:origSelector withObject:self waitUntilDone:NO];
		}
	}];
}

%end

%ctor {
	if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.mobileslideshow"])
		return;
	if ([UIApplication sharedApplication] || NSClassFromString(@"PHPhotoLibrary") != nil || NSClassFromString(@"ALAssetsLibrary") != nil || NSClassFromString(@"UIImagePickerController") != nil) {
		loadPreferences();
		%init;
	}
}