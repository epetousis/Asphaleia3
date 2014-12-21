#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
#import "SBUIPasscodeLockViewSimple4DigitKeypad.h"

typedef void (^ASPasscodeHandlerEventBlock) (BOOL authenticated);
 
@interface ASPasscodeHandler : NSObject
@property (retain) NSString *passcode;
+(instancetype)sharedInstance;
-(void)showInKeyWindowWithTitle:(NSString *)title subtitle:(NSString *)subtitle passcode:(NSString *)passcode eventBlock:(ASPasscodeHandlerEventBlock)eventBlock;
@end