#import "ASAuthenticationAlert.h"
#import "ASAuthenticationController.h"
#import "ASPreferences.h"
#import <SpringBoard/SBAlertItemsController.h>

#define titleWithSpacingForIcon(t) [NSString stringWithFormat:@"\n\n\n%@",t]
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"%@",t]

@interface ASAuthenticationAlert ()
-(NSArray *)allSubviewsOfView:(UIView *)view;
-(void)addSubviewToAlert:(UIView *)view;
@end

%subclass ASAuthenticationAlert : SBAlertItem

%new
-(id)initWithTitle:(NSString *)title message:(NSString *)message icon:(UIView *)icon smallIcon:(BOOL)useSmallIcon delegate:(id<ASAlertDelegate>)delegate {
	if ((self = [self init])) {
		self.title = title;
		self.message = message;
		self.delegate = delegate;
		self.icon = icon;
		self.useSmallIcon = useSmallIcon;
	}
	return self;
}

- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode {
	%orig;
	if (self.useSmallIcon) {
		self.alertSheet.title = titleWithSpacingForSmallIcon(self.title);
		self.icon.center = CGPointMake(270/2,34);
	} else {
		self.alertSheet.title = titleWithSpacingForIcon(self.title);
		self.icon.center = CGPointMake(270/2,41);
	}
	self.alertSheet.message = self.message;
	[self.alertSheet addButtonWithTitle:@"Cancel"];
	[self.alertSheet addButtonWithTitle:@"Passcode"];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self addSubviewToAlert:self.icon];
	});
}

- (void)alertView:(id)arg1 clickedButtonAtIndex:(int)arg2 {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.stopmonitoring"), NULL, NULL, YES);
    [[ASAuthenticationController sharedInstance] setCurrentAuthAlert:nil];
	if (self.delegate)
		[self.delegate alertView:arg1 clickedButtonAtIndex:arg2];

	[self dismiss];
}

- (BOOL)shouldShowInLockScreen {
	return NO;
}

%new
-(void)addSubviewToAlert:(UIView *)view {
    UIView *labelSuperview;
    for (id subview in [self allSubviewsOfView:[[self alertController] view]]){
        if ([subview isKindOfClass:[UILabel class]]) {
            labelSuperview = [subview superview];
        }
    }
    if ([labelSuperview respondsToSelector:@selector(addSubview:)]) {
        [labelSuperview addSubview:view];
    }
}

%new
- (NSArray *)allSubviewsOfView:(UIView *)view
{
    NSMutableArray *viewArray = [[NSMutableArray alloc] init];
    [viewArray addObject:view];
    for (UIView *subview in view.subviews)
    {
        [viewArray addObjectsFromArray:(NSArray *)[self allSubviewsOfView:subview]];
    }
    return [NSArray arrayWithArray:viewArray];
}

%new
-(void)show {
	if ([[ASAuthenticationController sharedInstance] currentAuthAlert])
        [[[ASAuthenticationController sharedInstance] currentAuthAlert] dismiss];

    [[ASAuthenticationController sharedInstance] setCurrentAuthAlert:self];

    if ([[ASPreferences sharedInstance] touchIDEnabled])
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia.startmonitoring"), NULL, NULL, YES);

	if (objc_getClass("SBAlertItemsController"))
		[[%c(SBAlertItemsController) sharedInstance] activateAlertItem:self];
}

// Properties
%new
-(void)setTitle:(NSString *)title {
	objc_setAssociatedObject(self, @selector(title), title, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
-(NSString *)title {
	return objc_getAssociatedObject(self, @selector(title));
}

%new
-(void)setMessage:(NSString *)message {
	objc_setAssociatedObject(self, @selector(message), message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
-(NSString *)message {
	return objc_getAssociatedObject(self, @selector(message));
}

%new
-(void)setDelegate:(id<ASAlertDelegate>)delegate {
	objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
-(id<ASAlertDelegate>)delegate {
	return objc_getAssociatedObject(self, @selector(delegate));
}

%new
-(void)setTag:(NSInteger)tag {
	objc_setAssociatedObject(self, @selector(tag), [NSNumber numberWithInt:tag], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
-(NSInteger)tag {
	return [objc_getAssociatedObject(self, @selector(tag)) intValue];
}

%new
-(void)setIcon:(UIView *)icon {
	objc_setAssociatedObject(self, @selector(icon), icon, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
-(UIView *)icon {
	return objc_getAssociatedObject(self, @selector(icon));
}

%new
-(void)setUseSmallIcon:(BOOL)useSmallIcon {
	objc_setAssociatedObject(self, @selector(useSmallIcon), [NSNumber numberWithBool:useSmallIcon], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
-(BOOL)useSmallIcon {
	return [objc_getAssociatedObject(self, @selector(useSmallIcon)) boolValue];
}

%end