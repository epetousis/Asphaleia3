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

#define kBundlePath @"/Library/Application Support/Asphaleia/AsphaleiaAssets.bundle"

@interface UIAlertView ()
-(id)_alertController;
@end

@interface UIAlertController ()
@property (readonly) UIView * _foregroundView;
@property (readonly) UIView * _dimmingView;
-(UIView *)_foregroundView;
-(UIView *)_dimmingView;
-(id)_containedAlertController;
-(id)_alertControllerView;
-(id)_alertControllerContainer;
@end

@interface SBIconImageView ()
@property(assign, nonatomic) float brightness;
@end

@interface ASCommon ()
@property (readwrite) NSMutableArray *snapshotViews;
@property (readwrite) NSMutableArray *obscurityViews;
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

-(UIAlertView *)showAppAuthenticationAlertWithIconView:(SBIconView *)iconView beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler {
    // need to add customisation to this...
    // icon at the top-centre of the alert
    NSString *message = nil;
    if (touchIDEnabled())
        message = @"Scan fingerprint to open.";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:iconView.icon.displayName
                   message:message
                   delegate:nil
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];
    BOOL vibrateOnBadFinger = shouldVibrateOnIncorrectFingerprint();

    UIViewController *v = [[UIViewController alloc] init];
    SBIconView *customIconView = [[objc_getClass("SBIconView") alloc] initWithDefaultSize];
    [customIconView _setIcon:[iconView icon] animated:YES];
    // Little hack to get rid of the badge
    for (UIView *subview in customIconView.subviews) {
        if (![subview isKindOfClass:[objc_getClass("SBIconImageView") class]])
            [subview removeFromSuperview];
    }
    [customIconView setLabelAccessoryViewHidden:YES];
    [customIconView setLabelHidden:YES];
    v.view.frame = CGRectMake(0,0,270,30);
    customIconView.center = CGPointMake(CGRectGetMidX(v.view.bounds),CGRectGetMidY(v.view.bounds)+20);
    customIconView.userInteractionEnabled = NO;
    [v.view addSubview:customIconView];

    __block PKGlyphView *fingerglyph;
    if (touchIDEnabled()) {
        [customIconView setHighlighted:YES];
        fingerglyph = [[objc_getClass("PKGlyphView") alloc] initWithStyle:1];
        fingerglyph.secondaryColor = [UIColor redColor];
        fingerglyph.primaryColor = [UIColor whiteColor];
        CGRect fingerframe = fingerglyph.frame;
        fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
        fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
        fingerglyph.frame = fingerframe;
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,fingerframe.size.width,fingerframe.size.height)];
        containerView.center = [iconView _iconImageView].center;
        [containerView addSubview:fingerglyph];
        [customIconView addSubview:containerView];
    }

    [[alertView _alertController] setValue:v forKey:@"contentViewController"];
    [(UIAlertController *)[alertView _alertController]_foregroundView].alpha = 0.0;

    __block BTTouchIDController *controller = [[BTTouchIDController alloc] initWithEventBlock:^void(BTTouchIDController *controller, id monitor, unsigned event) {
        switch (event) {
            case TouchIDFingerDown:
                alertView.title = @"Scanning finger...";
                [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
                    alertView.title = iconView.icon.displayName;
                } repeats:NO];
                [fingerglyph setState:1 animated:YES completionHandler:nil];
                break;
            case TouchIDFingerUp:
                [fingerglyph setState:0 animated:YES completionHandler:nil];
                break;
            case TouchIDNotMatched:
                alertView.title = iconView.icon.displayName;
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
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [[ASPasscodeHandler sharedInstance] showInKeyWindowWithEventBlock:^void(BOOL authenticated){
                handler(!authenticated);
            } passcode:getPasscode()];
        } else {
            handler(YES);
        }
    };

    if (!touchIDEnabled() && !passcodeEnabled()) {
        alertView.didPresentBlock = ^(UIAlertView *alertView) {
            [alertView dismissWithClickedButtonIndex:-1 animated:YES];
            handler(NO);
            return;
        };
        return alertView;
    }

    if (!touchIDEnabled()) {
        alertView.willPresentBlock = ^(UIAlertView *alertView) {
            [[ASPasscodeHandler sharedInstance] showInKeyWindowWithEventBlock:^void(BOOL authenticated){
                handler(!authenticated);
            } passcode:getPasscode()];
            return;
        };
        alertView.didPresentBlock = ^(UIAlertView *alertView) {
            [alertView dismissWithClickedButtonIndex:-1 animated:YES];
        };
        return alertView;
    }

    if (shouldBeginMonitoringOnWillPresent) {
        alertView.willPresentBlock = ^(UIAlertView *alertView) {
        if (!touchIDEnabled() && !passcodeEnabled()) {
            [alertView dismissWithClickedButtonIndex:-1 animated:YES];
            handler(NO);
            return;
        }
        if (touchIDEnabled())
            [controller startMonitoring];
        };
    } else {
        alertView.didPresentBlock = ^(UIAlertView *alertView) {
        if (!touchIDEnabled() && !passcodeEnabled()) {
            [alertView dismissWithClickedButtonIndex:-1 animated:YES];
            handler(NO);
            return;
        }
        if (touchIDEnabled())
            [controller startMonitoring];
        };
    }

    return alertView;
}

