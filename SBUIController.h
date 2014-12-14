@interface SBUIController : NSObject
+(id)sharedInstanceIfExists;
+(id)sharedInstance;
-(BOOL)isAppSwitcherShowing;
-(BOOL)clickedMenuButton;
@end