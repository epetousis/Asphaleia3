#import <UIKit/UIKit.h>
#import "PKGlyphView.h"
#import "BTTouchIDController.h"
#import "ASCommon.h"
#import "SBIconView.h"
#import "SBIcon.h"
#import "SBIconController.h"
#import "PreferencesHandler.h"
#import "substrate.h"
#import "UIImage+ImageEffects.h"
#import "SBUIController.h"
#import "SBDisplayLayout.h"
#import "SBDisplayItem.h"
#import "SBAppSwitcherIconController.h"
#import "SBAppSwitcherSnapshotView.h"
#import "CAFilter.h"
#import "SBApplication.h"
#import "SBApplicationIcon.h"
#import "SpringBoard.h"
#import "SBSearchViewController.h"
#import "SBControlCenterController.h"
#import <AudioToolbox/AudioServices.h>
#import "ASActivatorListener.h"
#import "ASControlPanel.h"
#import "NSTimer+Blocks.h"
#import "ASPasscodeHandler.h"
#import "ASTouchWindow.h"
#import "SBIconLabelView.h"
#import "SBIconLabelImageParameters.h"
#import "SBBannerContainerViewController.h"
#import "BBBulletin.h"
#import "SBApplicationController.h"

#define kBundlePath @"/Library/Application Support/Asphaleia/AsphaleiaAssets.bundle"

#define Log() NSLog(@"[Asphaleia] Method called: %@",NSStringFromSelector(_cmd))

PKGlyphView *fingerglyph;
SBIconView *currentIconView;
SBAppSwitcherIconController *iconController;
NSString *temporarilyUnlockedAppBundleID;
NSTimer *currentTempUnlockTimer;
NSTimer *currentTempGlobalDisableTimer;
ASTouchWindow *anywhereTouchWindow;
BOOL appAlreadyAuthenticated;

void RegisterForTouchIDNotifications(id observer, SEL selector) {
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"com.a3tweaks.asphaleia8.fingerdown" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"com.a3tweaks.asphaleia8.fingerup" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"com.a3tweaks.asphaleia8.authsuccess" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"com.a3tweaks.asphaleia8.authfailed" object:nil];
}

void DeregisterForTouchIDNotifications(id observer) {
	[[NSNotificationCenter defaultCenter] removeObserver:observer];
}

%hook SBIconController

-(id)init {
	SBIconController *controller = %orig;
	RegisterForTouchIDNotifications(controller, @selector(receiveTouchIDNotification:));
	return controller;
}

