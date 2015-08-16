#import "TouchIDInfo.h"
#import <LocalAuthentication/LocalAuthentication.h>

BOOL isTouchIDDevice(void) {
	LAContext *context = [[LAContext alloc] init];

    if (![context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
        return NO;
    }
    return YES;
}