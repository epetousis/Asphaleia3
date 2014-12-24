#import "ASCommon.h"
#include <sys/sysctl.h>
#import "UIAlertView+Blocks.h"
#import "BTTouchIDController.h"
#import <objc/runtime.h>
#import "PKGlyphView.h"
#import <AudioToolbox/AudioServices.h>
#import "NSTimer+Blocks.h"
#import "PreferencesHandler.h"
#import "ASPasscodeHandler.h"
#import "SBIconController.h"

#define kBundlePath @"/Library/Application Support/Asphaleia/AsphaleiaAssets.bundle"
#define titleWithSpacingForIcon(t) [NSString stringWithFormat:@"\n\n\n%@",t]
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

@interface ASCommon ()
@property (readwrite) NSMutableArray *snapshotViews;
@property (readwrite) NSMutableArray *obscurityViews;
@property UIAlertView *currentAlertView;
@end

@implementation ASCommon

static ASCommon *sharedCommonObj;

+(instancetype)sharedInstance {
    @synchronized(self) {
        if (!sharedCommonObj)
            sharedCommonObj = [[ASCommon alloc] init];
    }

    return sharedCommonObj;
}

-(void)showAppAuthenticationAlertWithIconView:(SBIconView *)iconView beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler {
    [[objc_getClass("SBIconController") sharedInstance] resetAsphaleiaIconView];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:titleWithSpacingForIcon(iconView.icon.displayName)
                   message:@"Scan fingerprint to open."
                   delegate:nil
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];
    BOOL vibrateOnBadFinger = shouldVibrateOnIncorrectFingerprint();

    UIImage *iconImage = [iconView.icon getIconImage:2];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
    imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);
    imgView.center = CGPointMake(270/2,41); // 270 is the width of a UIAlertView.

    __block PKGlyphView *fingerglyph;
    if (touchIDEnabled()) {
        imgView.image = [self colouriseImage:iconImage withColour:[UIColor colorWithWhite:0.f alpha:0.5f]];
        fingerglyph = [[objc_getClass("PKGlyphView") alloc] initWithStyle:1];
        fingerglyph.secondaryColor = [UIColor grayColor];
        fingerglyph.primaryColor = [UIColor redColor];
        CGRect fingerframe = fingerglyph.frame;
        fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
        fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
        fingerglyph.frame = fingerframe;
        fingerglyph.center = CGPointMake(CGRectGetMidX(imgView.bounds),CGRectGetMidY(imgView.bounds));
        [imgView addSubview:fingerglyph];
    }

    __block BTTouchIDController *controller = [[BTTouchIDController alloc] initWithEventBlock:^void(BTTouchIDController *controller, id monitor, unsigned event) {
        switch (event) {
            case TouchIDFingerDown:
                alertView.title = titleWithSpacingForIcon(@"Scanning finger...");
                [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
                    alertView.title = iconView.icon.displayName;
                } repeats:NO];
                [fingerglyph setState:1 animated:YES completionHandler:nil];
                break;
            case TouchIDFingerUp:
                [fingerglyph setState:0 animated:YES completionHandler:nil];
                break;
            case TouchIDNotMatched:
                alertView.title = titleWithSpacingForIcon(iconView.icon.displayName);
                [fingerglyph setState:0 animated:YES completionHandler:nil];
                if (vibrateOnBadFinger)
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                break;
            case TouchIDMatched:
                [alertView dismissWithClickedButtonIndex:-1 animated:YES];
                [controller stopMonitoring];
                handler(NO);
                break;
        }
    }];
    alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        [controller stopMonitoring];
        self.currentAlertView = nil;
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
                handler(!authenticated);
            }];
        } else {
            handler(YES);
        }
    };

    if (!touchIDEnabled() && !passcodeEnabled()) {
        handler(NO);
        return;
    }

    if (!touchIDEnabled()) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
                handler(!authenticated);
            }];
        return;
    }

    alertView.willPresentBlock = ^(UIAlertView *alertView) {
        UIView *labelSuperview;
        for (id subview in [self allSubviewsOfView:[[alertView _alertController] view]]){
            if ([subview isKindOfClass:[UILabel class]]) {
                labelSuperview = [subview superview];
            }
        }
        if ([labelSuperview respondsToSelector:@selector(addSubview:)]) {
            [labelSuperview addSubview:imgView];
        }
    };

    if (shouldBeginMonitoringOnWillPresent) {
        alertView.willPresentBlock = ^(UIAlertView *alertView) {
            UIView *labelSuperview;
            for (id subview in [self allSubviewsOfView:[[alertView _alertController] view]]){
                if ([subview isKindOfClass:[UILabel class]]) {
                    labelSuperview = [subview superview];
                }
            }
            if ([labelSuperview respondsToSelector:@selector(addSubview:)]) {
                [labelSuperview addSubview:imgView];
            }

        if (touchIDEnabled())
            [controller startMonitoring];
        };
    } else {
        alertView.didPresentBlock = ^(UIAlertView *alertView) {
        if (touchIDEnabled())
            [controller startMonitoring];
        };
    }

    if (self.currentAlertView)
        [self.currentAlertView dismissWithClickedButtonIndex:[self.currentAlertView cancelButtonIndex] animated:YES];

    self.currentAlertView = alertView;

    [alertView show];
}