-(void)iconTapped:(SBIconView *)iconView {
	if ([ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled) {
		[[%c(SBIconController) sharedInstance] asphaleia_resetAsphaleiaIconView];
		%orig;
		return;
	}

	if (fingerglyph && currentIconView) {
		[iconView setHighlighted:NO];
		if ([iconView isEqual:currentIconView]) {
			[[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
				if (authenticated) {
					appAlreadyAuthenticated = YES;
					[iconView.icon launchFromLocation:iconView.location];
				}
			}];
		}
		[[%c(SBIconController) sharedInstance] asphaleia_resetAsphaleiaIconView];

		return;
	} else if ((![getProtectedApps() containsObject:iconView.icon.applicationBundleID] && !shouldProtectAllApps()) || ([temporarilyUnlockedAppBundleID isEqual:iconView.icon.applicationBundleID] && !shouldProtectAllApps()) || !iconView.icon.applicationBundleID) {
		%orig;
		return;
	} else if (!touchIDEnabled() && passcodeEnabled()) {
		[[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
			[iconView setHighlighted:NO];

			if (authenticated){
				appAlreadyAuthenticated = YES;
				%orig;
			}
		}];
		return;
	}

	if (!anywhereTouchWindow) {
		anywhereTouchWindow = [[ASTouchWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	}

	currentIconView = iconView;

	if (!fingerglyph) {
		fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:1];
		fingerglyph.secondaryColor = [UIColor grayColor];
		fingerglyph.primaryColor = [UIColor redColor];
	}

	CGRect fingerframe = fingerglyph.frame;
	fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
	fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
	fingerglyph.frame = fingerframe;
	fingerglyph.center = CGPointMake(CGRectGetMidX([iconView _iconImageView].bounds),CGRectGetMidY([iconView _iconImageView].bounds));
	[[iconView _iconImageView] addSubview:fingerglyph];

	fingerglyph.transform = CGAffineTransformMakeScale(0.01,0.01);
	[UIView animateWithDuration:0.3f animations:^{
		fingerglyph.transform = CGAffineTransformMakeScale(1,1);
	}];

	[[BTTouchIDController sharedInstance] startMonitoring];

	[currentIconView asphaleia_updateLabelWithText:@"Scan finger..."];

	[anywhereTouchWindow blockTouchesAllowingTouchInView:currentIconView touchBlockedHandler:^void(ASTouchWindow *touchWindow, BOOL blockedTouch){
		if (blockedTouch) {
			[[%c(SBIconController) sharedInstance] asphaleia_resetAsphaleiaIconView];
		}
	}];
}

-(void)iconHandleLongPress:(SBIconView *)iconView {
	if (self.isEditing || !shouldSecureAppArrangement() || [ASPreferencesHandler sharedInstance].asphaleiaDisabled) {
		%orig;
		return;
	}

	[iconView setHighlighted:NO];
	[iconView cancelLongPressTimer];
	[iconView setTouchDownInIcon:NO];
	
	[[ASCommon sharedInstance] showAuthenticationAlertOfType:ASAuthenticationAlertAppArranging beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
		if (!wasCancelled)
			[self setIsEditing:YES];
		}];
}

%new
-(void)asphaleia_resetAsphaleiaIconView {
	if (fingerglyph && currentIconView) {
		[currentIconView _updateLabel];

		[UIView animateWithDuration:0.3f animations:^{
			fingerglyph.transform = CGAffineTransformMakeScale(0.01,0.01);
		}];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[currentIconView setHighlighted:NO];
			[[BTTouchIDController sharedInstance] stopMonitoring];

			[fingerglyph removeFromSuperview];
			fingerglyph.transform = CGAffineTransformMakeScale(1,1);
			[fingerglyph setState:0 animated:YES completionHandler:nil];

			currentIconView = nil;
			[anywhereTouchWindow setHidden:YES];
		});
	}
}

%new
-(void)receiveTouchIDNotification:(NSNotification *)notification
{
	if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.fingerdown"]) {
		if (fingerglyph && currentIconView) {
			[fingerglyph setState:1 animated:YES completionHandler:nil];
			[currentIconView asphaleia_updateLabelWithText:@"Scanning..."];
		}
	} else if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.fingerup"]) {
		if (fingerglyph)
			[fingerglyph setState:0 animated:YES completionHandler:nil];
	} else if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.authsuccess"]) {
		if (fingerglyph && currentIconView) {
			appAlreadyAuthenticated = YES;
			[currentIconView.icon launchFromLocation:currentIconView.location];
			[[%c(SBIconController) sharedInstance] asphaleia_resetAsphaleiaIconView];
		}
	} else if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.authfailed"]) {
		if (fingerglyph && currentIconView) {
			[fingerglyph setState:0 animated:YES completionHandler:nil];
			[currentIconView asphaleia_updateLabelWithText:@"Scan finger..."];
		}
	}
}

%end

%hook SBIconView

%new
-(void)asphaleia_updateLabelWithText:(NSString *)text {
	SBIconLabelView *iconLabelView = [self valueForKey:@"_labelView"];

	SBIconLabelImageParameters *imageParameters = [[iconLabelView imageParameters] mutableCopy];
	[imageParameters setText:text];
	[%c(SBIconLabelView) updateIconLabelView:iconLabelView withSettings:nil imageParameters:imageParameters];
}

%end

%hook SBAppSwitcherController
BOOL switcherAppAlreadyAuthenticated;

