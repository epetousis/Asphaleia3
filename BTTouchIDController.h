/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
@protocol SBUIBiometricEventMonitorDelegate
@required
-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event;
@end

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

@interface BTTouchIDController : NSObject {
	BOOL isMonitoring;
	BOOL previousMatchingSetting;
	id _monitorDelegate;
	NSArray *_monitorObservers;
}
+(id)sharedInstance;
-(void)startMonitoring:(id)object;
-(void)stopMonitoring:(id)object;
@end
