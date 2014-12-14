#import "SBDisplayItem.h"
@interface SBAppSwitcherSnapshotView : UIView
@property(retain, nonatomic) UIImage* deferredUpdateImage;
@property(readonly, copy, nonatomic) SBDisplayItem* displayItem;
@end