-(void)switcherScroller:(id)scroller itemTapped:(SBDisplayLayout *)displayLayout {
	Log();
	SBDisplayItem *item = [displayLayout.displayItems objectAtIndex:0];
	NSMutableDictionary *iconViews = [iconController valueForKey:@"_iconViews"];

	SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];

	SBIconView *iconView = [iconViews objectForKey:displayLayout];

	if ((![getProtectedApps() containsObject:item.displayIdentifier] && !shouldProtectAllApps()) || !shouldObscureAppContent() || [temporarilyUnlockedAppBundleID isEqual:item.displayIdentifier] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || [item.displayIdentifier isEqual:[frontmostApp bundleIdentifier]] || !iconView.icon.displayName) {
		%orig;
		return;
	}

	[[ASCommon sharedInstance] showAppAuthenticationAlertWithIconView:iconView customMessage:nil beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
	switcherAppAlreadyAuthenticated = YES;
	if (!wasCancelled)
		%orig;
	}];
}

-(void)switcherWasDismissed:(BOOL)dismissed {
	switcherAppAlreadyAuthenticated = NO;
	%orig;
}

-(void)_askDelegateToDismissToDisplayLayout:(SBDisplayLayout *)displayLayout displayIDsToURLs:(id)urls displayIDsToActions:(id)actions {
	Log();
	SBDisplayItem *item = [displayLayout.displayItems objectAtIndex:0];
	NSMutableDictionary *iconViews = [iconController valueForKey:@"_iconViews"];

	SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];

	SBIconView *iconView = [iconViews objectForKey:displayLayout];

	if ((![getProtectedApps() containsObject:item.displayIdentifier] && !shouldProtectAllApps()) || !shouldObscureAppContent() || [temporarilyUnlockedAppBundleID isEqual:item.displayIdentifier] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || [item.displayIdentifier isEqual:[frontmostApp bundleIdentifier]] || !iconView.icon.displayName || switcherAppAlreadyAuthenticated) {
		%orig;
		return;
	}

	[[ASCommon sharedInstance] showAppAuthenticationAlertWithIconView:iconView customMessage:nil beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
	switcherAppAlreadyAuthenticated = NO;
	if (!wasCancelled)
		%orig;
	else
		[[%c(SBUIController) sharedInstanceIfExists] clickedMenuButton];
	}];
}

%end

%hook SBAppSwitcherIconController

-(id)init {
	iconController = %orig;
	return iconController;
}

%end

%hook SBAppSwitcherSnapshotView

-(void)_layoutStatusBar {
	if ((![getProtectedApps() containsObject:self.displayItem.displayIdentifier] && !shouldProtectAllApps()) || !shouldObscureAppContent() || [temporarilyUnlockedAppBundleID isEqual:self.displayItem.displayIdentifier] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled)
		%orig;
}

+ (id)appSwitcherSnapshotViewForDisplayItem:(SBDisplayItem*)displayItem orientation:(int)orientation loadAsync:(BOOL)async withQueue:(id)queue statusBarCache:(id)cache {
	if ((![getProtectedApps() containsObject:displayItem.displayIdentifier] && !shouldProtectAllApps()) || !shouldObscureAppContent() || [temporarilyUnlockedAppBundleID isEqual:displayItem.displayIdentifier] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled) {
		return %orig;
	}

	UIImageView *snapshot = (UIImageView *)%orig();
	CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
	[filter setValue:@10 forKey:@"inputRadius"];
	UIImageView *snapshotImageView2 = [snapshot valueForKey:@"_containerView"];
	snapshotImageView2.layer.filters = [NSArray arrayWithObject:filter];
	[snapshot setValue:snapshotImageView2 forKey:@"_containerView"];

	NSBundle *asphaleiaAssets = [[NSBundle alloc] initWithPath:kBundlePath];
	UIImage *obscurityEye = [UIImage imageNamed:@"unocme.png" inBundle:asphaleiaAssets compatibleWithTraitCollection:nil];

	UIView *obscurityView = [[UIView alloc] initWithFrame:snapshot.bounds];
	obscurityView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.7f];

	UIImageView *imageView = [[UIImageView alloc] init];
	imageView.image = obscurityEye;
	imageView.frame = CGRectMake(0, 0, obscurityEye.size.width*2, obscurityEye.size.height*2);
	imageView.center = obscurityView.center;
	[obscurityView addSubview:imageView];

	obscurityView.tag = 80085; // ;)
	[snapshot addSubview:obscurityView];
	return snapshot;
}

%end

%hook SBUIController
BOOL switcherAuthenticating;

