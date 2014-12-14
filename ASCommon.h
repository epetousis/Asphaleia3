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
-(UIAlertView *)createAppAuthenticationAlertWithIconView:(SBIconView *)iconView beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(UIAlertView *)createAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(BOOL)isTouchIDDevice;

@end