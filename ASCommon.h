#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ASAuthenticationAlertType) {
  ASAuthenticationAlertAppArranging,
  ASAuthenticationAlertSwitcher,
  ASAuthenticationAlertSpotlight,
  ASAuthenticationAlertPowerDown,
  ASAuthenticationAlertControlCentre,
  ASAuthenticationAlertControlPanel,
  ASAuthenticationAlertPhotos,
  ASAuthenticationAlertSettingsPanel,
  ASAuthenticationAlertFlipswitch
};

typedef void (^ASCommonAuthenticationHandler) (BOOL wasCancelled);

@interface ASCommon : NSObject <UIAlertViewDelegate> {
  ASCommonAuthenticationHandler authHandler;
}
+(instancetype)sharedInstance;
-(UIAlertView *)currentAuthAlert;
-(BOOL)authenticateAppWithDisplayIdentifier:(NSString *)appIdentifier customMessage:(NSString *)customMessage dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(BOOL)authenticateFunction:(ASAuthenticationAlertType)alertType dismissedHandler:(ASCommonAuthenticationHandler)handler;

@end