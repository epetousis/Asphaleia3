@interface SBIcon : NSObject
-(void)launchFromLocation:(int)location;
-(NSString *)applicationBundleID;
-(NSString *)displayName;
-(void)setBadge:(id)badge;
-(id)getIconImage:(int)image;
@end