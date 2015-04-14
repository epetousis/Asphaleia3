#import <UIKit/UIKit.h>
#import "SBIcon.h"
#import "SBIconView.h"
#import "SBAppSwitcherSnapshotView.h"
#import "PKGlyphView.h"
#import "BTTouchIDController.h"

@interface UIAlertView ()
-(id)_alertController;
@end

typedef NS_ENUM(NSInteger, ASAuthenticationAlertType) {
  ASAuthenticationAlertAppArranging,
  ASAuthenticationAlertSwitcher,
  ASAuthenticationAlertSpotlight,
  ASAuthenticationAlertPowerDown,
  ASAuthenticationAlertControlCentre,
  ASAuthenticationAlertControlPanel
};

typedef void (^ASCommonAuthenticationHandler) (BOOL wasCancelled);

@interface ASCommon : NSObject {
	PKGlyphView *fingerglyph;
	BTTouchIDController *touchIDController;
}
//@property UIAlertView *currentAlertView;
+(instancetype)sharedInstance;
-(void)showAppAuthenticationAlertWithIconView:(SBIconView *)iconView customMessage:(NSString *)customMessage beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(void)showAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(BOOL)isTouchIDDevice;
-(void)dismissAnyAuthenticationAlerts;
- (NSArray *)allSubviewsOfView:(UIView *)view;

@end