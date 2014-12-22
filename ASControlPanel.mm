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
    SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
    NSString *bundleID = [frontmostApp bundleIdentifier];
    if ((bundleID && !shouldAllowControlPanelInApps()) || !shouldEnableControlPanel()) {
        [event setHandled:YES];
        return;
    }

    [[ASCommon sharedInstance] showAuthenticationAlertOfType:ASAuthenticationAlertControlPanel beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
        if (!wasCancelled) {
            NSString *mySecuredAppsTitle = [ASPreferencesHandler sharedInstance].appSecurityDisabled ? @"Enable My Secured Apps" : @"Disable My Secured Apps";
            NSString *enableGlobalAppsTitle = !shouldProtectAllApps() ? @"Enable Global App Security" : @"Disable Global App Security"; // Enable/Disable
            NSString *addRemoveFromSecureAppsTitle = nil;
            if (bundleID) {
                addRemoveFromSecureAppsTitle = [getProtectedApps() containsObject:bundleID] ? @"Remove from your Secured Apps" : @"Add to your Secured Apps";
            }
            NSMutableArray *buttonTitleArray = [NSMutableArray arrayWithObjects:mySecuredAppsTitle, enableGlobalAppsTitle, nil];
            if (addRemoveFromSecureAppsTitle)
                [buttonTitleArray addObject:addRemoveFromSecureAppsTitle];

            self.alertView = [UIAlertView showWithTitle:@"Asphaleia Control Panel"
                   message:nil
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:buttonTitleArray
                  tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:addRemoveFromSecureAppsTitle]) {
                        if (![[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey])
                            [[ASPreferencesHandler sharedInstance].prefs setObject:[NSMutableDictionary dictionary] forKey:kSecuredAppsKey];

                        [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey] setObject:[NSNumber numberWithBool:![getProtectedApps() containsObject:bundleID]] forKey:frontmostApp.bundleIdentifier];
                        [[ASPreferencesHandler sharedInstance].prefs writeToFile:kPreferencesFilePath atomically:YES];
                    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:mySecuredAppsTitle]) {
                        [ASPreferencesHandler sharedInstance].appSecurityDisabled = ![ASPreferencesHandler sharedInstance].appSecurityDisabled;
                    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:enableGlobalAppsTitle]) {
                        NSMutableDictionary *tempPrefs = [NSMutableDictionary dictionaryWithDictionary:[ASPreferencesHandler sharedInstance].prefs];
                        [tempPrefs setObject:[NSNumber numberWithBool:!shouldProtectAllApps()] forKey:kProtectAllAppsKey];
                        [ASPreferencesHandler sharedInstance].prefs = tempPrefs;
                        [[ASPreferencesHandler sharedInstance].prefs writeToFile:kPreferencesFilePath atomically:YES];
                    }
                  }];
        }
    }];
 
    [event setHandled:YES];
}
 
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

- (void)unload {
    if ([LASharedActivator isRunningInsideSpringBoard])
        [LASharedActivator unregisterListenerWithName:@"Control Panel"];
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