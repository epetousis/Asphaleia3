#import <UIKit/UIKit.h>
#import "PKGlyphView.h"
#import "BTTouchIDController.h"
#import "ASCommon.h"
#import "SBIconView.h"
#import "SBIcon.h"
#import "SBIconController.h"

#define TouchIDFingerDown  1
#define TouchIDFingerUp    0
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDNotMatched  10 

#define kAsphaleiaSettingsNotification @"com.a3tweaks.asphaleia/ReloadPrefs"

PKGlyphView *fingerglyph;
UIView *containerView;
SBIconView *currentIconView;

%hook SBIconController

-(void)iconTapped:(SBIconView *)iconView {
	if (fingerglyph && currentIconView && containerView) {
		if ([@[@"com.apple.Maps"] containsObject:iconView.icon.applicationBundleID])
			[iconView.icon launchFromLocation:iconView.location];

		[currentIconView setHighlighted:NO];
		[iconView setHighlighted:NO];
		[fingerglyph removeFromSuperview];
		[containerView removeFromSuperview];
		fingerglyph = nil;
		currentIconView = nil;
		containerView = nil;
		[[BTTouchIDController sharedInstance] stopMonitoring:self];
		return;
	} else if ([@[@"com.apple.Maps"] containsObject:iconView.icon.applicationBundleID]) {
		[iconView setHighlighted:NO];
		[iconView.icon launchFromLocation:iconView.location];
		return;
	}

	currentIconView = iconView;
	fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:1];
	fingerglyph.secondaryColor = [UIColor redColor];
	fingerglyph.primaryColor = [UIColor whiteColor];
	CGRect fingerframe = fingerglyph.frame;
	fingerframe.size.height = [iconView _iconImageView].frame.size.height-10;
	fingerframe.size.width = [iconView _iconImageView].frame.size.width-10;
	fingerglyph.frame = fingerframe;
	containerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,fingerframe.size.width,fingerframe.size.height)];
	containerView.center = [iconView _iconImageView].center;
	[containerView addSubview:fingerglyph];
	[iconView addSubview:containerView];
	//[iconView bringSubviewToFront:containerView];

	fingerglyph.transform = CGAffineTransformMakeScale(0.01,0.01);
	[UIView animateWithDuration:0.3f animations:^{
		fingerglyph.transform = CGAffineTransformMakeScale(1,1);
	}];

	[[BTTouchIDController sharedInstance] startMonitoring:self];
}

%new
-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event {
	switch (event) {
		case TouchIDMatched:
			if (fingerglyph && currentIconView && containerView) {
				[currentIconView.icon launchFromLocation:currentIconView.location];
				[currentIconView setHighlighted:NO];
				[fingerglyph removeFromSuperview];
				[containerView removeFromSuperview];
				fingerglyph = nil;
				currentIconView = nil;
				containerView = nil;
				[[BTTouchIDController sharedInstance] stopMonitoring:self];
			}
			break;
		case TouchIDFingerDown:
			[fingerglyph setState:1 animated:YES completionHandler:nil];
			break;
		case TouchIDFingerUp:
			[fingerglyph setState:0 animated:YES completionHandler:nil];
			break;
		case TouchIDNotMatched:
			[fingerglyph setState:0 animated:YES completionHandler:nil];
			break;
	}
}

// editing hook
-(void)iconHandleLongPress:(SBIconView *)iconView {
	if (self.isEditing) {
		%orig;
		return;
	}
	UIAlertView *test = [[ASCommon sharedInstance] createAppAuthenticationAlertWithIcon:nil];
	[test show];

	[iconView setHighlighted:NO];
	[iconView cancelLongPressTimer];
	[iconView setTouchDownInIcon:NO];
	//[self setIsEditing:YES];
}

%end