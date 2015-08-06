#import <Flipswitch/Flipswitch.h>
%hook FSSwitchMainPanel

- (void)setState:(int)state forSwitchIdentifier:(NSString *)switchIdentifier {
	return;
}

%end

%ctor {
	dlopen("/Library/MobileSubstrate/DynamicLibraries/Flipswitch.dylib", RTLD_NOW);
}