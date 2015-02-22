#import "ASActivatorListener.h"
#import <objc/runtime.h>
#import <dlfcn.h>

@implementation ASActivatorListener

+(instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedInstance = [self new];
        dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
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
    if (self.eventHandler)
        [self.eventHandler release];
    self.eventHandler = [handler copy];
    if (objc_getClass("LAActivator")) {
        if ([[objc_getClass("LAActivator") sharedInstance] isRunningInsideSpringBoard])
            [[objc_getClass("LAActivator") sharedInstance] registerListener:self forName:@"Dynamic Selection"];
    }
}

-(void)load {
    if (objc_getClass("LAActivator")) {
        if ([[objc_getClass("LAActivator") sharedInstance] isRunningInsideSpringBoard] && self.eventHandler)
            [[objc_getClass("LAActivator") sharedInstance] registerListener:self forName:@"Dynamic Selection"];
    }
}

- (void)unload {
    if (objc_getClass("LAActivator")) {
        if ([[objc_getClass("LAActivator") sharedInstance] isRunningInsideSpringBoard])
            [[objc_getClass("LAActivator") sharedInstance] unregisterListenerWithName:@"Dynamic Selection"];
    }
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