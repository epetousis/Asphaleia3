#import "ASCommon.h"
#include <sys/sysctl.h>
#import "UIAlertView+Blocks.h"
#import <objc/runtime.h>
#import <AudioToolbox/AudioServices.h>
#import "NSTimer+Blocks.h"
#import "PreferencesHandler.h"
#import "ASPasscodeHandler.h"

#define kBundlePath @"/Library/Application Support/Asphaleia/AsphaleiaAssets.bundle"
#define titleWithSpacingForIcon(t) [NSString stringWithFormat:@"\n\n\n%@",t]
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface ASCommon ()
@property UIAlertView *currentAlertView;
@end

@implementation ASCommon

static ASCommon *sharedCommonObj;

+(instancetype)sharedInstance {
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedCommonObj = [[ASCommon alloc] init];
        [sharedCommonObj registerForTouchIDNotifications];
    });

    return sharedCommonObj;
}

-(void)dealloc {
    [self deregisterForTouchIDNotifications];
}

-(UIAlertView *)returnAppAuthenticationAlertWithIconView:(SBIconView *)iconView customMessage:(NSString *)customMessage delegate:(id<UIAlertViewDelegate>)delegate {
    /*if (!touchIDEnabled()) {
        return nil;
    }*/

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

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                   message:message
                   delegate:delegate
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];

    currentIconView = iconView;
    UIImage *iconImage = [iconView.icon getIconImage:2];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
    imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);
    imgView.center = CGPointMake(270/2,41); // 270 is the width of a UIAlertView.

    if (touchIDEnabled()) {
        imgView.image = [self colouriseImage:iconImage withColour:[UIColor colorWithWhite:0.f alpha:0.5f]];
        if (!fingerglyph) {
            fingerglyph = [[objc_getClass("PKGlyphView") alloc] initWithStyle:1];
            fingerglyph.secondaryColor = [UIColor grayColor];
            fingerglyph.primaryColor = [UIColor redColor];
            CGRect fingerframe = fingerglyph.frame;
            fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
            fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
            fingerglyph.frame = fingerframe;
            fingerglyph.center = CGPointMake(CGRectGetMidX(imgView.bounds),CGRectGetMidY(imgView.bounds));
        }
        [imgView addSubview:fingerglyph];
        alertViewAccessory = imgView;
    }

    return alertView;
}

-(UIAlertView *)returnAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType delegate:(id<UIAlertViewDelegate>)delegate {
    /*if (!touchIDEnabled()) {
        return nil;
    }*/

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

    __block UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
    imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);
    imgView.center = CGPointMake(270/2,32); // 270 is the width of a UIAlertView.
    alertViewAccessory = imgView;

    return alertView;
}

-(void)showAppAuthenticationAlertWithIconView:(SBIconView *)iconView customMessage:(NSString *)customMessage beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler {
    [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
    authHandler = [handler copy];

    UIAlertView *alertView = [self returnAppAuthenticationAlertWithIconView:iconView customMessage:customMessage delegate:self];

    if (!touchIDEnabled() && !passcodeEnabled()) {
        authHandler(NO);
        return;
    }

    if (!touchIDEnabled()) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
                authHandler(!authenticated);
            }];
        return;
    }

    [alertView show];
}

-(void)showAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler {
    [[objc_getClass("SBIconController") sharedInstance] asphaleia_resetAsphaleiaIconView];
    authHandler = [handler copy];

    UIAlertView *alertView = [self returnAuthenticationAlertOfType:alertType delegate:self];

    if (!touchIDEnabled() && !passcodeEnabled()) {
        authHandler(NO);
        return;
    }

    if (!touchIDEnabled()) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:nil eventBlock:^void(BOOL authenticated){
                authHandler(!authenticated);
            }];
        return;
    }

    [alertView show];
}

-(void)receiveTouchIDNotification:(NSNotification *)notification
{
    if (!self.currentAuthAlert) {
        return;
    }
    NSString *origTitle = self.currentAuthAlert.title;
    if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.fingerdown"]) {
        if ([origTitle containsString:@"\n\n\n"]) {
            self.currentAuthAlert.title = titleWithSpacingForIcon(@"Scanning finger...");
        } else {
            self.currentAuthAlert.title = titleWithSpacingForSmallIcon(@"Scanning finger...");
        }
        [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
            self.currentAuthAlert.title = origTitle;
        } repeats:NO];
        if (fingerglyph)
            [fingerglyph setState:1 animated:YES completionHandler:nil];
    } else if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.fingerup"]) {
        if (fingerglyph)
            [fingerglyph setState:0 animated:YES completionHandler:nil];
    } else if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.authsuccess"]) {
        [self.currentAuthAlert dismissWithClickedButtonIndex:-1 animated:YES];
        [[ASTouchIDController sharedInstance] stopMonitoring];
        if (fingerglyph)
            [fingerglyph setState:0 animated:YES completionHandler:nil];
        authHandler(NO);
        self.currentAuthAlert = nil;
    } else if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.authfailed"]) {
        self.currentAuthAlert.title = origTitle;
        if (fingerglyph)
            [fingerglyph setState:0 animated:YES completionHandler:nil];
    }
}

-(void)registerForTouchIDNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTouchIDNotification:) name:@"com.a3tweaks.asphaleia8.fingerdown" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTouchIDNotification:) name:@"com.a3tweaks.asphaleia8.fingerup" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTouchIDNotification:) name:@"com.a3tweaks.asphaleia8.authsuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTouchIDNotification:) name:@"com.a3tweaks.asphaleia8.authfailed" object:nil];
}

-(void)deregisterForTouchIDNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    SBIconView *iconView = currentIconView;
    currentIconView = nil;
    [[ASTouchIDController sharedInstance] stopMonitoring];
    self.currentAuthAlert = nil;
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
            authHandler(!authenticated);
        }];
    } else if (buttonIndex == [alertView cancelButtonIndex]) {
        authHandler(YES);
    }
}

- (void)willPresentAlertView:(UIAlertView *)alertView {
    [self addSubview:alertViewAccessory toAlertView:alertView];

    if (self.currentAuthAlert)
        [self.currentAuthAlert dismissWithClickedButtonIndex:[self.currentAuthAlert cancelButtonIndex] animated:YES];

    self.currentAuthAlert = alertView;

    if (touchIDEnabled())
        [[ASTouchIDController sharedInstance] startMonitoring];
}

/*- (void)didPresentAlertView:(UIAlertView *)alertView {
    if (touchIDEnabled())
        [[ASTouchIDController sharedInstance] startMonitoring];
}*/

@end