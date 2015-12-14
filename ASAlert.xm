#import "ASAlert.h"
#import <SpringBoard/SBAlertItemsController.h>

#define titleWithSpacingForIcon(t) [NSString stringWithFormat:@"\n\n\n%@",t]
#define titleWithSpacingForSmallIcon(t) [NSString stringWithFormat:@"\n\n%@",t]

@interface ASAlert ()
@property (nonatomic) NSMutableArray *buttons;
@property (nonatomic) UIView *aboveTitleSubview;
-(NSArray *)allSubviewsOfView:(UIView *)view;
-(void)addSubviewToAlert:(UIView *)view;
@end

%subclass ASAlert : SBAlertItem

-(id)initWithTitle:(NSString *)title description:(NSString *)description delegate:(id<ASAlertDelegate>)delegate {
	if ((self = [self init])) {
		self.title = title;
		self.description = description;
		self.delegate = delegate;
		self.buttons = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)requirePasscode {
	%orig;
	self.alertSheet.title = self.title;
	self.alertSheet.message = self.description;

	for (NSString *button in self.buttons)
		[self.alertSheet addButtonWithTitle:button];

	if (self.aboveTitleSubview) {
		self.alertSheet.title = titleWithSpacingForSmallIcon(self.title);
		self.aboveTitleSubview.center = CGPointMake(270/2,32);
		dispatch_async(dispatch_get_main_queue(), ^{
			[self addSubviewToAlert:self.aboveTitleSubview];
		});
	}
}

- (void)alertView:(id)arg1 clickedButtonAtIndex:(int)arg2 {
	if (self.delegate)
		[self.delegate alertView:arg1 clickedButtonAtIndex:arg2];
}

- (BOOL)shouldShowInLockScreen {
	return NO;
}

%new
-(void)setAboveTitleSubview:(UIView *)view {
	self.aboveTitleSubview = view;
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
	if (self.delegate)
		[self.delegate willPresentAlertView:self];
	if (objc_getClass("SBAlertItemsController"))
		[[%c(SBAlertItemsController) sharedInstance] activateAlertItem:self];
}

%new
-(void)addButtonWithTitle:(NSString *)buttonTitle {
	if ([buttonTitle isKindOfClass:[NSString class]]) {
		[self.buttons addObject:buttonTitle];
	}
}

%new
-(void)removeButtonWithTitle:(NSString *)buttonTitle {
	if ([buttonTitle isKindOfClass:[NSString class]]) {
		[self.buttons removeObject:buttonTitle];
	}
}

%end