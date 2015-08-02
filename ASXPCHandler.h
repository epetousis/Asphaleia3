@interface ASXPCHandler : NSObject
@property BOOL slideUpControllerActive;
+(instancetype)sharedInstance;
- (NSDictionary *)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo;
@end