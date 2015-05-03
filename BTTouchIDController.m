/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
#import "BTTouchIDController.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ASActivatorListener.h"
#import "ASControlPanel.h"
#import <libactivator/libactivator.h>
#import <dlfcn.h>

@interface BTTouchIDController ()
@property (readwrite) BOOL isMonitoring;
@end

@implementation BTTouchIDController

/*+(BTTouchIDController *)sharedInstance {
	// Setup instance for current class once
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	// Provide instance
	return sharedInstance;
}*/

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

	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	Class la = objc_getClass("LASharedActivator");
	if (la) {
		if ([objc_getClass("LASharedActivator") hasListenerWithName:@"Dynamic Selection"])
			[[ASActivatorListener sharedInstance] unload];
		
		if ([objc_getClass("LASharedActivator") hasListenerWithName:@"Control Panel"])
			[[ASControlPanel sharedInstance] unload];
	}

	log(@"Started monitoring");
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

	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	Class la = objc_getClass("LASharedActivator");
	if (la) {
		if (![objc_getClass("LASharedActivator") hasListenerWithName:@"Dynamic Selection"])
			[[ASActivatorListener sharedInstance] load];
	
		if (![objc_getClass("LASharedActivator") hasListenerWithName:@"Control Panel"])
			[[ASControlPanel sharedInstance] load];
	}

	log(@"Stopped Monitoring");
}

-(BTTouchIDController *)initWithEventBlock:(BTTouchIDEventBlock)block {
	self = [super init];
    if(self) {
        self.biometricEventBlock = [block copy]; // very important that you _copy_ the block, otherwise you will cause a crash!
    }
    return self;
}

-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event {
    if (self.biometricEventBlock) {
        self.biometricEventBlock(self, monitor, event);
    }
}

@end
