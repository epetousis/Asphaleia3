#import <SpringBoardUI/SBAlertItem.h>

@class ASAlert;

@protocol ASAlertDelegate <NSObject>
- (void)alertView:(ASAlert *)alertView clickedButtonAtIndex:(NSInteger)index;
@optional
- (void)willPresentAlertView:(ASAlert *)alertView;
@end

@interface ASAlert : SBAlertItem
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *description;
@property (nonatomic, weak) id<ASAlertDelegate> delegate;
@property(nonatomic) NSInteger tag;
-(id)initWithTitle:(NSString *)title description:(NSString *)description delegate:(id<ASAlertDelegate>)delegate;
-(id)alertController;
-(void)addButtonWithTitle:(NSString *)buttonTitle;
-(void)removeButtonWithTitle:(NSString *)buttonTitle;
-(void)setAboveTitleSubview:(UIView *)view;
-(void)show;

@end