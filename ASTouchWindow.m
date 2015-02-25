#import "ASTouchWindow.h"

@implementation ASTouchWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect frame = self.viewToAllowTouchIn.frame;
    if (self.viewToAllowTouchIn.isInDock) {
        frame = CGRectMake(frame.origin.x,[UIScreen mainScreen].bounds.size.height-self.viewToAllowTouchIn.superview.frame.size.height+frame.origin.y,frame.size.width,frame.size.height);
    }
    if (!CGRectContainsPoint(frame, point)) {
        self.handler(self, YES);
        return YES;
    }
    return NO;
}

- (id)initWithFrame:(CGRect)aRect {
    self = [super initWithFrame:aRect];
    if (self) {
        self.windowLevel = UIWindowLevelAlert;
        [self setHidden:NO];
        [self setAlpha:1.0];
        [self setBackgroundColor:[UIColor clearColor]];
    }
    
    return self;
}

-(void)blockTouchesAllowingTouchInView:(SBIconView *)touchView touchBlockedHandler:(ASTouchWindowTouchBlockedEvent)handler {
    self.viewToAllowTouchIn = touchView;
    self.handler = [handler copy];
    [self makeKeyAndVisible];
}

@end