-(void)showAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler {
    [[objc_getClass("SBIconController") sharedInstance] resetAsphaleiaIconView];
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
        default:
            title = @"Asphaleia";
            iconImage = [UIImage imageNamed:@"IconDefault.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];
            break;
    }
    title = titleWithSpacingForSmallIcon(title);

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                   message:@"Scan fingerprint to access."
                   delegate:nil
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];
    BOOL vibrateOnBadFinger = shouldVibrateOnIncorrectFingerprint();

    __block BTTouchIDController *controller = [[BTTouchIDController alloc] initWithEventBlock:^void(BTTouchIDController *controller, id monitor, unsigned event) {
        switch (event) {
            case TouchIDFingerDown:
                alertView.title = titleWithSpacingForSmallIcon(@"Scanning finger...");
                [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
                    alertView.title = title;
                } repeats:NO];
                break;
            case TouchIDNotMatched:
                alertView.title = title;
                if (vibrateOnBadFinger)
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                break;
            case TouchIDMatched:
                [alertView dismissWithClickedButtonIndex:-1 animated:YES];
                [controller stopMonitoring];
                handler(NO);
                break;
        }
    }];
    alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        [controller stopMonitoring];
        self.currentAlertView = nil;
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:nil eventBlock:^void(BOOL authenticated){
                handler(!authenticated);
            }];
        } else {
            handler(YES);
        }
    };

    if (!touchIDEnabled() && !passcodeEnabled()) {
        handler(NO);
        return;
    }

    if (!touchIDEnabled()) {
        [[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:nil eventBlock:^void(BOOL authenticated){
            handler(!authenticated);
        }];
        return;
    }

    UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
    imgView.frame = CGRectMake(0,0,iconImage.size.width,iconImage.size.height);
    imgView.center = CGPointMake(270/2,32); // 270 is the width of a UIAlertView.

    alertView.willPresentBlock = ^(UIAlertView *alertView) {
        UIView *labelSuperview;
        for (id subview in [self allSubviewsOfView:[[alertView _alertController] view]]){
            if ([subview isKindOfClass:[UILabel class]]) {
                labelSuperview = [subview superview];
            }
        }
        if ([labelSuperview respondsToSelector:@selector(addSubview:)]) {
            [labelSuperview addSubview:imgView];
        }
    };

    if (shouldBeginMonitoringOnWillPresent) {
        alertView.willPresentBlock = ^(UIAlertView *alertView) {
        UIView *labelSuperview;
        for (id subview in [self allSubviewsOfView:[[alertView _alertController] view]]){
            if ([subview isKindOfClass:[UILabel class]]) {
                labelSuperview = [subview superview];
            }
        }
        if ([labelSuperview respondsToSelector:@selector(addSubview:)]) {
            [labelSuperview addSubview:imgView];
        }

        if (touchIDEnabled())
            [controller startMonitoring];
        };
    } else {
        alertView.didPresentBlock = ^(UIAlertView *alertView) {
        if (touchIDEnabled())
            [controller startMonitoring];
        };
    }

    if (self.currentAlertView)
        [self.currentAlertView dismissWithClickedButtonIndex:[self.currentAlertView cancelButtonIndex] animated:YES];

    self.currentAlertView = alertView;

    [alertView show];
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

-(BOOL)shouldAddObscurityViewForSnapshotView:(SBAppSwitcherSnapshotView *)snapshotView {
    return [self.snapshotViews indexOfObject:snapshotView] == NSNotFound;
}

-(UIView *)obscurityViewForSnapshotView:(SBAppSwitcherSnapshotView *)snapshotView {
    if (self.snapshotViews && [self.snapshotViews indexOfObject:snapshotView] != NSNotFound)
        return [self.obscurityViews objectAtIndex:[self.snapshotViews indexOfObject:snapshotView]];

    NSBundle *asphaleiaAssets = [[NSBundle alloc] initWithPath:kBundlePath];
    UIImage *obscurityEye = [UIImage imageNamed:@"unocme.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];

    UIView *obscurityView = [[UIView alloc] initWithFrame:snapshotView.bounds];
    obscurityView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.7f];

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = obscurityEye;
    imageView.frame = CGRectMake(0, 0, obscurityEye.size.width*2, obscurityEye.size.height*2);
    imageView.center = obscurityView.center;
    [obscurityView addSubview:imageView];

    [self.snapshotViews addObject:snapshotView];
    [self.obscurityViews insertObject:obscurityView atIndex:[self.snapshotViews indexOfObject:snapshotView]];
    return obscurityView;
}

-(void)obscurityViewRemovedForSnapshotView:(SBAppSwitcherSnapshotView *)snapshotView {
    [self.obscurityViews removeObjectAtIndex:[self.snapshotViews indexOfObject:snapshotView]];
    [self.snapshotViews removeObject:snapshotView];
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
    if (self.currentAlertView)
        [self.currentAlertView dismissWithClickedButtonIndex:[self.currentAlertView cancelButtonIndex] animated:YES];
}

- (NSMutableArray *)allSubviewsOfView:(UIView *)view
{
    NSMutableArray *viewArray = [NSMutableArray array];
    [viewArray addObject:view];
    for (UIView *subview in view.subviews)
    {
        [viewArray addObjectsFromArray:(NSArray *)[self allSubviewsOfView:subview]];
    }
    return viewArray;
}

@end