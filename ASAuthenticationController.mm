#import "ASAuthenticationController.h"
#include <sys/sysctl.h>
#import <objc/runtime.h>
#import <AudioToolbox/AudioServices.h>
#import "NSTimer+Blocks.h"
#import "PreferencesHandler.h"
#import "ASPasscodeHandler.h"

#define kBundlePath @"/Library/Application Support/Asphaleia/AsphaleiaAssets.bundle"
#define titleWithSpacingForIcon(t) [NSString stringWithFormat:@"\n\n\n%@",t]
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface ASAuthenticationController ()
-(void)receivedNotificationOfName:(NSString *)name;
@end

void touchIDNotificationReceived(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[ASAuthenticationController sharedInstance] receivedNotificationOfName:(__bridge NSString *)name];
}

@implementation ASAuthenticationController

static ASAuthenticationController *sharedCommonObj;

+(instancetype)sharedInstance {
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedCommonObj = [[ASAuthenticationController alloc] init];
        [sharedCommonObj registerForTouchIDNotifications];
    });

    return sharedCommonObj;
}

-(void)dealloc {
    [self deregisterForTouchIDNotifications];
}

-(UIAlertView *)returnAppAuthenticationAlertWithIconView:(SBIconView *)iconView customMessage:(NSString *)customMessage delegate:(id<UIAlertViewDelegate>)delegate {
    NSString *title;
    NSString *message;
    if (customMessage)
        message = customMessage;
    else
        message = @"Scan fingerprint to open.";

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.4")) {
        title = titleWithSpacingForIcon([iconView.icon displayNameForLocation:0]);
    } else {
        title = titleWithSpacingForIcon(iconView.icon.displayName);
    }

    __block UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                   message:message
                   delegate:delegate
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];

    currentAuthAppBundleID = iconView.icon.applicationBundleID;
    UIImage *iconImage = [iconView.icon getIconImage:2];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
    imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);
    imgView.center = CGPointMake(270/2,41); // 270 is the width of a UIAlertView.

    if (touchIDEnabled()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            imgView.image = [self colouriseImage:iconImage withColour:[UIColor colorWithWhite:0.f alpha:0.5f]];
            if (!_fingerglyph) {
                _fingerglyph = [[objc_getClass("PKGlyphView") alloc] initWithStyle:1];
                _fingerglyph.secondaryColor = [UIColor grayColor];
                _fingerglyph.primaryColor = [UIColor redColor];
                CGRect fingerframe = _fingerglyph.frame;
                fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
                fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
                _fingerglyph.frame = fingerframe;
                _fingerglyph.center = CGPointMake(CGRectGetMidX(imgView.bounds),CGRectGetMidY(imgView.bounds));
            }
            [imgView addSubview:_fingerglyph];
            [self addSubview:imgView toAlertView:alertView];
        });
    }

    return alertView;
}

