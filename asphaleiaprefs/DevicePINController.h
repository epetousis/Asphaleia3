/*
* This header is generated by classdump-dyld 0.7
* on Friday, November 7, 2014 at 1:48:07 AM Eastern European Standard Time
* Operating System: Version 8.1 (Build 12B411)
* Image Source: /System/Library/PrivateFrameworks/Preferences.framework/Preferences
* classdump-dyld is licensed under GPLv3, Copyright © 2013 by Elias Limneos.
*/

#import <Preferences/PSDetailController.h>
#import "DevicePINControllerDelegate.h"

@class NSString, UIBarButtonItem;

@interface DevicePINController : PSDetailController {

	int _mode;
	int _substate;
	NSString* _oldPassword;
	NSString* _lastEntry;
	BOOL _success;
	id _pinDelegate;
	UIBarButtonItem* _cancelButton;
	UIBarButtonItem* _nextButton;
	UIBarButtonItem* _doneButton;
	NSString* _error1;
	NSString* _error2;
	BOOL _hidesNavigationButtons;

}

@property (assign,nonatomic) id<DevicePINControllerDelegate> pinDelegate;              //@synthesize pinDelegate=_pinDelegate - In the implementation block
@property (assign,nonatomic) BOOL hidesNavigationButtons;                              //@synthesize hidesNavigationButtons=_hidesNavigationButtons - In the implementation block
+(BOOL)settingEnabled;
-(BOOL)isBlocked;
-(BOOL)success;
-(void)setSpecifier:(id)arg1 ;
-(void)dealloc;
-(id)init;
-(id)title;
-(void)suspend;
-(void)viewWillLayoutSubviews;
-(void)loadView;
-(void)viewWillAppear:(BOOL)arg1 ;
-(void)viewDidAppear:(BOOL)arg1 ;
-(void)viewWillDisappear:(BOOL)arg1 ;
-(void)setMode:(int)arg1 ;
-(int)mode;
-(void)_dismiss;
-(void)setPane:(id)arg1 ;
-(void)setLastEntry:(id)arg1 ;
-(void)willUnlock;
-(BOOL)requiresKeyboard;
-(BOOL)useProgressiveDelays;
-(CFStringRef)defaultsID;
-(void)_updateUI;
-(CGSize)overallContentSizeForViewInPopover;
-(BOOL)validatePIN:(id)arg1 ;
-(BOOL)isNumericPIN;
-(int)_getScreenType;
-(CFStringRef)failedAttemptsKey;
-(CFStringRef)blockTimeIntervalKey;
-(CFStringRef)blockedStateKey;
-(double)unblockTime;
-(void)_clearBlockedState;
-(long long)numberOfFailedAttempts;
-(void)_setNumberOfFailedAttempts:(long long)arg1 ;
-(void)_setUnblockTime:(double)arg1 ;
-(id)stringsBundle;
-(id)stringsTable;
-(void)_showFailedAttempts;
-(void)_updateErrorTextAndFailureCount:(BOOL)arg1 ;
-(void)cancelButtonTapped;
-(BOOL)simplePIN;
-(BOOL)showSimplePINCancelButtonOnLeft;
-(void)adjustButtonsForPasswordLength:(unsigned long long)arg1 ;
-(void)_updatePINButtons;
-(BOOL)pinIsAcceptable:(id)arg1 outError:(id*)arg2 ;
-(void)_slidePasscodeField;
-(void)_showUnacceptablePINError:(id)arg1 password:(id)arg2 ;
-(BOOL)completedInputIsValid:(id)arg1 ;
-(void)performActionAfterPINSet;
-(id<DevicePINControllerDelegate>)pinDelegate;
-(BOOL)_asyncSetPinCompatible;
-(void)setPIN:(id)arg1 completion:(/*^block*/id)arg2 ;
-(void)setPIN:(id)arg1 ;
-(void)_showPINConfirmationError;
-(BOOL)attemptValidationWithPIN:(id)arg1 ;
-(void)setOldPassword:(id)arg1 ;
-(void)performActionAfterPINRemove;
-(void)performActionAfterPINEntry;
-(int)pinLength;
-(void)pinEntered:(id)arg1 ;
-(id)pinInstructionsPrompt;
-(id)pinInstructionsPromptFont;
-(void)setPinDelegate:(id<DevicePINControllerDelegate>)arg1 ;
-(BOOL)hidesNavigationButtons;
-(void)setHidesNavigationButtons:(BOOL)arg1 ;
-(void)setSuccess:(BOOL)arg1 ;
@end

