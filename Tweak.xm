#import <UIKit/UIKit.h>
#import <UIKit/UIApplication2.h>
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

PKGlyphView *fingerglyph;
SBIconView *currentIconView;
SBAppSwitcherIconController *iconController;
BTTouchIDController *iconTouchIDController;
NSString *temporarilyUnlockedAppBundleID;
NSTimer *currentTempUnlockTimer;
NSTimer *currentTempGlobalDisableTimer;
ASTouchWindow *anywhereTouchWindow;

%hook SBIconController

-(void)iconTapped:(SBIconView *)iconView {
	if ([ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled) {
		[[%c(SBIconController) sharedInstance] resetAsphaleiaIconView];
		%orig;
		return;
	}

	if (fingerglyph && currentIconView) {
		[iconView setHighlighted:NO];
		if ([iconView isEqual:currentIconView]) {
			[[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
				if (authenticated)
					[iconView.icon launchFromLocation:iconView.location];
			}];
		}
		[[%c(SBIconController) sharedInstance] resetAsphaleiaIconView];

		return;
	} else if ((![getProtectedApps() containsObject:iconView.icon.applicationBundleID] || [temporarilyUnlockedAppBundleID isEqual:iconView.icon.applicationBundleID]) && !shouldProtectAllApps()) {
		%orig;
		return;
	} else if (!touchIDEnabled() && passcodeEnabled()) {
		[[ASPasscodeHandler sharedInstance] showInKeyWindowWithPasscode:getPasscode() iconView:iconView eventBlock:^void(BOOL authenticated){
			[iconView setHighlighted:NO];

			if (authenticated)
			%orig;
		}];
		return;
	}

	anywhereTouchWindow = [[ASTouchWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

	currentIconView = iconView;
	fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:1];
	fingerglyph.secondaryColor = [UIColor grayColor];
	fingerglyph.primaryColor = [UIColor redColor];
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

	iconTouchIDController = [[BTTouchIDController alloc] initWithEventBlock:^void(BTTouchIDController *controller, id monitor, unsigned event) {
		switch (event) {
		case TouchIDMatched:
			if (fingerglyph && currentIconView) {
				[currentIconView.icon launchFromLocation:currentIconView.location];
				[[%c(SBIconController) sharedInstance] resetAsphaleiaIconView];
			}
			break;
		case TouchIDFingerDown:
			[fingerglyph setState:1 animated:YES completionHandler:nil];

			[currentIconView updateLabelWithText:@"Scanning..."];

			break;
		case TouchIDFingerUp:
			[fingerglyph setState:0 animated:YES completionHandler:nil];
			break;
		case TouchIDNotMatched:
			[fingerglyph setState:0 animated:YES completionHandler:nil];

			[currentIconView updateLabelWithText:@"Scan finger..."];

			if (shouldVibrateOnIncorrectFingerprint())
					AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			break;
		}
	}];
	[iconTouchIDController startMonitoring];

	[currentIconView updateLabelWithText:@"Scan finger..."];

	[anywhereTouchWindow blockTouchesAllowingTouchInView:currentIconView touchBlockedHandler:^void(ASTouchWindow *touchWindow, BOOL blockedTouch){
		if (blockedTouch) {
			[[%c(SBIconController) sharedInstance] resetAsphaleiaIconView];
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
-(void)resetAsphaleiaIconView {
	if (fingerglyph && currentIconView) {
		[currentIconView _updateLabel];

		[UIView animateWithDuration:0.3f animations:^{
			fingerglyph.transform = CGAffineTransformMakeScale(0.01,0.01);
		}];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[currentIconView setHighlighted:NO];
			[fingerglyph removeFromSuperview];
			[iconTouchIDController stopMonitoring];
			//[fingerglyph release];

			currentIconView = nil;
			//[iconTouchIDController release];
			if (anywhereTouchWindow) {
				[anywhereTouchWindow setHidden:YES];
				//[anywhereTouchWindow release];
			}
		});
	}
}

%end

%hook SBIconView

%new
-(void)updateLabelWithText:(NSString *)text {
	SBIconLabelView *iconLabelView = [self valueForKey:@"_labelView"];

	SBIconLabelImageParameters *imageParameters = [[iconLabelView imageParameters] mutableCopy];
	[imageParameters setText:text];
	[%c(SBIconLabelView) updateIconLabelView:iconLabelView withSettings:nil imageParameters:imageParameters];
}

%end

%hook SBAppSwitcherController

-(void)_askDelegateToDismissToDisplayLayout:(SBDisplayLayout *)displayLayout displayIDsToURLs:(id)urls displayIDsToActions:(id)actions {
	SBDisplayItem *item = [displayLayout.displayItems objectAtIndex:0];
	NSMutableDictionary *iconViews = [iconController valueForKey:@"_iconViews"];

	SBApplication *frontmostApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];

	if (![getProtectedApps() containsObject:item.displayIdentifier] || [temporarilyUnlockedAppBundleID isEqual:item.displayIdentifier] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled || [item.displayIdentifier isEqual:[frontmostApp bundleIdentifier]]) {
		%orig;
		return;
	}

	[[ASCommon sharedInstance] showAppAuthenticationAlertWithIconView:[iconViews objectForKey:displayLayout] beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
	if (!wasCancelled)
		%orig;
	}];
}

%end

%hook SBAppSwitcherIconController

-(void)dealloc {
	iconController = nil;
	%orig;
}

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

-(void)layoutSubviews {
	%orig;
	if ((![getProtectedApps() containsObject:self.displayItem.displayIdentifier] && !shouldProtectAllApps()) || !shouldObscureAppContent() || [temporarilyUnlockedAppBundleID isEqual:self.displayItem.displayIdentifier] || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled) {
		return;
	}
	
	for (UIView *view in [[ASCommon sharedInstance] allSubviewsOfView:self]) {
		if (view.tag == 80085)
			return;
	}

	CAFilter* filter = [CAFilter filterWithName:@"gaussianBlur"];
	[filter setValue:[NSNumber numberWithFloat:15] forKey:@"inputRadius"];
	[filter setValue:[NSNumber numberWithBool:YES] forKey:@"inputHardEdges"];
	UIImageView *snapshotImageView = [self valueForKey:@"_snapshotImageView"];
	snapshotImageView.layer.filters = [NSArray arrayWithObject:filter];
	[self setValue:snapshotImageView forKey:@"_snapshotImageView"];

	UIView *obscurityView = [[ASCommon sharedInstance] obscurityViewWithSnapshotView:self];
	obscurityView.tag = 80085; // ;)
	[self addSubview:obscurityView];
}

-(void)dealloc {
	for (UIView *view in [[ASCommon sharedInstance] allSubviewsOfView:self]) {
		if (view.tag == 80085) {
			[view removeFromSuperview];
			[view release];
		}
	}
	%orig;
}

%end

%hook SBUIController

-(BOOL)_activateAppSwitcher {
	if (!shouldSecureSwitcher()) {
		return %orig;
	}

	[[ASCommon sharedInstance] showAuthenticationAlertOfType:ASAuthenticationAlertSwitcher beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
		if (!wasCancelled)
			%orig;
		}];
	return NO;
}

%end

%hook SBLockScreenManager

-(void)_lockUI {
	[[%c(SBIconController) sharedInstance] resetAsphaleiaIconView];
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
		[[ASCommon sharedInstance] showAppAuthenticationAlertWithIconView:iconView beginMesaMonitoringBeforeShowing:NO dismissedHandler:^(BOOL wasCancelled) {
			blurredWindow.hidden = YES;
			[blurredWindow release];

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
		[temporarilyUnlockedAppBundleID release];
		[currentTempUnlockTimer release];
	} repeats:NO];
}

%end

%hook SpringBoard
static BOOL openURLHasAuthenticated;

-(void)_applicationOpenURL:(id)url withApplication:(id)application sender:(id)sender publicURLsOnly:(BOOL)only animating:(BOOL)animating activationSettings:(id)settings withResult:(id)result {
	%orig;
	openURLHasAuthenticated = NO;
}

-(void)applicationOpenURL:(id)url withApplication:(id)application sender:(id)sender publicURLsOnly:(BOOL)only animating:(BOOL)animating needsPermission:(BOOL)permission activationSettings:(id)settings withResult:(id)result {
	if ((![getProtectedApps() containsObject:[application bundleIdentifier]] && !shouldProtectAllApps()) || [ASPreferencesHandler sharedInstance].asphaleiaDisabled || [ASPreferencesHandler sharedInstance].appSecurityDisabled) {
		%orig;
		return;
	}

	SBApplicationIcon *appIcon = [[%c(SBApplicationIcon) alloc] initWithApplication:application];
	SBIconView *iconView = [[%c(SBIconView) alloc] initWithDefaultSize];
	[iconView _setIcon:appIcon animated:YES];

	[[ASCommon sharedInstance] showAppAuthenticationAlertWithIconView:iconView beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
			if (!wasCancelled) {
				// using %orig; crashes springboard, so this is my alternative.
				openURLHasAuthenticated = YES;
				[self applicationOpenURL:url];
			}
		}];
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
		return;
	}];
}