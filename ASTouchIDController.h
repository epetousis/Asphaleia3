/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
#import "Asphaleia.h"
@class ASTouchIDController;
@protocol SBUIBiometricEventMonitorDelegate
@required
-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event;
@end

typedef void (^BTTouchIDEventBlock) (ASTouchIDController *controller, id monitor, unsigned event);

#define asphaleiaLogMsg(str) NSLog(@"[Asphaleia] %@",str)

@interface SBUIBiometricEventMonitor : NSObject
- (void)addObserver:(id)arg1;
- (void)removeObserver:(id)arg1;
- (void)_startMatching;
- (void)_setMatchingEnabled:(BOOL)arg1;
- (BOOL)isMatchingEnabled;
-(BOOL)hasEnrolledIdentities;
@end

#define TouchIDFingerDown  1
#define TouchIDFingerUp    0
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDMaybeMatched 4
#define TouchIDNotMatched  9

@interface ASTouchIDController : NSObject <SBUIBiometricEventMonitorDelegate> {
	BOOL starting;
	BOOL stopping;
	BOOL previousMatchingSetting;
	NSArray *activatorListenerNames;
	NSArray *activatorListenerNamesSpringBoard;
	NSArray *activatorListenerNamesLS;
}
@property (nonatomic, strong) BTTouchIDEventBlock biometricEventBlock;
@property (readonly) BOOL isMonitoring;
@property (readonly) NSHashTable *oldObservers;
@property (readonly) id lastMatchedFingerprint;
@property BOOL shouldBlockLockscreenMonitor;
+(instancetype)sharedInstance;
-(void)startMonitoring;
-(void)stopMonitoring;
@end
