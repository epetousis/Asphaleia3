#import <UIKit/UIKit.h>
#import "PKGlyphView.h"
#import "ASTouchIDController.h"
#import "ASCommon.h"
#import "PreferencesHandler.h"
#import "substrate.h"
#import "UIImage+ImageEffects.h"
#import <AudioToolbox/AudioServices.h>
#import "ASActivatorListener.h"
#import "ASControlPanel.h"
#import "NSTimer+Blocks.h"
#import "ASPasscodeHandler.h"
#import "ASTouchWindow.h"
#import "Asphaleia.h"
#import <RocketBootstrap/RocketBootstrap.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "ASXPCHandler.h"

#define kBundlePath @"/Library/Application Support/Asphaleia/AsphaleiaAssets.bundle"

#define asphaleiaLog() NSLog(@"[Asphaleia] Method called: %@",NSStringFromSelector(_cmd))

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

SBAppSwitcherIconController *iconController;
NSTimer *currentTempUnlockTimer;
NSTimer *currentTempGlobalDisableTimer;
SBBannerContainerViewController *controller;
CPDistributedMessagingCenter *centre;

void RegisterForTouchIDNotifications(id observer, SEL selector) {
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"com.a3tweaks.asphaleia8.fingerdown" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"com.a3tweaks.asphaleia8.fingerup" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"com.a3tweaks.asphaleia8.authsuccess" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"com.a3tweaks.asphaleia8.authfailed" object:nil];
}

void DeregisterForTouchIDNotifications(id observer) {
	[[NSNotificationCenter defaultCenter] removeObserver:observer];
}

@interface ASCommon ()
-(BOOL)authenticateAppWithIconView:(SBIconView *)iconView authenticatedHandler:(ASCommonAuthenticationHandler)handler;
@end

%hook SBIconController

-(void)iconTapped:(SBIconView *)iconView {
	BOOL isProtected = [[ASCommon sharedInstance] authenticateAppWithIconView:iconView authenticatedHandler:^void(BOOL wasCancelled){
		if (!wasCancelled) {
			if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.3")) {
				[iconView.icon launchFromLocation:iconView.location context:nil];
			} else {
				[iconView.icon launchFromLocation:iconView.location];
			}
		}
	}];
	if (!isProtected)
		%orig;
}

-(void)iconHandleLongPress:(SBIconView *)iconView {
	if (self.isEditing || !shouldSecureAppArrangement()) {
		%orig;
		return;
	}

	[iconView setHighlighted:NO];
	[iconView cancelLongPressTimer];
	[iconView setTouchDownInIcon:NO];
	
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertAppArranging dismissedHandler:^(BOOL wasCancelled) {
		if (!wasCancelled)
			[self setIsEditing:YES];
		}];
}

%new
-(void)asphaleia_resetAsphaleiaIconView {
	if ([ASCommon sharedInstance].fingerglyph && [ASCommon sharedInstance].currentHSIconView) {
		[[ASCommon sharedInstance].currentHSIconView _updateLabel];

		[UIView animateWithDuration:0.3f animations:^{
			[ASCommon sharedInstance].fingerglyph.transform = CGAffineTransformMakeScale(0.01,0.01);
		}];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[[ASCommon sharedInstance].currentHSIconView setHighlighted:NO];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia8.stopmonitoring"), NULL, NULL, YES);

			[[ASCommon sharedInstance].fingerglyph removeFromSuperview];
			[ASCommon sharedInstance].fingerglyph.transform = CGAffineTransformMakeScale(1,1);
			[[ASCommon sharedInstance].fingerglyph setState:0 animated:YES completionHandler:nil];

			[[ASCommon sharedInstance].currentHSIconView _updateLabel];

			[ASCommon sharedInstance].currentHSIconView = nil;
			[[ASCommon sharedInstance].anywhereTouchWindow setHidden:YES];
		});
	}
}

%end

%hook SBIconView

