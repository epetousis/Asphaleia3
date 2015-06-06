@interface BiometricKit : NSObject
+(id)manager;
-(NSDictionary *)identities:(id)object;
@end