-(void)_toggleSwitcher {
	Log();
	if (!shouldSecureSwitcher()) {
		%orig;
		return;
	}
	if (!switcherAuthenticating) {
		switcherAuthenticating = YES;
		[[ASCommon sharedInstance] showAuthenticationAlertOfType:ASAuthenticationAlertSwitcher beginMesaMonitoringBeforeShowing:NO dismissedHandler:^(BOOL wasCancelled) {
			switcherAuthenticating = NO;
			if (!wasCancelled)
				%orig;
			}];
	}
}

-(BOOL)isAppSwitcherShowing {
	if (switcherAuthenticating)
		return YES;
	else
		return %orig;
}

- (void)activateApplicationAnimated:(id)application {
	Log();
	if ((![getProtectedApps() containsObject:[application bundleIdentifier]] && !shouldProtectAllApps()) || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || appAlreadyAuthenticated) {
		appAlreadyAuthenticated = NO;
		%orig;
		return;
	}

	appAlreadyAuthenticated = NO;

	SBApplicationIcon *appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:application];
	SBIconView *iconView = [[%c(SBIconView) alloc] initWithDefaultSize];
	[iconView _setIcon:appIcon animated:YES];

	[[ASCommon sharedInstance] showAppAuthenticationAlertWithIconView:iconView customMessage:nil beginMesaMonitoringBeforeShowing:NO dismissedHandler:^(BOOL wasCancelled) {
			if (!wasCancelled) {
				%orig;
			}
		}];
}

%end

%hook SBLockScreenManager

-(void)_lockUI {
	[[%c(SBIconController) sharedInstance] asphaleia_resetAsphaleiaIconView];
	[[ASCommon sharedInstance] dismissAnyAuthenticationAlerts];
	[[ASPasscodeHandler sharedInstance] dismissPasscodeView];
	%orig;
	if (shouldResetAppExitTimerOnLock() && currentTempUnlockTimer) {
		[currentTempUnlockTimer fire];
		[currentTempGlobalDisableTimer fire];
	}
}

-(void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
	%orig;
	if (shouldDelayAppSecurity()) {
		[ASPreferencesHandler sharedInstance].appSecurityDisabled = YES;
		currentTempGlobalDisableTimer = [NSTimer scheduledTimerWithTimeInterval:appSecurityDelayTimeInterval() block:^{
			[ASPreferencesHandler sharedInstance].appSecurityDisabled = NO;
		} repeats:NO];
		return;
	}

	SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
	if (([getProtectedApps() containsObject:[frontmostApp bundleIdentifier]] || shouldProtectAllApps()) && !shouldUnsecurelyUnlockIntoApp() && frontmostApp && ![temporarilyUnlockedAppBundleID isEqual:[frontmostApp bundleIdentifier]]) {
		SBApplicationIcon *appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:frontmostApp];
		SBIconView *iconView = [[%c(SBIconView) alloc] initWithDefaultSize];
		[iconView _setIcon:appIcon animated:YES];

		__block UIWindow *blurredWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		blurredWindow.backgroundColor = [UIColor clearColor];

		UIVisualEffect *blurEffect;
		blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
		
		UIVisualEffectView *visualEffectView;
		visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		
		visualEffectView.frame = [[UIScreen mainScreen] bounds];

		blurredWindow.windowLevel = UIWindowLevelAlert-1;
		[blurredWindow addSubview:visualEffectView];
		[blurredWindow makeKeyAndVisible];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[[ASCommon sharedInstance] showAppAuthenticationAlertWithIconView:iconView customMessage:nil beginMesaMonitoringBeforeShowing:NO dismissedHandler:^(BOOL wasCancelled) {
				blurredWindow.hidden = YES;

				if (wasCancelled) {
					[[%c(SBUIController) sharedInstanceIfExists] clickedMenuButton];
				}
			}];
		});
	}
}

%end

%hook SBSearchViewController
static BOOL searchControllerHasAuthenticated;
static BOOL searchControllerAuthenticating;

-(void)_setShowingKeyboard:(BOOL)keyboard {
	%orig;
	if (keyboard && !searchControllerHasAuthenticated && !searchControllerAuthenticating && shouldSecureSpotlight()) {
		[self cancelButtonPressed];
		[[ASCommon sharedInstance] showAuthenticationAlertOfType:ASAuthenticationAlertSpotlight beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
		searchControllerAuthenticating = NO;
		if (!wasCancelled) {
			searchControllerHasAuthenticated = YES;
			[(SpringBoard *)[UIApplication sharedApplication] _revealSpotlight];
			[self _setShowingKeyboard:YES];
		}
		}];
		searchControllerAuthenticating = YES;
	}
}

