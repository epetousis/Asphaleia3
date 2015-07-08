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
#import <substrate.h>

@interface BTTouchIDController ()
@property (readwrite) BOOL isMonitoring;
@end

@interface SBScreenFlash
+(id)mainScreenFlasher;
-(void)flashWhiteWithCompletion:(id)completion;
@end

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
	//[[objc_getClass("SBScreenFlash") mainScreenFlasher] flashWhiteWithCompletion:nil];
	switch(event) {
		case TouchIDFingerDown:
			asphaleiaLogMsg(@"Finger down");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.fingerdown" object:self];
			break;
		case TouchIDFingerUp:
			asphaleiaLogMsg(@"Finger up");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.fingerup" object:self];
			break;
		case TouchIDFingerHeld:
			asphaleiaLogMsg(@"Finger held");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.fingerheld" object:self];
			break;
		case TouchIDMatched:
			asphaleiaLogMsg(@"Finger matched");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.authsuccess" object:self];
			[self stopMonitoring];
			break;
		case TouchIDNotMatched:
			asphaleiaLogMsg(@"Authentication failed");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.authfailed" object:self];
			if ([[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] boolValue] : NO)
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			break;
		case 10: // For the new iPhone
			asphaleiaLogMsg(@"Authentication failed");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.a3tweaks.asphaleia8.authfailed" object:self];
			if ([[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] ? [[[ASPreferencesHandler sharedInstance].prefs objectForKey:kVibrateOnFailKey] boolValue] : NO)
				AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			break;
	}
}

-(void)startMonitoring {
	// If already monitoring, don't start again
	if(self.isMonitoring) {
		return;
	}
	self.isMonitoring = YES;

	// Get current monitor instance so observer can be added
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	// Save current device matching state
	previousMatchingSetting = [monitor isMatchingEnabled];

	id activator = [objc_getClass("LAActivator") sharedInstance];
	if (activator)
    {
		id event = [objc_getClass("LAEvent") eventWithName:@"libactivator.fingerprint-sensor.press.single" mode:@"application"]; // LAEventNameFingerprintSensorPressSingle
		if (event)
        {
			activatorListenerNames = [activator assignedListenerNamesForEvent:event];
			if (activatorListenerNames)
				for (NSString *listenerName in activatorListenerNames)
					[activator removeListenerAssignment:listenerName fromEvent:event];
		}
	}

	oldObservers = [MSHookIvar<NSHashTable*>(monitor, "_observers") copy];
	for (id observer in oldObservers)
		[monitor removeObserver:observer];

	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	Class la = objc_getClass("LASharedActivator");
	if (la) {
		if ([(LAActivator *)objc_getClass("LASharedActivator") hasListenerWithName:@"Dynamic Selection"])
			[[ASActivatorListener sharedInstance] unload];
		
		if ([(LAActivator *)objc_getClass("LASharedActivator") hasListenerWithName:@"Control Panel"])
			[[ASControlPanel sharedInstance] unload];
	}

	// Begin listening :D
	[monitor addObserver:self];
	[monitor _setMatchingEnabled:YES];
	[monitor _startMatching];

	asphaleiaLogMsg(@"Touch ID monitoring began");
}

-(void)stopMonitoring {
	// If already stopped, don't stop again
	if(!self.isMonitoring) {
		return;
	}
	self.isMonitoring = NO;

	// Get current monitor instance so observer can be removed
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	
	// Stop listening
	NSHashTable *observers = MSHookIvar<NSHashTable*>(monitor, "_observers");
	if (observers && [observers containsObject:self])
		[monitor removeObserver:self];
	if (oldObservers && observers)
		for (id observer in oldObservers)
			[monitor addObserver:observer];
	oldObservers = nil;
	[monitor _setMatchingEnabled:previousMatchingSetting];

	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	Class la = objc_getClass("LASharedActivator");
	if (la) {
		if (![(LAActivator *)objc_getClass("LASharedActivator") hasListenerWithName:@"Dynamic Selection"])
			[[ASActivatorListener sharedInstance] load];
	
		if (![(LAActivator *)objc_getClass("LASharedActivator") hasListenerWithName:@"Control Panel"])
			[[ASControlPanel sharedInstance] load];
	}

	id activator = [objc_getClass("LAActivator") sharedInstance];
    if (activator && activatorListenerNames)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
           id event = [objc_getClass("LAEvent") eventWithName:@"libactivator.fingerprint-sensor.press.single" mode:@"application"]; // LAEventNameFingerprintSensorPressSingle
           if (event)
               for (NSString *listenerName in activatorListenerNames)
                   [activator addListenerAssignment:listenerName toEvent:event];
        });
    }

	asphaleiaLogMsg(@"Touch ID monitoring ended");
}

@end
