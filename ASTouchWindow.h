#import <UIKit/UIKit.h>
@class ASTouchWindow;

typedef void (^ASTouchWindowTouchBlockedEvent) (ASTouchWindow *touchWindow, BOOL blockedTouch);

@interface ASTouchWindow : UIWindow {
	BOOL touchedOutside;
}
@property (assign) UIView *viewToAllowTouchIn;
@property (nonatomic, strong) ASTouchWindowTouchBlockedEvent handler;
-(void)blockTouchesAllowingTouchInView:(UIView *)touchView touchBlockedHandler:(ASTouchWindowTouchBlockedEvent)handler;
@end