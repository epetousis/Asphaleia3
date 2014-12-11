#import <UIKit/UIKit.h>
#import "SBIcon.h"

@interface ASCommon : NSObject
+(ASCommon *)sharedInstance;
-(UIAlertView *)createAppAuthenticationAlertWithIcon:(SBIcon *)icon;

@end