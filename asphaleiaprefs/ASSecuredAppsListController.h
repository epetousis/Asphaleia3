#import <Preferences/PSListController.h>

@interface ASSecuredAppsListController : PSListController{
	NSMutableDictionary *systemApps;
	NSArray *systemAppsSortedTitles;
	NSDictionary *appStoreApps;
	NSArray *appStoreAppsSortedTitles;
	NSMutableArray *systemAppsSortedKeys;
	NSMutableArray *appStoreAppsSortedKeys;
	NSArray *allAppsSortedKeys;
	NSMutableDictionary *securedApps;
	NSMutableDictionary *asphaleiaSettings;
}
@end