-(UIAlertView *)returnAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType delegate:(id<UIAlertViewDelegate>)delegate {
    NSBundle *asphaleiaAssets = [[NSBundle alloc] initWithPath:kBundlePath];

    NSString *title;
    UIImage *iconImage;
    switch (alertType) {
        case ASAuthenticationAlertAppArranging:
            title = @"Arrange Apps";
            iconImage = [UIImage imageNamed:@"IconEditMode.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
        case ASAuthenticationAlertSwitcher:
            title = @"Multitasking";
            iconImage = [UIImage imageNamed:@"IconMultitasking.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
        case ASAuthenticationAlertSpotlight:
            title = @"Spotlight";
            iconImage = [UIImage imageNamed:@"IconSpotlight.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
        case ASAuthenticationAlertPowerDown:
            title = @"Slide to Power Off";
            iconImage = [UIImage imageNamed:@"IconPowerOff.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
        case ASAuthenticationAlertControlCentre:
            title = @"Control Center";
            iconImage = [UIImage imageNamed:@"IconControlCenter.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
        case ASAuthenticationAlertControlPanel:
            title = @"Asphaleia Control Panel";
            iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
        case ASAuthenticationAlertPhotos:
            title = @"Photo Library";
            iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
        case ASAuthenticationAlertSettingsPanel:
            title = @"Settings Panel";
            iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
        case ASAuthenticationAlertFlipswitch:
            title = @"Flipswitch";
            iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
        default:
            title = @"Asphaleia";
            iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
    }
    title = titleWithSpacingForSmallIcon(title);

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                   message:@"Scan fingerprint to access."
                   delegate:delegate
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
        imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);
        imgView.center = CGPointMake(270/2,32); // 270 is the width of a UIAlertView.
        [self addSubview:imgView toAlertView:alertView];
    });

    return alertView;
}

-(BOOL)authenticateAppWithDisplayIdentifier:(NSString *)appIdentifier customMessage:(NSString *)customMessage dismissedHandler:(ASCommonAuthenticationHandler)handler {
    [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];

    SBApplication *application = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:appIdentifier];
    SBApplicationIcon *appIcon = [[objc_getClass("SBApplicationIcon") alloc] initWithApplication:application];
    SBIconView *iconView = [[objc_getClass("SBIconView") alloc] initWithDefaultSize];
    [iconView _setIcon:appIcon animated:YES];

    if ((![getProtectedApps() containsObject:appIdentifier] && !shouldProtectAllApps()) || [_temporarilyUnlockedAppBundleID isEqual:appIdentifier] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled) {
        return NO;
    }

    authHandler = [handler copy];

    UIAlertView *alertView = [self returnAppAuthenticationAlertWithIconView:iconView customMessage:customMessage delegate:self];

    if (!touchIDEnabled() && !passcodeEnabled()) {
        return NO;
    }

    if (!touchIDEnabled()) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
                if (authenticated)
                    _appUserAuthorisedID = appIdentifier;
                authHandler(!authenticated);
            }];
        return YES;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView show];
    });
    return YES;
}

-(BOOL)authenticateFunction:(ASAuthenticationAlertType)alertType dismissedHandler:(ASCommonAuthenticationHandler)handler {
    if ([ASPreferencesHandler sharedInstance].asphaleiaDisabled) {
        return NO;
    }

    [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
    authHandler = [handler copy];

    UIAlertView *alertView = [self returnAuthenticationAlertOfType:alertType delegate:self];

    if (!touchIDEnabled() && !passcodeEnabled()) {
        return NO;
    }

    if (!touchIDEnabled()) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:nil eventBlock:^void(BOOL authenticated){
                authHandler(!authenticated);
            }];
        return YES;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView show];
    });
    return YES;
}

