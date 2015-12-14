#import "ASAuthenticationAlert.h"
#import <SpringBoard/SBAlertItemsController.h>

#define titleWithSpacingForIcon(t) [NSString stringWithFormat:@"\n\n\n%@",t]
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

@interface ASAuthenticationAlert ()
-(NSArray *)allSubviewsOfView:(UIView *)view;
-(void)addSubviewToAlert:(UIView *)view;
@end

%subclass ASAuthenticationAlert : ASAlert

-(id)initWithTitle:(NSString *)title description:(NSString *)description icon:(UIView *)icon smallIcon:(BOOL)useSmallIcon delegate:(id<ASAlertDelegate>)delegate {
	if ((self = [self initWithTitle:title description:description delegate:delegate])) {
		self.icon = icon;
		self.useSmallIcon = useSmallIcon;
	}
	return self;
}

- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode {
	%orig;
	if (self.useSmallIcon) {
		self.alertSheet.title = titleWithSpacingForSmallIcon(self.title);
		self.icon.center = CGPointMake(270/2,32);
	} else {
		self.alertSheet.title = titleWithSpacingForIcon(self.title);
		self.icon.center = CGPointMake(270/2,41);
	}
	[self.alertSheet addButtonWithTitle:@"Cancel"];
	[self.alertSheet addButtonWithTitle:@"Passcode"];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self addSubviewToAlert:self.icon];
	});
}

%end