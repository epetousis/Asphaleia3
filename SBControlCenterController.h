@interface SBControlCenterController : NSObject
+(id)sharedInstance;
-(void)presentAnimated:(BOOL)animated;
-(void)presentAnimated:(BOOL)animated completion:(id)completion;
-(void)_presentWithDuration:(double)duration completion:(id)completion;
-(void)dismissAnimated:(BOOL)animated completion:(id)completion;
-(void)dismissAnimated:(BOOL)animated;
-(void)_revealSlidingViewToHeight:(float)height;
-(void)_finishPresenting:(BOOL)presenting completion:(id)completion;
-(void)_updateRevealPercentage:(float)percentage;
@end