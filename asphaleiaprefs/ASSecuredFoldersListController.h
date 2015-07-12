#import <Preferences/PSListController.h>

@interface ASSecuredFoldersListController : PSListController {
	NSMutableArray *folderNames;
	NSMutableDictionary *securedFolders;
	NSMutableDictionary *asphaleiaSettings;
}
@end
