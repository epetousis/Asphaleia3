#import <UIKit/UIKit.h>
#import "Asphaleia.h"
#import "PKGlyphView.h"
#import "ASTouchIDController.h"
#import "ASTouchWindow.h"
#import "ASCommon.h"

@interface UIAlertView ()
-(id)_alertController;
@end

@interface ASAuthenticationController : NSObject <UIAlertViewDelegate> {
	ASCommonAuthenticationHandler authHandler;
	NSString *currentAuthAppBundleID;
}
@property UIAlertView *currentAuthAlert;
@property SBIconView *currentHSIconView;
@property PKGlyphView *fingerglyph;
@property NSString *appUserAuthorisedID;
@property BOOL catchAllIgnoreRequest;
@property NSString *temporarilyUnlockedAppBundleID;
@property ASTouchWindow *anywhereTouchWindow;
+(instancetype)sharedInstance;
-(UIAlertView *)returnAppAuthenticationAlertWithIconView:(SBIconView *)iconView customMessage:(NSString *)customMessage delegate:(id<UIAlertViewDelegate>)delegate;
-(UIAlertView *)returnAuthenticationAlertOfType:(ASAuthenticationAlertType)alertType delegate:(id<UIAlertViewDelegate>)delegate;
-(BOOL)authenticateAppWithDisplayIdentifier:(NSString *)appIdentifier customMessage:(NSString *)customMessage dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(BOOL)authenticateFunction:(ASAuthenticationAlertType)alertType dismissedHandler:(ASCommonAuthenticationHandler)handler;
-(BOOL)authenticateAppWithIconView:(SBIconView *)iconView authenticatedHandler:(ASCommonAuthenticationHandler)handler;
-(void)dismissAnyAuthenticationAlerts;
-(void)addSubview:(UIView *)view toAlertView:(UIAlertView *)alertView;
- (NSArray *)allSubviewsOfView:(UIView *)view;

@end