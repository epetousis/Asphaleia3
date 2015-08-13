#import "ASXPCHandler.h"
#import "Asphaleia.h"
#import <objc/runtime.h>
#import "PreferencesHandler.h"
#import "ASAuthenticationController.h"
#import <RocketBootstrap/RocketBootstrap.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

@interface ASPreferencesHandler ()
@property (readwrite) BOOL asphaleiaDisabled;
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
		[ASPreferencesHandler sharedInstance].asphaleiaDisabled = [userInfo[@"asphaleiaDisabled"] boolValue];
	} else if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/ReadAsphaleiaState"]) {
		return @{ @"asphaleiaDisabled" : [NSNumber numberWithBool:[ASPreferencesHandler sharedInstance].asphaleiaDisabled] };
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
	}
	return nil;
}

@end