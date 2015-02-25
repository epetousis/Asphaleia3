#import "SBIcon.h"

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
-(void)updateLabelWithText:(NSString *)text;
@end