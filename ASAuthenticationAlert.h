#import <SpringBoardUI/SBAlertItem.h>
#import "ASAlert.h"

@interface ASAuthenticationAlert : ASAlert
@property (nonatomic) UIView *icon;
@property BOOL useSmallIcon;
@property(nonatomic) NSInteger tag;
-(id)initWithTitle:(NSString *)title description:(NSString *)description icon:(UIView *)icon smallIcon:(BOOL)useSmallIcon delegate:(id<ASAlertDelegate>)delegate;
-(id)alertController;
-(void)show;

@end