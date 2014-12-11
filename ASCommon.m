#import "ASCommon.h"

@implementation ASCommon

static ASCommon *sharedCommonObj;

+(ASCommon *)sharedInstance {
    @synchronized(self) {
        if (!sharedCommonObj)
            sharedCommonObj = [[ASCommon alloc] init];
    }

    return sharedCommonObj;
}

-(UIAlertView *)createAppAuthenticationAlertWithIcon:(SBIcon *)icon {
    // need to add customisation to this...
    // icon at the top-centre of the alert
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"[icon name]"
                                message:@"Scan fingerprint to open."
                                delegate:self
                                cancelButtonTitle:@"Passcode"
                                otherButtonTitles:@"Cancel", nil];
    return alertView;
}

@end