-(void)_handleDismissGesture {
	searchControllerHasAuthenticated = NO;
	searchControllerAuthenticating = NO;
	%orig;
}

-(void)dismiss {
	searchControllerHasAuthenticated = NO;
	searchControllerAuthenticating = NO;
	%orig;
}

%end

%hook SBPowerDownController

-(void)orderFront {
	if (!shouldSecurePowerDownView()) {
		%orig;
		return;
	}

	[[ASCommon sharedInstance] showAuthenticationAlertOfType:ASAuthenticationAlertPowerDown beginMesaMonitoringBeforeShowing:NO dismissedHandler:^(BOOL wasCancelled) {
	if (!wasCancelled)
		%orig;
	}];
}

%end

%hook SBControlCenterController
static BOOL controlCentreAuthenticating;
static BOOL controlCentreHasAuthenticated;

-(void)presentAnimated:(BOOL)animated completion:(id)completion {
	if (controlCentreAuthenticating) {
		return;
	}

	if (!shouldSecureControlCentre() || controlCentreHasAuthenticated) {
		%orig;
		return;
	}

	controlCentreAuthenticating = YES;
	[[ASCommon sharedInstance] showAuthenticationAlertOfType:ASAuthenticationAlertControlCentre beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
	controlCentreAuthenticating = NO;
	if (!wasCancelled) {
		controlCentreHasAuthenticated = YES;
		%orig;
	}
	}];
}

-(void)beginTransitionWithTouchLocation:(CGPoint)touchLocation {
	if (!shouldSecureControlCentre() || controlCentreHasAuthenticated || controlCentreAuthenticating) {
		%orig;
		return;
	}

	controlCentreAuthenticating = YES;
	[[ASCommon sharedInstance] showAuthenticationAlertOfType:ASAuthenticationAlertControlCentre beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
	controlCentreAuthenticating = NO;
	if (!wasCancelled) {
		controlCentreHasAuthenticated = YES;
		[self presentAnimated:YES];
	}
	}];
}

-(void)_endPresentation {
	controlCentreHasAuthenticated = NO;
	controlCentreAuthenticating = NO;
	%orig;
}

%end

%hook SBApplication

-(void)willAnimateDeactivation:(BOOL)deactivation {
	%orig;
	if (![getProtectedApps() containsObject:[self bundleIdentifier]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled)
		return;

	if (currentTempUnlockTimer)
		[currentTempUnlockTimer fire];

	if (appExitUnlockTimeInterval() <= 0)
		return;

	temporarilyUnlockedAppBundleID = [self bundleIdentifier];
	currentTempUnlockTimer = [NSTimer scheduledTimerWithTimeInterval:appExitUnlockTimeInterval() block:^{
		temporarilyUnlockedAppBundleID = nil;
		currentTempUnlockTimer = nil;
	} repeats:NO];
}

%end

%hook SpringBoard
static BOOL openURLHasAuthenticated;

-(void)_openURLCore:(id)core display:(id)display animating:(BOOL)animating sender:(id)sender activationSettings:(id)settings withResult:(id)result {
	%orig;
	openURLHasAuthenticated = NO;
}

-(void)_applicationOpenURL:(id)url withApplication:(id)application sender:(id)sender publicURLsOnly:(BOOL)only animating:(BOOL)animating activationSettings:(id)settings withResult:(id)result {
	if ((![getProtectedApps() containsObject:[application bundleIdentifier]] && !shouldProtectAllApps()) || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || openURLHasAuthenticated) {
		%orig;
		return;
	}

	SBApplicationIcon *appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:application];
	SBIconView *iconView = [[%c(SBIconView) alloc] initWithDefaultSize];
	[iconView _setIcon:appIcon animated:YES];

	[[ASCommon sharedInstance] showAppAuthenticationAlertWithIconView:iconView customMessage:nil beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
			if (!wasCancelled) {
				// using %orig; crashes springboard, so this is my alternative.
				openURLHasAuthenticated = YES;
				[self applicationOpenURL:url];
			}
		}];
}

