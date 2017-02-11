/* Modified from Sassoty's code
https://github.com/Sassoty/BioTesting */
#import "Asphaleia.h"
@class ASTouchIDController;
@protocol SBUIBiometricResource
@required
- (void)biometricKitInterface:(id)arg1 handleEvent:(unsigned)arg2;
@end

typedef void (^BTTouchIDEventBlock) (ASTouchIDController *controller, id monitor, unsigned event);

#define asphaleiaLogMsg(str) NSLog(@"[Asphaleia] %@",str)

@interface SBUIBiometricResource : NSObject
+ (id)sharedInstance;
- (void)addObserver:(id)arg1;
- (void)removeObserver:(id)arg1;
- (void)_startMatching;
- (BOOL)isMatchingEnabled;
- (BOOL)hasEnrolledFingers;
@end

#define TouchIDFingerDown  1
#define TouchIDFingerUp    0
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDMaybeMatched 4
#define TouchIDNotMatched  9

@interface ASTouchIDController : NSObject <SBUIBiometricResource> {
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
+ (instancetype)sharedInstance;
- (void)startMonitoring;
- (void)stopMonitoring;
@end
