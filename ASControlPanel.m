#import "ASControlPanel.h"
#import "ASCommon.h"
#import "UIAlertView+Blocks.h"
#import "SpringBoard.h"
#import "PreferencesHandler.h"

@interface ASControlPanel ()
@property UIAlertView *alertView;
@end

@implementation ASControlPanel

+(instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}
 
-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    UIAlertView *alertView = [[ASCommon sharedInstance] createAuthenticationAlertOfType:ASAuthenticationAlertControlPanel beginMesaMonitoringBeforeShowing:YES vibrateOnIncorrectFingerprint:shouldVibrateOnIncorrectFingerprint() dismissedHandler:^(BOOL wasCancelled) {
        if (!wasCancelled) {
            //NSString *mySecuredAppsTitle = @"%@ My Secured Apps"; // Enable/Disable
            //NSString *enableGlobalAppsTitle = @"%@ Global App Security"; // Enable/Disable
            NSString *addRemoveFromSecureAppsTitle = nil; // Remove from/Add to
            NSString *bundleID = [[(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication] bundleIdentifier];
            if (bundleID) {
                addRemoveFromSecureAppsTitle = getProtectedApps() ? @"Remove from your Secured Apps" : @"Add to your Secured Apps";
            }

            self.alertView = [[UIAlertView alloc] initWithTitle:@"Asphaleia Control Panel"
                   message:nil
                   delegate:nil
         cancelButtonTitle:@"Close"
         otherButtonTitles:@"Disable My Secured Apps", @"Enable Global App Security",nil];
        }
        }];
    [alertView show];
 
    [event setHandled:YES];
}

/*
[[prefs objectForKey:kSecuredAppsKey] setObject:appSecureValue forKey:frontmostApp.bundleIdentifier];
        [prefs writeToFile:kPreferencesFilePath atomically:YES];
*/
 
-(void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
    if (self.alertView) {
        [self.alertView dismissWithClickedButtonIndex:-1 animated:YES];
        self.alertView = nil;
    }
}
 
- (void)load {
    if ([LASharedActivator isRunningInsideSpringBoard])
        [LASharedActivator registerListener:self forName:@"Control Panel"];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"Asphaleia";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    return @"Control Panel";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    return @"Open Asphaleia's control panel";
}

- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"application", nil];
}
 
@end