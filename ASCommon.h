#import <UIKit/UIKit.h>
#import "Asphaleia.h"
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
  ASAuthenticationAlertControlPanel,
  ASAuthenticationAlertPhotos
};

typedef void (^ASCommonAuthenticationHandler) (BOOL wasCancelled);

@interface ASCommon : NSObject <UIAlertViewDelegate> {
	PKGlyphView *fingerglyph;
	ASCommonAuthenticationHandler authHandler;
	UIView *alertViewAccessory;
	SBIconView *currentIconView;
}
@property UIAlertView *currentAuthAlert;
+(instancetype)sharedInstance;
-(void)showAppAuthenticationAlertWithIconView:(SBIconView *)iconView customMessage:(NSString *)customMessage beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(void)showAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(BOOL)isTouchIDDevice;
-(void)dismissAnyAuthenticationAlerts;
- (NSArray *)allSubviewsOfView:(UIView *)view;

@end