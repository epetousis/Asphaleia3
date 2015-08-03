#import <UIKit/UIKit.h>
#import "Asphaleia.h"
#import "PKGlyphView.h"
#import "ASTouchIDController.h"

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
  ASAuthenticationAlertPhotos,
  ASAuthenticationAlertSettingsPanel
};

typedef void (^ASCommonAuthenticationHandler) (BOOL wasCancelled);

@interface ASCommon : NSObject <UIAlertViewDelegate> {
	PKGlyphView *fingerglyph;
	ASCommonAuthenticationHandler authHandler;
	UIView *alertViewAccessory;
	SBIconView *currentIconView;
}
@property UIAlertView *currentAuthAlert;
@property NSString *appUserAuthorisedID;
@property BOOL catchAllIgnoreRequest;
@property NSString *temporarilyUnlockedAppBundleID;
+(instancetype)sharedInstance;
-(UIAlertView *)returnAppAuthenticationAlertWithIconView:(SBIconView *)iconView customMessage:(NSString *)customMessage delegate:(id<UIAlertViewDelegate>)delegate;
-(UIAlertView *)returnAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType delegate:(id<UIAlertViewDelegate>)delegate;
-(BOOL)authenticateAppWithDisplayIdentifier:(NSString *)appIdentifier customMessage:(NSString *)customMessage dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(void)showAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(BOOL)isTouchIDDevice;
-(void)dismissAnyAuthenticationAlerts;
-(void)addSubview:(UIView *)view toAlertView:(UIAlertView *)alertView;
- (NSArray *)allSubviewsOfView:(UIView *)view;

@end