%end

%hook SBBannerContainerViewController
UIVisualEffectView *notificationBlurView;
PKGlyphView *bannerFingerGlyph;
BOOL currentBannerAuthenticated;

-(id)initWithNibName:(id)nibName bundle:(id)bundle {
	SBBannerContainerViewController *controller = %orig;
	RegisterForTouchIDNotifications(controller, @selector(receiveTouchIDNotification:));
	return controller;
}

-(void)loadView {
	%orig;

	currentBannerAuthenticated = NO;

	if ((![getProtectedApps() containsObject:[[self _bulletin] sectionID]] && !shouldProtectAllApps()) || [temporarilyUnlockedAppBundleID isEqual:[[self _bulletin] sectionID]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled)
		return;

	UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
	notificationBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	notificationBlurView.frame = self._bannerFrame;
	notificationBlurView.userInteractionEnabled = NO;
	[self.bannerContextView addSubview:notificationBlurView];

	SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:[[self _bulletin] sectionID]];
	SBApplicationIcon *appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:application];
	SBIconView *iconView = [[%c(SBIconView) alloc] initWithDefaultSize];
	[iconView _setIcon:appIcon animated:YES];
	UIImage *iconImage = [iconView.icon getIconImage:2];
	UIImageView *imgView = [[UIImageView alloc] initWithImage:iconImage];
	imgView.frame = CGRectMake(0,0,notificationBlurView.frame.size.height-20,notificationBlurView.frame.size.height-20);
	imgView.center = CGPointMake(imgView.frame.size.width/2+10,CGRectGetMidY(notificationBlurView.bounds));
	[notificationBlurView.contentView addSubview:imgView];

	NSString *displayName = [application displayName];
	UILabel *appNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	appNameLabel.textColor = [UIColor whiteColor];
	appNameLabel.text = displayName;
	[appNameLabel sizeToFit];
	appNameLabel.center = CGPointMake(10+imgView.frame.size.width+10+appNameLabel.frame.size.width/2,CGRectGetMidY(notificationBlurView.bounds));
	[notificationBlurView.contentView addSubview:appNameLabel];

	if (!bannerFingerGlyph) {
		bannerFingerGlyph = [[%c(PKGlyphView) alloc] initWithStyle:1];
		bannerFingerGlyph.secondaryColor = [UIColor grayColor];
		bannerFingerGlyph.primaryColor = [UIColor redColor];
	}
	CGRect fingerframe = bannerFingerGlyph.frame;
	fingerframe.size.height = notificationBlurView.frame.size.height-20;
	fingerframe.size.width = notificationBlurView.frame.size.height-20;
	bannerFingerGlyph.frame = fingerframe;
	bannerFingerGlyph.center = CGPointMake(notificationBlurView.bounds.size.width-fingerframe.size.height/2-10,CGRectGetMidY(notificationBlurView.bounds));
	[notificationBlurView.contentView addSubview:bannerFingerGlyph];
	[bannerFingerGlyph setState:0 animated:YES completionHandler:nil];

	[[BTTouchIDController sharedInstance] startMonitoring];
}

