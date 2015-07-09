/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
#import "Asphaleia.h"
@class BTTouchIDController;
@protocol SBUIBiometricEventMonitorDelegate
@required
-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event;
@end

typedef void (^BTTouchIDEventBlock) (BTTouchIDController *controller, id monitor, unsigned event);

#define asphaleiaLogMsg(str) HBLogInfo(@"[Asphaleia] %@",str)

@interface SBUIBiometricEventMonitor : NSObject
- (void)addObserver:(id)arg1;
- (void)removeObserver:(id)arg1;
- (void)_startMatching;
- (void)_setMatchingEnabled:(BOOL)arg1;
- (BOOL)isMatchingEnabled;
@end

#define TouchIDFingerDown  1
#define TouchIDFingerUp    0
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDMaybeMatched 4
#define TouchIDNotMatched  9

@interface BTTouchIDController : NSObject <SBUIBiometricEventMonitorDelegate> {
	BOOL previousMatchingSetting;
	NSArray *activatorListenerNames;
}
@property (nonatomic, strong) BTTouchIDEventBlock biometricEventBlock;
@property (readonly) BOOL isMonitoring;
@property (readonly) NSHashTable *oldObservers;
+(instancetype)sharedInstance;
-(void)startMonitoring;
-(void)stopMonitoring;
@end
