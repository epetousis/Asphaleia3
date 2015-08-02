#import <UIKit/UIKit.h>

@interface BBBulletin : NSObject
-(NSString *)sectionID;
-(id)modalAlertContent;
@end

@interface SBDisplayItem : NSObject
@property (nonatomic,readonly) NSString * displayIdentifier;
@end

@interface CAFilter : NSObject
+(CAFilter*)filterWithName:(NSString*)name;
@end

@interface SBAppSwitcherIconController : NSObject
@property(copy, nonatomic) NSArray* displayLayouts;
@end

@interface SBAppSwitcherSnapshotView : UIView
@property(retain, nonatomic) UIImage* deferredUpdateImage;
@property(readonly, copy, nonatomic) SBDisplayItem* displayItem;
@end

@interface SBApplication : NSObject
-(id)bundleIdentifier;
-(NSString*)displayName;
-(NSString*)longDisplayName;
@end

@interface SBApplicationController : NSObject
-(id)sharedInstance;
-(id)applicationWithBundleIdentifier:(NSString*)bundleID;
@end

@interface SBApplicationIcon : NSObject
-(id)initWithApplication:(id)application;
@end

@interface SBBannerContainerViewController : UIViewController
@property(readonly, assign, nonatomic) UIView* bannerContextView;
-(CGRect)_bannerFrameForOrientation:(int)orientation;
-(CGRect)_bannerFrame;
-(BBBulletin *)_bulletin;
@end

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

@interface SBDisplayLayout : NSObject
@property (nonatomic,readonly) long long layoutSize;
@property (nonatomic,readonly) NSArray * displayItems;
-(NSArray *)displayItems;
@end

@interface SBIcon : NSObject
// 8.4+
-(NSString *)displayNameForLocation:(int)location;
// 8.3+
-(void)launchFromLocation:(int)location context:(id)context;
// 8.1 and lower
-(void)launchFromLocation:(int)location;
-(NSString *)displayName;
// All
- (BOOL)isFolderIcon;
- (BOOL)isApplicationIcon;
-(NSString *)applicationBundleID;
-(void)setBadge:(id)badge;
-(id)getIconImage:(int)image;
- (BOOL)isDownloadingIcon;
@end

@interface SBIconController : NSObject
+(id)sharedInstance;
-(BOOL)isEditing;
-(void)setIsEditing:(BOOL)editing;
// Custom method
-(void)asphaleia_resetAsphaleiaIconView;
@end

@interface SBIconLabelImageParameters : NSObject <NSCopying, NSMutableCopying>
@property(readonly, copy, nonatomic) NSString* text;
-(id)mutableCopyWithZone:(NSZone*)zone;
-(id)copyWithZone:(NSZone*)zone;
-(void)setText:(NSString *)text;
-(void)dealloc;
-(id)initWithParameters:(id)parameters;
-(id)init;
@end

@interface SBIconLabelView : UIView {
	SBIconLabelImageParameters* _imageParameters;
}
@property(retain, nonatomic) SBIconLabelImageParameters* imageParameters;
+(void)updateIconLabelView:(id)view withSettings:(id)settings imageParameters:(id)parameters;
+(id)newIconLabelViewWithSettings:(id)settings imageParameters:(id)parameters;
-(void)_checkInImages;
-(void)dealloc;
@end

@interface SBIconImageView : UIImageView
@property(assign, nonatomic) float overlayAlpha;
@end

@interface SBIconView : UIView
@property(assign, nonatomic) int location;
@property(retain, nonatomic) SBIcon* icon;
@property(assign, nonatomic) BOOL isEditing;
-(void)setIsGrabbed:(BOOL)grabbed;
-(void)setHighlighted:(BOOL)highlighted;
-(void)setAllowJitter:(BOOL)jitter;
-(BOOL)isHighlighted;
-(void)cancelLongPressTimer;
-(void)setIconImageAndAccessoryAlpha:(float)alpha;
-(SBIconImageView *)_iconImageView;
-(void)setTouchDownInIcon:(BOOL)icon;
-(BOOL)isTouchDownInIcon;
-(void)cancelLongPressTimer;
-(id)initWithDefaultSize;
-(void)_setIcon:(id)icon animated:(BOOL)animated;
-(void)setLabelAccessoryViewHidden:(BOOL)hidden;
-(void)setLabelHidden:(BOOL)hidden;
-(void)_updateLabel;
-(BOOL)isInDock;
// New method
-(void)asphaleia_updateLabelWithText:(NSString *)text;
@end

@interface SBSearchViewController : UIViewController
+(SBSearchViewController *)sharedInstance;
-(void)cancelButtonPressed;
-(void)_setShowingKeyboard:(BOOL)keyboard;
-(void)dismiss;
@end

@interface SBUIController : NSObject
+(id)sharedInstanceIfExists;
+(id)sharedInstance;
-(BOOL)isAppSwitcherShowing;
-(BOOL)clickedMenuButton;
@end

@interface SpringBoard : NSObject
-(void)_revealSpotlight;
-(SBApplication *)_accessibilityFrontMostApplication;
-(void)_applicationOpenURL:(id)url withApplication:(id)application sender:(id)sender publicURLsOnly:(BOOL)only animating:(BOOL)animating activationSettings:(id)settings withResult:(id)result;
-(BOOL)_requestPermissionToOpenURL:(id)openURL withApplication:(id)application sender:(id)sender;
-(void)applicationOpenURL:(id)url;
@end

@interface SBBannerController : NSObject
+(id)sharedInstance;
-(BOOL)isShowingBanner;
@end

@interface BiometricKit : NSObject
+(id)manager;
-(NSDictionary *)identities:(id)object;
@end

@interface SBLockScreenManager : NSObject
@property(readonly, assign) BOOL isUILocked;
@property(assign, nonatomic, getter=isUIUnlocking) BOOL UIUnlocking;
+(id)sharedInstance;
@end

@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
@end

@interface SBLockScreenSlideUpToAppController : NSObject
- (void)_finishSlideDownWithCompletion:(id)completion;
@end

// Auxo LE
@interface AuxoCardView : UIView
@property(readonly, nonatomic) NSString *displayIdentifier;
@end

@interface AuxoCollectionViewCell : NSObject
@property(readonly, nonatomic) AuxoCardView *cardView;
@end

@interface AuxoCollectionView : UICollectionView
- (void)activateApplicationWithDisplayIdentifier:(NSString *)arg1 fromCell:(AuxoCollectionViewCell *)arg2;
@end