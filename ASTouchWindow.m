#import "ASTouchWindow.h"

@implementation ASTouchWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!CGRectContainsPoint(self.viewToAllowTouchIn.frame, point)) {
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

-(void)blockTouchesAllowingTouchInView:(UIView *)touchView touchBlockedHandler:(ASTouchWindowTouchBlockedEvent)handler {
    self.viewToAllowTouchIn = touchView;
    self.handler = [handler copy];
    [self makeKeyAndVisible];
}

@end