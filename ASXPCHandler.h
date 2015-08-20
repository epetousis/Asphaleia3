#define xpcNotifications @[\
	@"com.a3tweaks.asphaleia2.xpc/CheckSlideUpControllerActive",\
	@"com.a3tweaks.asphaleia2.xpc/SetAsphaleiaState",\
	@"com.a3tweaks.asphaleia2.xpc/ReadAsphaleiaState",\
	@"com.a3tweaks.asphaleia2.xpc/SetUserAuthorisedApp",\
	@"com.a3tweaks.asphaleia2.xpc/AuthenticateApp",\
	@"com.a3tweaks.asphaleia2.xpc/AuthenticateFunction",\
	@"com.a3tweaks.asphaleia2.xpc/GetCurrentAuthAlert",\
	@"com.a3tweaks.asphaleia2.xpc/GetCurrentTempUnlockedApp",\
	@"com.a3tweaks.asphaleia2.xpc/IsTouchIDDevice"]
@interface ASXPCHandler : NSObject
@property BOOL slideUpControllerActive;
+(instancetype)sharedInstance;
- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo;
@end