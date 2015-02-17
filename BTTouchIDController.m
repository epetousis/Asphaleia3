/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
#import "BTTouchIDController.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "ASActivatorListener.h"
#import "ASControlPanel.h"
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
	if(self.isMonitoring) {
		return;
	}
	self.isMonitoring = YES;

	// Get current monitor instance so observer can be added
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	// Save current device matching state
	previousMatchingSetting = [monitor isMatchingEnabled];

	_monitorObservers = [[[monitor valueForKey:@"_observers"] allObjects] copy];
	for (int i=0; i<_monitorObservers.count; i++)
	{
		[monitor removeObserver:[_monitorObservers objectAtIndex:i]];
	}

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
	if(!self.isMonitoring) {
		return;
	}
	self.isMonitoring = NO;

	// Get current monitor instance so observer can be removed
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	
	// Stop listening
	[monitor removeObserver:self];

	for (id observer in _monitorObservers)
	{
		[monitor addObserver:observer];
	}

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
	BTTouchIDEventBlock eventBlock = self.biometricEventBlock;
    
    if (eventBlock) {
        eventBlock(self, monitor, event);
    }
}

-(void)dealloc {
	[self stopMonitoring];

	[super dealloc];
}

@end