-(BOOL)authenticateAppWithIconView:(SBIconView *)iconView authenticatedHandler:(ASCommonAuthenticationHandler)handler {
    if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
            return NO;

    if ([ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || [[iconView icon] isDownloadingIcon]) {
        [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
        [iconView setHighlighted:NO];
        return NO;
    }

    NSString *displayName;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.4")) {
        displayName = [iconView.icon displayNameForLocation:iconView.location];
    } else {
        displayName = [iconView.icon displayName];
    }
    currentAuthAppBundleID = iconView.icon.applicationBundleID;

    if (_fingerglyph && _currentHSIconView) {
        [iconView setHighlighted:NO];
        if ([iconView isEqual:_currentHSIconView]) {
            [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
                if (authenticated) {
                    [ASAuthenticationController sharedInstance].appUserAuthorisedID = iconView.icon.applicationBundleID;
                }
                handler(!authenticated);
            }];
        }
        [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];

        return YES;
    } else if (([iconView.icon isApplicationIcon] && ![getProtectedApps() containsObject:iconView.icon.applicationBundleID] && !shouldProtectAllApps()) || ([[ASAuthenticationController sharedInstance].temporarilyUnlockedAppBundleID isEqual:iconView.icon.applicationBundleID] && !shouldProtectAllApps()) || ([iconView.icon isFolderIcon] && ![getProtectedFolders() containsObject:displayName])) {
        [iconView setHighlighted:NO];
        return NO;
    } else if (!touchIDEnabled() && passcodeEnabled()) {
        [iconView setHighlighted:NO];
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){

            if (authenticated){
                [ASAuthenticationController sharedInstance].appUserAuthorisedID = iconView.icon.applicationBundleID;
            }
            handler(!authenticated);
        }];
        return YES;
    }

    if (!_anywhereTouchWindow) {
        _anywhereTouchWindow = [[ASTouchWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }

    _currentHSIconView = iconView;

    if (!_fingerglyph) {
        _fingerglyph = [[objc_getClass("PKGlyphView") alloc] initWithStyle:1];
        _fingerglyph.secondaryColor = [UIColor grayColor];
        _fingerglyph.primaryColor = [UIColor redColor];
    }

    CGRect fingerframe = _fingerglyph.frame;
    fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
    fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
    _fingerglyph.frame = fingerframe;
    _fingerglyph.center = CGPointMake(CGRectGetMidX([iconView _iconImageView].bounds),CGRectGetMidY([iconView _iconImageView].bounds));
    [[iconView _iconImageView] addSubview:_fingerglyph];

    _fingerglyph.transform = CGAffineTransformMakeScale(0.01,0.01);
    [UIView animateWithDuration:0.3f animations:^{
        _fingerglyph.transform = CGAffineTransformMakeScale(1,1);
    }];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.startmonitoring"), NULL, NULL, YES);

    [_currentHSIconView asphaleia_updateLabelWithText:@"Scan finger..."];

    [_anywhereTouchWindow blockTouchesAllowingTouchInView:_currentHSIconView touchBlockedHandler:^void(ASTouchWindow *touchWindow, BOOL blockedTouch){
        if (blockedTouch) {
            [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
            handler(YES);
        }
    }];
    return YES;
}

-(void)receivedNotificationOfName:(NSString *)name
{
    if (self.currentAuthAlert) {
        NSString *origTitle = self.currentAuthAlert.title;
        if ([name isEqualToString:@"com.a3tweaks.asphaleia8.fingerdown"]) {
            if ([origTitle containsString:@"\n\n\n"]) {
                self.currentAuthAlert.title = titleWithSpacingForIcon(@"Scanning finger...");
            } else {
                self.currentAuthAlert.title = titleWithSpacingForSmallIcon(@"Scanning finger...");
            }
            [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
                self.currentAuthAlert.title = origTitle;
            } repeats:NO];
            if (_fingerglyph)
                [_fingerglyph setState:1 animated:YES completionHandler:nil];
        } else if ([name isEqualToString:@"com.a3tweaks.asphaleia8.fingerup"]) {
            if (_fingerglyph)
                [_fingerglyph setState:0 animated:YES completionHandler:nil];
        } else if ([name isEqualToString:@"com.a3tweaks.asphaleia8.authsuccess"]) {
            [self.currentAuthAlert dismissWithClickedButtonIndex:-1 animated:YES];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.stopmonitoring"), NULL, NULL, YES);
            if (_fingerglyph)
                [_fingerglyph setState:0 animated:YES completionHandler:nil];
            _appUserAuthorisedID = currentAuthAppBundleID;
            authHandler(NO);
            self.currentAuthAlert = nil;
            currentAuthAppBundleID = nil;
        } else if ([name isEqualToString:@"com.a3tweaks.asphaleia8.authfailed"]) {
            self.currentAuthAlert.title = origTitle;
            if (_fingerglyph)
                [_fingerglyph setState:0 animated:YES completionHandler:nil];
        }
    } else if (self.currentHSIconView) {
        if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"])
            return;
        if ([name isEqualToString:@"com.a3tweaks.asphaleia8.fingerdown"]) {
            if (_fingerglyph && _currentHSIconView) {
                [_fingerglyph setState:1 animated:YES completionHandler:nil];
                [_currentHSIconView asphaleia_updateLabelWithText:@"Scanning..."];
            }
        } else if ([name isEqualToString:@"com.a3tweaks.asphaleia8.fingerup"]) {
            if (_fingerglyph)
                [_fingerglyph setState:0 animated:YES completionHandler:nil];
        } else if ([name isEqualToString:@"com.a3tweaks.asphaleia8.authsuccess"]) {
            if (_fingerglyph && _currentHSIconView) {
                [ASAuthenticationController sharedInstance].appUserAuthorisedID = currentAuthAppBundleID;
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.3")) {
                    [_currentHSIconView.icon launchFromLocation:_currentHSIconView.location context:nil];
                } else {
                    [_currentHSIconView.icon launchFromLocation:_currentHSIconView.location];
                }
                [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
                currentAuthAppBundleID = nil;
            }
        } else if ([name isEqualToString:@"com.a3tweaks.asphaleia8.authfailed"]) {
            if (_fingerglyph && _currentHSIconView) {
                [_fingerglyph setState:0 animated:YES completionHandler:nil];
                [_currentHSIconView asphaleia_updateLabelWithText:@"Scan finger..."];
            }
        }
    }
}

-(void)registerForTouchIDNotifications {
    addObserver(touchIDNotificationReceived, "com.a3tweaks.asphaleia8.fingerdown");
    addObserver(touchIDNotificationReceived, "com.a3tweaks.asphaleia8.fingerup");
    addObserver(touchIDNotificationReceived, "com.a3tweaks.asphaleia8.authsuccess");
    addObserver(touchIDNotificationReceived, "com.a3tweaks.asphaleia8.authfailed");
}

-(void)deregisterForTouchIDNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(UIImage *)colouriseImage:(UIImage *)origImage withColour:(UIColor *)tintColour {
    UIGraphicsBeginImageContextWithOptions(origImage.size, NO, origImage.scale);
    CGContextRef imgContext = UIGraphicsGetCurrentContext();
    CGRect imageRect = CGRectMake(0, 0, origImage.size.width, origImage.size.height);
    CGContextScaleCTM(imgContext, 1, -1);
    CGContextTranslateCTM(imgContext, 0, -imageRect.size.height);
    CGContextSaveGState(imgContext);
    CGContextClipToMask(imgContext, imageRect, origImage.CGImage);
    [tintColour set];
    CGContextFillRect(imgContext, imageRect);
    CGContextRestoreGState(imgContext);
    CGContextSetBlendMode(imgContext, kCGBlendModeMultiply);
    CGContextDrawImage(imgContext, imageRect, origImage.CGImage);
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
}

-(void)dismissAnyAuthenticationAlerts {
    if (self.currentAuthAlert)
        [self.currentAuthAlert dismissWithClickedButtonIndex:[self.currentAuthAlert cancelButtonIndex] animated:YES];
}

- (NSArray *)allSubviewsOfView:(UIView *)view
{
    NSMutableArray *viewArray = [[NSMutableArray alloc] init];
    [viewArray addObject:view];
    for (UIView *subview in view.subviews)
    {
        [viewArray addObjectsFromArray:(NSArray *)[self allSubviewsOfView:subview]];
    }
    return [NSArray arrayWithArray:viewArray];
}

-(void)addSubview:(UIView *)view toAlertView:(UIAlertView *)alertView {
    UIView *labelSuperview;
    for (id subview in [self allSubviewsOfView:[[alertView _alertController] view]]){
        if ([subview isKindOfClass:[UILabel class]]) {
            labelSuperview = [subview superview];
        }
    }
    if ([labelSuperview respondsToSelector:@selector(addSubview:)]) {
        [labelSuperview addSubview:view];
    }
}

// UIAlertView delegate methods
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    SBApplication *application = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:currentAuthAppBundleID];
    SBApplicationIcon *appIcon = [[objc_getClass("SBApplicationIcon") alloc] initWithApplication:application];
    SBIconView *iconView = [[objc_getClass("SBIconView") alloc] initWithDefaultSize];
    [iconView _setIcon:appIcon animated:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.stopmonitoring"), NULL, NULL, YES);
    self.currentAuthAlert = nil;
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
            if (authenticated)
                _appUserAuthorisedID = currentAuthAppBundleID;
            authHandler(!authenticated);
        }];
    } else if (buttonIndex == [alertView cancelButtonIndex]) {
        authHandler(YES);
    }
}

- (void)willPresentAlertView:(UIAlertView *)alertView {
    if (self.currentAuthAlert)
        [self.currentAuthAlert dismissWithClickedButtonIndex:[self.currentAuthAlert cancelButtonIndex] animated:YES];

    self.currentAuthAlert = alertView;

    if (touchIDEnabled())
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.startmonitoring"), NULL, NULL, YES);
}

@end