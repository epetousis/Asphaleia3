#import "ASActivatorListener.h"

@implementation ASActivatorListener

+(instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}
 
-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    ASActivatorListenerEventHandler eventHandler = self.eventHandler;

    if (eventHandler)
        eventHandler(event, NO);
 
    [event setHandled:YES];
}
 
-(void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
    ASActivatorListenerEventHandler eventHandler = self.eventHandler;

    if (eventHandler)
        eventHandler(event, YES);
}
 
- (void)loadWithEventHandler:(ASActivatorListenerEventHandler)handler {
    self.eventHandler = [handler copy];
    if ([LASharedActivator isRunningInsideSpringBoard])
        [LASharedActivator registerListener:self forName:@"Dynamic Selection"];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"Asphaleia";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    return @"Dynamic Selection";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    return @"Toggle security for current app";
}

- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"application", nil];
}
 
@end