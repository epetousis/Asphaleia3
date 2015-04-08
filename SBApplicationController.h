@interface SBApplicationController : NSObject
-(id)sharedInstance;
-(id)applicationWithBundleIdentifier:(NSString*)bundleID;
@end