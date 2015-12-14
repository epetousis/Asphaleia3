#import <SpringBoardUI/SBAlertItem.h>
#import "ASAlert.h"

@interface ASAuthenticationAlert : SBAlertItem
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *message;
@property (nonatomic, weak) id<ASAlertDelegate> delegate;
@property(nonatomic) NSInteger tag;
@property (nonatomic) UIView *icon;
@property BOOL useSmallIcon;
-(id)initWithTitle:(NSString *)title message:(NSString *)message icon:(UIView *)icon smallIcon:(BOOL)useSmallIcon delegate:(id<ASAlertDelegate>)delegate;
-(id)alertController;
-(void)show;

@end