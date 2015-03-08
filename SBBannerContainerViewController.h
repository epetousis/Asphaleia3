@interface BBBulletin : NSObject
-(NSString *)sectionID;
@end

@interface SBBannerContainerViewController : UIViewController
@property(readonly, assign, nonatomic) UIView* bannerContextView;
-(CGRect)_bannerFrameForOrientation:(int)orientation;
-(CGRect)_bannerFrame;
-(BBBulletin *)_bulletin;
@end