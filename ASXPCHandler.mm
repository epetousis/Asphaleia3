#import "ASXPCHandler.h"
#import "Asphaleia.h"
#import <objc/runtime.h>
#import "ASPreferences.h"
#import "ASAuthenticationController.h"
#import <RocketBootstrap/RocketBootstrap.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

@interface ASPreferences ()
@property (readwrite) BOOL asphaleiaDisabled;
@property (readwrite) BOOL itemSecurityDisabled;
@end

@implementation ASXPCHandler
static ASXPCHandler *sharedHandlerObj;
+(instancetype)sharedInstance {
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedHandlerObj = [[ASXPCHandler alloc] init];
	});
	return sharedHandlerObj;
}

- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/CheckSlideUpControllerActive"]) {
		return @{ @"active" : [NSNumber numberWithBool:_slideUpControllerActive] };
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/SetAsphaleiaState"]) {
		if (userInfo[@"asphaleiaDisabled"])
			[ASPreferences sharedInstance].asphaleiaDisabled = [userInfo[@"asphaleiaDisabled"] boolValue];
		if (userInfo[@"itemSecurityDisabled"])
			[ASPreferences sharedInstance].itemSecurityDisabled = [userInfo[@"itemSecurityDisabled"] boolValue];
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/ReadAsphaleiaState"]) {
		return @{ @"asphaleiaDisabled" : [NSNumber numberWithBool:[ASPreferences sharedInstance].asphaleiaDisabled], @"itemSecurityDisabled" : [NSNumber numberWithBool:[ASPreferences sharedInstance].itemSecurityDisabled] };
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/SetUserAuthorisedApp"]) {
		[ASAuthenticationController sharedInstance].appUserAuthorisedID = userInfo[@"appIdentifier"];
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/AuthenticateApp"]) {
		BOOL isProtected = [[ASAuthenticationController sharedInstance] authenticateAppWithDisplayIdentifier:userInfo[@"appIdentifier"] customMessage:userInfo[@"customMessage"] dismissedHandler:^(BOOL wasCancelled) {
			if (wasCancelled)
				CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia2.xpc/AuthCancelled"), NULL, NULL, YES);
			else
				CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia2.xpc/AuthSucceeded"), NULL, NULL, YES);
		}];
		return @{ @"isProtected" : [NSNumber numberWithBool:isProtected] };
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/AuthenticateFunction"]) {
		BOOL isProtected = [[ASAuthenticationController sharedInstance] authenticateFunction:[userInfo[@"alertType"] intValue] dismissedHandler:^(BOOL wasCancelled) {
			if (wasCancelled)
				CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia2.xpc/AuthCancelled"), NULL, NULL, YES);
			else
				CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia2.xpc/AuthSucceeded"), NULL, NULL, YES);
		}];
		return @{ @"isProtected" : [NSNumber numberWithBool:isProtected] };
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/GetCurrentAuthAlert"]) {
		if ([ASAuthenticationController sharedInstance].currentAuthAlert)
			return @{ @"currentAuthAlert" : [ASAuthenticationController sharedInstance].currentAuthAlert };
		else
			return @{ @"currentAuthAlert" : [NSNull null] };
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/GetCurrentTempUnlockedApp"]) {
		if ([ASAuthenticationController sharedInstance].temporarilyUnlockedAppBundleID)
			return @{ @"bundleIdentifier" : [ASAuthenticationController sharedInstance].temporarilyUnlockedAppBundleID };
		else
			return @{ @"bundleIdentifier" : [NSNull null] };
	}
	return nil;
}

@end