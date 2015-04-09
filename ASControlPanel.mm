#import "ASControlPanel.h"
#import "ASCommon.h"
#import "UIAlertView+Blocks.h"
#import "SpringBoard.h"
#import "PreferencesHandler.h"
#import <objc/runtime.h>
#import <dlfcn.h>

#define kBundlePath @"/Library/Application Support/Asphaleia/AsphaleiaAssets.bundle"
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

@interface ASControlPanel ()
@property UIAlertView *alertView;
@end

@implementation ASControlPanel

+(instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedInstance = [self new];
        dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
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
                addRemoveFromSecureAppsTitle = [getProtectedAppsNoBullshit() containsObject:bundleID] ? @"Remove from your Secured Apps" : @"Add to your Secured Apps";
            }
            NSMutableArray *buttonTitleArray = [NSMutableArray arrayWithObjects:mySecuredAppsTitle, enableGlobalAppsTitle, nil];
            if (addRemoveFromSecureAppsTitle)
                [buttonTitleArray addObject:addRemoveFromSecureAppsTitle];

            self.alertView = [[UIAlertView alloc] initWithTitle:titleWithSpacingForSmallIcon(@"Asphaleia Control Panel")
                                message:nil
                                delegate:nil
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:nil];
            for (NSString *buttonTitle in buttonTitleArray)
                [self.alertView addButtonWithTitle:buttonTitle];

            self.alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
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

                };

            NSBundle *asphaleiaAssets = [[NSBundle alloc] initWithPath:kBundlePath];
            UIImage *iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
            imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);
            imgView.center = CGPointMake(270/2,32);

            self.alertView.willPresentBlock = ^(UIAlertView *alertView) {
                UIView *labelSuperview;
                for (id subview in [[ASCommon sharedInstance] allSubviewsOfView:[[alertView _alertController] view]]){
                    if ([subview isKindOfClass:[UILabel class]]) {
                        labelSuperview = [subview superview];
                    }
                }
                if ([labelSuperview respondsToSelector:@selector(addSubview:)]) {
                    [labelSuperview addSubview:imgView];
                }
            };

            [self.alertView show];
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
    if (objc_getClass("LAActivator")) {
        if ([[objc_getClass("LAActivator") sharedInstance] isRunningInsideSpringBoard])
            [[objc_getClass("LAActivator") sharedInstance] registerListener:self forName:@"Control Panel"];
    }
}

- (void)unload {
    if (objc_getClass("LAActivator")) {
        if ([[objc_getClass("LAActivator") sharedInstance] isRunningInsideSpringBoard])
            [[objc_getClass("LAActivator") sharedInstance] unregisterListenerWithName:@"Control Panel"];
    }
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