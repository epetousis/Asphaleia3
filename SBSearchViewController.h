@interface SBSearchViewController : UIViewController
+(SBSearchViewController *)sharedInstance;
-(void)cancelButtonPressed;
-(void)_setShowingKeyboard:(BOOL)keyboard;
-(void)dismiss;
@end