-(UIAlertView *)createAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType beginMesaMonitoringBeforeShowing:(BOOL)shouldBeginMonitoringOnWillPresent dismissedHandler:(ASCommonAuthenticationHandler)handler {
    NSString *title;
    NSString *message = nil;
    switch (alertType) {
        case ASAuthenticationAlertAppArranging:
            title = @"Arrange Apps";
            break;
        case ASAuthenticationAlertSwitcher:
            title = @"Multitasking";
            break;
        case ASAuthenticationAlertSpotlight:
            title = @"Spotlight";
            break;
        case ASAuthenticationAlertPowerDown:
            title = @"Slide to Power Off";
            break;
        case ASAuthenticationAlertControlCentre:
            title = @"Control Center";
            break;
        case ASAuthenticationAlertControlPanel:
            title = @"Asphaleia Control Panel";
            break;
        default:
            title = @"Asphaleia";
            break;
    }
    if (touchIDEnabled())
        message = @"Scan fingerprint to access.";

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                   message:message
                   delegate:nil
         cancelButtonTitle:@"Cancel"
         otherButtonTitles:@"Passcode",nil];
    BOOL vibrateOnBadFinger = shouldVibrateOnIncorrectFingerprint();

    __block BTTouchIDController *controller = [[BTTouchIDController alloc] initWithEventBlock:^void(BTTouchIDController *controller, id monitor, unsigned event) {
        switch (event) {
            case TouchIDFingerDown:
                alertView.title = @"Scanning finger...";
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
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [[ASPasscodeHandler sharedInstance] showInKeyWindowWithEventBlock:^void(BOOL authenticated){
                handler(!authenticated);
            } passcode:getPasscode()];
        } else {
            handler(YES);
        }
    };
    if (shouldBeginMonitoringOnWillPresent) {
        alertView.willPresentBlock = ^(UIAlertView *alertView) {
        if (!touchIDEnabled() && !passcodeEnabled()) {
            [alertView dismissWithClickedButtonIndex:-1 animated:YES];
            handler(NO);
            return;
        }
        if (touchIDEnabled())
            [controller startMonitoring];
        };
    } else {
        alertView.didPresentBlock = ^(UIAlertView *alertView) {
        if (!touchIDEnabled() && !passcodeEnabled()) {
            [alertView dismissWithClickedButtonIndex:-1 animated:YES];
            handler(NO);
            return;
        }
        if (touchIDEnabled())
            [controller startMonitoring];
        };
    }

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

-(BOOL)shouldAddObscurityViewForSnapshotView:(SBAppSwitcherSnapshotView *)snapshotView {
    return [self.snapshotViews indexOfObject:snapshotView] == NSNotFound;
}

-(UIView *)obscurityViewForSnapshotView:(SBAppSwitcherSnapshotView *)snapshotView {
    if (self.snapshotViews && [self.snapshotViews indexOfObject:snapshotView] != NSNotFound)
        return [self.obscurityViews objectAtIndex:[self.snapshotViews indexOfObject:snapshotView]];

    NSBundle *asphaleiaAssets = [[NSBundle alloc] initWithPath:kBundlePath];
    UIImage *obscurityEye = [UIImage imageNamed:@"unocme.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];

    UIView *obscurityView = [[UIView alloc] initWithFrame:snapshotView.bounds];
    obscurityView.backgroundColor = [UIColor blackColor];
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

@end