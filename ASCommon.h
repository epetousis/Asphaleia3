#import <UIKit/UIKit.h>
#import "SBIcon.h"

typedef NS_ENUM(NSInteger, ASAuthenticationAlertType) {
  ASAuthenticationAlertAppArranging,
  ASAuthenticationAlertSwitcher
};

@interface ASCommon : NSObject
+(ASCommon *)sharedInstance;
-(UIAlertView *)createAppAuthenticationAlertWithIcon:(SBIcon *)icon completionHandler:(void (^)(UIAlertView *alertView, NSInteger buttonIndex))handler;
-(UIAlertView *)createAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType completionHandler:(void (^)(UIAlertView *alertView, NSInteger buttonIndex))handler;
-(BOOL)isTouchIDDevice;

@end