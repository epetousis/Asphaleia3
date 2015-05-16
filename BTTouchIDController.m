/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
#import "BTTouchIDController.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ASActivatorListener.h"
#import "ASControlPanel.h"
#import <libactivator/libactivator.h>
#import <dlfcn.h>
#import <AudioToolbox/AudioServices.h>
#import "PreferencesHandler.h"

@interface BTTouchIDController ()
@property (readwrite) BOOL isMonitoring;
@end

#define Log(str) NSLog(@"[Asphaleia] %@",str)

@implementation BTTouchIDController

+(id)sharedInstance {
	// Setup instance for current class once
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	// Provide instance
	return sharedInstance;
}

-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event {
	switch(event) {
		case TouchIDFingerDown:
			Log(@"Finger down");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.fingerdown" object:self];
			break;
		case TouchIDFingerUp:
			Log(@"Finger up");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.fingerup" object:self];
			break;
		case TouchIDFingerHeld:
			Log(@"Finger held");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.fingerheld" object:self];
			break;
		case TouchIDMatched:
			Log(@"Finger matched");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.authsuccess" object:self];
			[self stopMonitoring];
			break;
		case TouchIDNotMatched:
			Log(@"Authentication failed");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.authfailed" object:self];
			if ([[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] boolValue] : NO)
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			break;
		case 10: // For the new iPhone
			Log(@"Authentication failed");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.authfailed" object:self];
			if ([[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] boolValue] : NO)
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			break;
	}
}

-(void)startMonitoring {
	// If already monitoring, don't start again
	if(_isMonitoring) {
		return;
	}
	_isMonitoring = YES;

	// Get current monitor instance so observer can be added
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	// Save current device matching state
	previousMatchingSetting = [monitor isMatchingEnabled];

	// Begin listening :D
	[monitor addObserver:self];
	[monitor _setMatchingEnabled:YES];
	[monitor _startMatching];

	Log(@"Touch ID monitoring began");
}

-(void)stopMonitoring {
	// If already stopped, don't stop again
	if(!_isMonitoring) {
		return;
	}
	_isMonitoring = NO;

	// Get current monitor instance so observer can be removed
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	
	// Stop listening
	[monitor removeObserver:self];
	[monitor _setMatchingEnabled:previousMatchingSetting];

	Log(@"Touch ID monitoring ended");
}

@end
