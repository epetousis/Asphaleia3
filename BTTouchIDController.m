/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
#import "BTTouchIDController.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

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

-(void)startMonitoringWithEventBlock:(BTTouchIDEventBlock)block {
	// If already monitoring, don't start again
	if(isMonitoring) {
		return;
	}
	isMonitoring = YES;

	// Get current monitor instance so observer can be added
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	// Save current device matching state
	previousMatchingSetting = [monitor isMatchingEnabled];

	_monitorObservers = [[[monitor valueForKey:@"_observers"] allObjects] copy];
	for (int i=0; i<_monitorObservers.count; i++)
	{
		[monitor removeObserver:[_monitorObservers objectAtIndex:i]];
	}

	self.biometricEventBlock = block;

	// Begin listening :D
	[monitor addObserver:self];
	[monitor _setMatchingEnabled:YES];
	[monitor _startMatching];

	log(@"Started monitoring");
}

-(void)stopMonitoring {
	// If already stopped, don't stop again
	if(!isMonitoring) {
		return;
	}
	isMonitoring = NO;

	// Get current monitor instance so observer can be removed
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	
	// Stop listening
	[monitor removeObserver:self];

	for (id observer in _monitorObservers)
	{
		[monitor addObserver:observer];
	}

	[monitor _setMatchingEnabled:previousMatchingSetting];

	log(@"Stopped Monitoring");
}

-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event {
	BTTouchIDEventBlock eventBlock = self.biometricEventBlock;
    
    if (eventBlock) {
        eventBlock(monitor, event);
    }
}

@end
