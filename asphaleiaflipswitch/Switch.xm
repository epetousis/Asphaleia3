#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"

@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

static NSString *nsNotificationString = @"com.a3tweaks.asphaleia/ReloadPrefs";

@interface AsphaleiaFlipswitchSwitch : NSObject <FSSwitchDataSource> {
	BOOL state;
}
@end

@implementation AsphaleiaFlipswitchSwitch

-(instancetype)init {
	AsphaleiaFlipswitchSwitch *flipswitch = [super init];
	if (flipswitch) {
		state = YES;
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)nsNotificationString, NULL, NULL, YES);
	}
	return flipswitch;
}

- (NSString *)titleForSwitchIdentifier:(NSString *)switchIdentifier {
	return @"Asphaleia 2";
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier {
	return (state) ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier {
	switch (newState) {
	case FSSwitchStateIndeterminate:
		break;
	case FSSwitchStateOn:
		state = YES;
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)nsNotificationString, NULL, NULL, YES);
		break;
	case FSSwitchStateOff:
		state = NO;
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)nsNotificationString, NULL, NULL, YES);
		break;
	}
	return;
}

@end
