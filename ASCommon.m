#import "ASCommon.h"
#include <sys/sysctl.h>

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
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Passcode", nil];
    CGAffineTransform moveUp = CGAffineTransformMakeTranslation(0.0, 0.0);
    [alertView setTransform: moveUp];
    return alertView;
}

-(BOOL)isTouchIDDevice {
    int sysctlbyname(const char *, void *, size_t *, void *, size_t);

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);

    char *answer = (char *)malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);

    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];

    free(answer);

    NSArray *touchIDModels = @[ @"iPhone6,1", @"iPhone6,2", @"iPhone7,1", @"iPhone7,2", @"iPad5,3", @"iPad5,4", @"iPad4,7", @"iPad4,8", @"iPad4,9" ];

    return [touchIDModels containsObject:results];
}

@end