#import <Flipswitch/Flipswitch.h>
#import "../ASCommon.h"
#import "../PreferencesHandler.h"
%hook FSSwitchMainPanel
BOOL currentSwitchAuthenticated;

- (void)setState:(int)arg1 forSwitchIdentifier:(NSString *)identifier {
	if (![getProtectedSwitches() containsObject:identifier]) {
		%orig;
		return;
	}

	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertFlipswitch dismissedHandler:^(BOOL wasCancelled){
		if (!wasCancelled) {
			%orig;
			currentSwitchAuthenticated = YES;
		}
	}];
}
- (void)applyActionForSwitchIdentifier:(NSString *)identifier {
	if (![getProtectedSwitches() containsObject:identifier]) {
		%orig;
		return;
	}

	if (currentSwitchAuthenticated) {
		%orig;
		currentSwitchAuthenticated = NO;
		return;
	}

	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertFlipswitch dismissedHandler:^(BOOL wasCancelled){
		if (!wasCancelled)
			%orig;
	}];
}
- (void)applyAlternateActionForSwitchIdentifier:(NSString *)identifier {
	if (![getProtectedSwitches() containsObject:identifier]) {
		%orig;
		return;
	}

	if (currentSwitchAuthenticated) {
		%orig;
		currentSwitchAuthenticated = NO;
		return;
	}

	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertFlipswitch dismissedHandler:^(BOOL wasCancelled){
		if (!wasCancelled)
			%orig;
	}];
}

%end

%ctor {
	dlopen("/Library/MobileSubstrate/DynamicLibraries/Flipswitch.dylib", RTLD_NOW);
	loadPreferences();
}