%new
-(void)asphaleia_updateLabelWithText:(NSString *)text {
	SBIconLabelView *iconLabelView = MSHookIvar<SBIconLabelView *>(self,"_labelView");

	SBIconLabelImageParameters *imageParameters = [[iconLabelView imageParameters] mutableCopy];
	[imageParameters setText:text];
	[%c(SBIconLabelView) updateIconLabelView:iconLabelView withSettings:nil imageParameters:imageParameters];
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
	if ((![getProtectedApps() containsObject:self.displayItem.displayIdentifier] && !shouldProtectAllApps()) || !shouldObscureAppContent() || [[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:self.displayItem.displayIdentifier])
		%orig;
}

- (void)_layoutContainer {
	%orig;
	if ((![getProtectedApps() containsObject:self.displayItem.displayIdentifier] && !shouldProtectAllApps()) || !shouldObscureAppContent() || [[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:self.displayItem.displayIdentifier]) {
		return;
	}

	SBAppSwitcherSnapshotView *snapshot = self;
	CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
	[filter setValue:@10 forKey:@"inputRadius"];
	UIImageView *snapshotImageView = MSHookIvar<UIImageView *>(snapshot,"_snapshotImageView");
	snapshotImageView.layer.filters = [NSArray arrayWithObject:filter];

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

	[self addSubview:obscurityView];
}

%end

%hook SBUIController
BOOL switcherAuthenticating;

-(void)_toggleSwitcher {
	asphaleiaLog();
	if (!shouldSecureSwitcher()) {
		%orig;
		return;
	}
	if (!switcherAuthenticating) {
		switcherAuthenticating = YES;
		[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertSwitcher dismissedHandler:^(BOOL wasCancelled) {
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

%end

%hook SBLockScreenManager
UIWindow *blurredWindow;

-(void)_lockUI {
	[ASXPCHandler sharedInstance].slideUpControllerActive = NO;
	[[ASTouchIDController sharedInstance] stopMonitoring];
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
	if (([getProtectedApps() containsObject:[frontmostApp bundleIdentifier]] || shouldProtectAllApps()) && !shouldUnsecurelyUnlockIntoApp() && frontmostApp && ![[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:[frontmostApp bundleIdentifier]]) {
		blurredWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		blurredWindow.backgroundColor = [UIColor clearColor];

		UIVisualEffect *blurEffect;
		blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];

		UIVisualEffectView *visualEffectView;
		visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

		visualEffectView.frame = [[UIScreen mainScreen] bounds];

		blurredWindow.windowLevel = UIWindowLevelAlert-1;
		[blurredWindow addSubview:visualEffectView];
		[blurredWindow makeKeyAndVisible];
	}
}

- (void)unlockUIFromSource:(int)source withOptions:(id)options {
	if (source != 14 || ![[ASTouchIDController sharedInstance] shouldBlockLockscreenMonitor] || ![[ASTouchIDController sharedInstance] isMonitoring])
		%orig;
}

%end

%hook SBLockScreenViewController

-(void)viewDidDisappear:(BOOL)animated {
	%orig;
	
	SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
	if (([getProtectedApps() containsObject:[frontmostApp bundleIdentifier]] || shouldProtectAllApps()) && !shouldUnsecurelyUnlockIntoApp() && frontmostApp && ![[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:[frontmostApp bundleIdentifier]] && ![ASCommon sharedInstance].catchAllIgnoreRequest) {

		[[ASCommon sharedInstance] authenticateAppWithDisplayIdentifier:[frontmostApp bundleIdentifier] customMessage:nil dismissedHandler:^(BOOL wasCancelled) { // If you want to set beginMesaMonitoringBeforeShowing to yes, implement the home button click disabling code
			if (blurredWindow) {
				blurredWindow.hidden = YES;
				blurredWindow = nil;
			}

			if (wasCancelled) {
				[[%c(SBUIController) sharedInstanceIfExists] clickedMenuButton];
			}
		}];
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
		[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertSpotlight dismissedHandler:^(BOOL wasCancelled) {
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

	[[ASTouchIDController sharedInstance] setShouldBlockLockscreenMonitor:YES];
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertPowerDown dismissedHandler:^(BOOL wasCancelled) {
	[[ASTouchIDController sharedInstance] setShouldBlockLockscreenMonitor:NO];
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
	[[ASTouchIDController sharedInstance] setShouldBlockLockscreenMonitor:YES];
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertControlCentre dismissedHandler:^(BOOL wasCancelled) {
	controlCentreAuthenticating = NO;
	[[ASTouchIDController sharedInstance] setShouldBlockLockscreenMonitor:NO];
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
	[[ASTouchIDController sharedInstance] setShouldBlockLockscreenMonitor:YES];
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertControlCentre dismissedHandler:^(BOOL wasCancelled) {
	controlCentreAuthenticating = NO;
	[[ASTouchIDController sharedInstance] setShouldBlockLockscreenMonitor:NO];
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

	[ASCommon sharedInstance].temporarilyUnlockedAppBundleID = [self bundleIdentifier];
	currentTempUnlockTimer = [NSTimer scheduledTimerWithTimeInterval:appExitUnlockTimeInterval() block:^{
		[ASCommon sharedInstance].temporarilyUnlockedAppBundleID = nil;
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
	asphaleiaLog();
	if ((![getProtectedApps() containsObject:[application bundleIdentifier]] && !shouldProtectAllApps()) || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || openURLHasAuthenticated || [[ASCommon sharedInstance].appUserAuthorisedID isEqualToString:[application bundleIdentifier]]) {
		%orig;
		return;
	}

	[ASCommon sharedInstance].catchAllIgnoreRequest = YES;
	if ([[settings description] containsString:@"fromLocked = BSSettingFlagYes"]) {
		SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
		if (shouldUnsecurelyUnlockIntoApp() && [getProtectedApps() containsObject:[frontmostApp bundleIdentifier]])
			return;
	}

	[[ASCommon sharedInstance] authenticateAppWithDisplayIdentifier:[application bundleIdentifier] customMessage:nil dismissedHandler:^(BOOL wasCancelled) {
			if (!wasCancelled) {
				if (blurredWindow && [[settings description] containsString:@"fromLocked = BSSettingFlagYes"]) {
					blurredWindow.hidden = YES;
					blurredWindow = nil;
				}
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
	controller = %orig;
	RegisterForTouchIDNotifications(controller, @selector(receiveTouchIDNotification:));
	return controller;
}

-(void)loadView {
	%orig;

	currentBannerAuthenticated = NO;

	if ((![getProtectedApps() containsObject:[[self _bulletin] sectionID]] && !shouldProtectAllApps()) || [[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:[[self _bulletin] sectionID]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || !shouldObscureNotifications())
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

	if (!touchIDEnabled()) {
		UILabel *authPassLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		authPassLabel.text = @"Tap to show";
		[authPassLabel sizeToFit];
		authPassLabel.center = notificationBlurView.contentView.center;
		CGRect frame = authPassLabel.frame;
		frame.origin.x = notificationBlurView.frame.size.width - frame.size.width - 10;
		authPassLabel.frame = frame;
		authPassLabel.textColor = [UIColor whiteColor];
		[notificationBlurView.contentView addSubview:authPassLabel];
		return;
	}

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

	[[ASTouchIDController sharedInstance] startMonitoring];
}

-(void)_handleBannerTapGesture:(id)gesture {
	if ((![getProtectedApps() containsObject:[[self _bulletin] sectionID]] && !shouldProtectAllApps()) || [[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:[[self _bulletin] sectionID]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || currentBannerAuthenticated || !shouldObscureNotifications()) {
		%orig;
	} else {
		[[ASTouchIDController sharedInstance] stopMonitoring];
		[[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:nil eventBlock:^void(BOOL authenticated){
			if (authenticated) {
				if (notificationBlurView) {
					currentBannerAuthenticated = YES;
					[ASCommon sharedInstance].appUserAuthorisedID = [[self _bulletin] sectionID];
					[UIView animateWithDuration:0.3f animations:^{
						[notificationBlurView setAlpha:0.0f];
					} completion:^(BOOL finished){
						if (finished && bannerFingerGlyph)
							[bannerFingerGlyph setState:0 animated:NO completionHandler:nil];
					}];
				}
			} else {
				if ([[%c(SBBannerController) sharedInstance] isShowingBanner] && touchIDEnabled())
					[[ASTouchIDController sharedInstance] startMonitoring];
			}
		}];
	}
}

-(void)viewDidDisappear:(BOOL)animated {
	%orig;
	currentBannerAuthenticated = NO;
	[ASCommon sharedInstance].appUserAuthorisedID = nil;

	if (![[%c(SBBannerController) sharedInstance] isShowingBanner]) {
		[[ASTouchIDController sharedInstance] stopMonitoring];
	}

	if (bannerFingerGlyph) {
		[bannerFingerGlyph setState:0 animated:NO completionHandler:nil];
	}

	if (notificationBlurView) {
		[notificationBlurView removeFromSuperview];
		notificationBlurView = nil;
	}
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
			[ASCommon sharedInstance].appUserAuthorisedID = [[self _bulletin] sectionID];
			[[ASTouchIDController sharedInstance] stopMonitoring];
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

%hook SBBannerController

- (BOOL)gestureRecognizerShouldBegin:(id)gestureRecognizer {
	if ((![getProtectedApps() containsObject:[[controller _bulletin] sectionID]] && !shouldProtectAllApps()) || [[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:[[controller _bulletin] sectionID]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || currentBannerAuthenticated || !shouldObscureNotifications())
		return %orig;
	else
		return NO;
}

%end

%hook SBBulletinModalController

-(void)observer:(id)observer addBulletin:(BBBulletin *)bulletin forFeed:(unsigned)feed {
	if ((![getProtectedApps() containsObject:[bulletin sectionID]] && !shouldProtectAllApps()) || [[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:[bulletin sectionID]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || currentBannerAuthenticated || !shouldObscureNotifications()) {
		%orig;
		return;
	}

	[[ASCommon sharedInstance] authenticateAppWithDisplayIdentifier:[bulletin sectionID] customMessage:@"Scan fingerprint to show notification." dismissedHandler:^(BOOL wasCancelled) {
			if (!wasCancelled) {
				%orig;
			}
		}];
}

%end

%hook SBWorkspace

-(void)setCurrentTransaction:(id)transaction {
	asphaleiaLog();
	if (![transaction isKindOfClass:[%c(SBAppToAppWorkspaceTransaction) class]]) {
		%orig;
		return;
	}

	SBApplication *application = MSHookIvar<SBApplication *>(transaction, "_toApp");
	if ((![getProtectedApps() containsObject:[application bundleIdentifier]] && !shouldProtectAllApps()) ||
		[[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:[application bundleIdentifier]] ||
		[ASPreferencesHandler sharedInstance].asphaleiaDisabled ||
		[ASPreferencesHandler sharedInstance].appSecurityDisabled ||
		[[ASCommon sharedInstance].appUserAuthorisedID isEqualToString:[application bundleIdentifier]] ||
		[ASCommon sharedInstance].catchAllIgnoreRequest ||
		![application bundleIdentifier]) {

		[ASCommon sharedInstance].appUserAuthorisedID = nil;
		[ASCommon sharedInstance].catchAllIgnoreRequest = NO;
		%orig;
		return;
	}

	[ASCommon sharedInstance].appUserAuthorisedID = nil;

	SBApplicationIcon *appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:application];
	SBIconView *iconView = [[%c(SBIconView) alloc] initWithDefaultSize];
	[iconView _setIcon:appIcon animated:YES];

	[[ASCommon sharedInstance] authenticateAppWithDisplayIdentifier:application.bundleIdentifier customMessage:nil dismissedHandler:^(BOOL wasCancelled) {
			[ASCommon sharedInstance].appUserAuthorisedID = nil;
			if (!wasCancelled) {
				%orig;
			}
		}];
}

%end

%hook SBUIBiometricEventMonitor

- (void)_setMatchingEnabled:(BOOL)arg1 {
	BOOL deviceLocked = MSHookIvar<BOOL>(self, "_deviceLocked");
	BOOL screenOff = MSHookIvar<BOOL>(self, "_screenIsOff");
	if (!arg1 && !deviceLocked && !screenOff)
		return;
	else
		%orig;
}

- (void)removeObserver:(id)arg1 {
	NSHashTable *currentObservers = MSHookIvar<NSHashTable*>(self, "_observers");
	if ([[ASTouchIDController sharedInstance] isMonitoring] && [currentObservers containsObject:[ASTouchIDController sharedInstance]])
		[[[ASTouchIDController sharedInstance] oldObservers] removeObject:arg1];
	else
		%orig;
}

%end

%hook SBLockScreenSlideUpToAppController

- (void)beginPresentationWithTouchLocation:(CGPoint)touchLocation {
	%orig;
	[ASXPCHandler sharedInstance].slideUpControllerActive = YES;
}

- (void)_activateApp:(id)app withAppInfo:(id)appInfo andURL:(id)url animated:(BOOL)animated {
	if ((![getProtectedApps() containsObject:[app bundleIdentifier]] && !shouldProtectAllApps()) || [[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:[app bundleIdentifier]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled) {
		%orig;
		return;
	}

	[[ASTouchIDController sharedInstance] setShouldBlockLockscreenMonitor:YES];
	[[ASCommon sharedInstance] authenticateAppWithDisplayIdentifier:[app bundleIdentifier] customMessage:nil dismissedHandler:^(BOOL wasCancelled) {
			[[ASTouchIDController sharedInstance] setShouldBlockLockscreenMonitor:NO];
			if (!wasCancelled) {
				[ASCommon sharedInstance].catchAllIgnoreRequest = YES;
				%orig;
			} else {
				[self _finishSlideDownWithCompletion:nil];
			}
		}];
}

- (void)_handleAppLaunchedUnderLockScreenWithResult:(int)result {
	SBApplication *app = MSHookIvar<SBApplication *>(self, "_targetApp");
	if ((![getProtectedApps() containsObject:[app bundleIdentifier]] && !shouldProtectAllApps()) || [[ASCommon sharedInstance].temporarilyUnlockedAppBundleID isEqual:[app bundleIdentifier]] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled) {
		%orig;
	}
}

%end

%ctor {
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
	centre = [CPDistributedMessagingCenter centerNamed:@"com.a3tweaks.asphaleia2.xpc"];
	rocketbootstrap_distributedmessagingcenter_apply(centre);
	[centre runServerOnCurrentThread];
	[centre registerForMessageName:@"com.a3tweaks.asphaleia2.xpc/CheckSlideUpControllerActive" target:[ASXPCHandler sharedInstance] selector:@selector(handleMessageNamed:withUserInfo:)];
}