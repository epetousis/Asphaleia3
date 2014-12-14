#import <UIKit/UIKit.h>
#import "SBIcon.h"
#import "SBIconView.h"

typedef NS_ENUM(NSInteger, ASAuthenticationAlertType) {
  ASAuthenticationAlertAppArranging,
  ASAuthenticationAlertSwitcher
};

typedef void (^ASCommonAuthenticationHandler) (BOOL wasCancelled);

@interface ASCommon : NSObject
+(ASCommon *)sharedInstance;
-(UIAlertView *)createAppAuthenticationAlertWithIconView:(SBIconView *)iconView dismissedHandler:(ASCommonAuthenticationHandler)handler beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent;
-(UIAlertView *)createAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType dismissedHandler:(ASCommonAuthenticationHandler)handler beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent;
-(BOOL)isTouchIDDevice;

@end