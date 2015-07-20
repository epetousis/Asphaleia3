#import <Preferences/PSListController.h>

@interface ASSecuredSettingsListController : PSListController {
	NSMutableArray *settingsPanelNames;
	NSMutableDictionary *securedSettings;
	NSMutableDictionary *asphaleiaSettings;
}
@end
