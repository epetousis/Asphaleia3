/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
@protocol SBUIBiometricEventMonitorDelegate
@required
-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event;
@end

typedef void (^BTTouchIDEventBlock) (id monitor, unsigned event);

#define log(z) NSLog(@"[BioTesting] %@", z)

@interface SBUIBiometricEventMonitor : NSObject
- (void)addObserver:(id)arg1;
- (void)removeObserver:(id)arg1;
- (void)_startMatching;
- (void)_setMatchingEnabled:(BOOL)arg1;
- (BOOL)isMatchingEnabled;
@end

@interface BiometricKit : NSObject
+ (id)manager;
@end

#define TouchIDFingerDown  1
#define TouchIDFingerUp    0
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDNotMatched  10

@interface BTTouchIDController : NSObject <SBUIBiometricEventMonitorDelegate> {
	BOOL isMonitoring;
	BOOL previousMatchingSetting;
	id _monitorDelegate;
	NSArray *_monitorObservers;
}
@property BTTouchIDEventBlock biometricEventBlock;
+(id)sharedInstance;
-(void)startMonitoringWithEventBlock:(BTTouchIDEventBlock)block;
-(void)stopMonitoring;
@end
