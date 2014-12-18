@interface SBControlCenterController : NSObject
+(id)sharedInstance;
-(void)_endPresentation;
-(void)_beginPresentation;
-(void)presentAnimated:(BOOL)animated;
-(void)presentAnimated:(BOOL)animated completion:(id)completion;
-(void)_presentWithDuration:(double)duration completion:(id)completion;
-(void)dismissAnimated:(BOOL)animated completion:(id)completion;
-(void)dismissAnimated:(BOOL)animated;
-(void)_revealSlidingViewToHeight:(float)height;
-(void)_finishPresenting:(BOOL)presenting completion:(id)completion;
-(void)_updateRevealPercentage:(float)percentage;
-(void)cancelTransition;
-(void)abortAnimatedTransition;
@end