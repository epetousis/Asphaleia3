#import "ASXPCHandler.h"
#import "Asphaleia.h"
#import <objc/runtime.h>
#import "PreferencesHandler.h"

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
	}
	return nil;
}

@end