-(void)_handleBannerTapGesture:(id)gesture {
	if ((![getProtectedApps() containsObject:[[self _bulletin] sectionID]] && !shouldProtectAllApps()) || [temporarilyUnlockedAppBundleID isEqual:[[self _bulletin] sectionID]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || currentBannerAuthenticated)
		%orig;
}

-(void)viewDidDisappear:(BOOL)animated {
	if (bannerFingerGlyph) {
		[bannerFingerGlyph setState:0 animated:NO completionHandler:nil];
	}

	if (notificationBlurView) {
		[notificationBlurView removeFromSuperview];
		notificationBlurView = nil;
	}
	%orig;
}

-(void)setBannerPullDisplacement:(float)displacement {
	if ((![getProtectedApps() containsObject:[[self _bulletin] sectionID]] && !shouldProtectAllApps()) || [temporarilyUnlockedAppBundleID isEqual:[[self _bulletin] sectionID]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || currentBannerAuthenticated)
		%orig;
}

-(void)setBannerPullPercentage:(float)percentage {
	if ((![getProtectedApps() containsObject:[[self _bulletin] sectionID]] && !shouldProtectAllApps()) || [temporarilyUnlockedAppBundleID isEqual:[[self _bulletin] sectionID]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || currentBannerAuthenticated)
		%orig;
}

%new
-(void)receiveTouchIDNotification:(NSNotification *)notification
{
	if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.fingerdown"]) {
		if (bannerFingerGlyph)
			[bannerFingerGlyph setState:1 animated:YES completionHandler:nil];
	} else if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.fingerup"]) {
		if (bannerFingerGlyph)
			[bannerFingerGlyph setState:0 animated:YES completionHandler:nil];
	} else if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.authsuccess"]) {
		if (bannerFingerGlyph && notificationBlurView) {
			currentBannerAuthenticated = YES;
			[[BTTouchIDController sharedInstance] stopMonitoring];
			[UIView animateWithDuration:0.3f animations:^{
				[notificationBlurView setAlpha:0.0f];
			} completion:^(BOOL finished){
				if (finished)
					[bannerFingerGlyph setState:0 animated:NO completionHandler:nil];
			}];
		}
	} else if ([[notification name] isEqualToString:@"com.a3tweaks.asphaleia8.authfailed"]) {
		if (bannerFingerGlyph)
			[bannerFingerGlyph setState:0 animated:YES completionHandler:nil];
	}
}

%end

%hook SBBulletinModalController

-(void)observer:(id)observer addBulletin:(BBBulletin *)bulletin forFeed:(unsigned)feed {
	if ((![getProtectedApps() containsObject:[bulletin sectionID]] && !shouldProtectAllApps()) || [temporarilyUnlockedAppBundleID isEqual:[bulletin sectionID]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || currentBannerAuthenticated) {
		%orig;
		return;
	}

	SBApplication *application = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:[bulletin sectionID]];
	SBApplicationIcon *appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:application];
	SBIconView *iconView = [[%c(SBIconView) alloc] initWithDefaultSize];
	[iconView _setIcon:appIcon animated:YES];

	[[ASCommon sharedInstance] showAppAuthenticationAlertWithIconView:iconView customMessage:@"Scan fingerprint to show notification." beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
			if (!wasCancelled) {
				%orig;
			}
		}];
}

%end

@interface UIView ()
-(NSString*)recursiveDescription;
@end

%hook SBNotificationsClearButton

//-(BOOL)isBulletinSection !!!!!!
-(void)didMoveToSuperview {
	%orig;
	NSLog(@"[Asphaleia] %@",[[(UIView *)self superview] superview]);
}

%end

%ctor {
	addObserver(preferencesChangedCallback,kPrefsChangedNotification);
	loadPreferences();
	[[ASControlPanel sharedInstance] load];
	[[ASActivatorListener sharedInstance] loadWithEventHandler:^void(LAEvent *event, BOOL abortEventCalled){
		SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
		NSString *bundleID = frontmostApp.bundleIdentifier;

		if (!bundleID || !shouldUseDynamicSelection())
			return;

		NSNumber *appSecureValue = [NSNumber numberWithBool:![[[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey] objectForKey:bundleID] boolValue]];
		if (abortEventCalled)
			appSecureValue = [NSNumber numberWithBool:NO];

		[[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey] setObject:appSecureValue forKey:frontmostApp.bundleIdentifier];
		[[ASPreferencesHandler sharedInstance].prefs writeToFile:kPreferencesFilePath atomically:YES];

		NSString *title = nil;
		NSString *description = nil;
		if (![[[[ASPreferencesHandler sharedInstance].prefs objectForKey:kSecuredAppsKey] objectForKey:bundleID] boolValue]) {
			title = @"Disabled authentication";
			description = [NSString stringWithFormat:@"Disabled authentication for %@", frontmostApp.displayName];
		} else {
			title = @"Enabled authentication";
			description = [NSString stringWithFormat:@"Enabled authentication for %@", frontmostApp.displayName];
		}

		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
				   message:description
				  delegate:nil
		 cancelButtonTitle:@"Okay"
		 otherButtonTitles:nil];
		[alertView show];
	}];
}