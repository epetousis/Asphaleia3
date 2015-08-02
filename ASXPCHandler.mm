#import "ASXPCHandler.h"
#import "Asphaleia.h"
#import <objc/runtime.h>

@implementation ASXPCHandler
static ASXPCHandler *sharedHandlerObj;
+(instancetype)sharedInstance {
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedHandlerObj = [[ASXPCHandler alloc] init];
	});
	return sharedHandlerObj;
}

- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo {
	if ([name isEqualToString:@"com.a3tweaks.asphaleia2.xpc/CheckSlideUpControllerActive"]) {
		return @{ @"active" : [NSNumber numberWithBool:_slideUpControllerActive] };
	}
	return nil;
}

@end