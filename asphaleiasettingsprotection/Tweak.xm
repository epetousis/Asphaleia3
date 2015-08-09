#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import "../ASCommon.h"
#import <UIKit/UIKit.h>
#import "../ASPasscodeHandler.h"
#import "../PreferencesHandler.h"
#import "../NSTimer+Blocks.h"
@interface PSSpecifier ()
@property (assign,nonatomic) SEL controllerLoadAction;
@property (assign,nonatomic) Class detailControllerClass;
@end
@interface PrefsListController : PSListController
-(void)lazyLoadBundle:(PSSpecifier *)specifier;
-(id)table;
@end

%hook PrefsListController

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (![getProtectedPanels() containsObject:[[(PSTableCell *)[tableView cellForRowAtIndexPath:indexPath] specifier] identifier]]) {
		%orig;
		return;
	}
	[[ASCommon sharedInstance] authenticateFunction:ASAuthenticationAlertSettingsPanel dismissedHandler:^(BOOL wasCancelled){
		if (!wasCancelled) {
			%orig;
		} else {
			[[self table] deselectRowAtIndexPath:[[self table] indexPathForSelectedRow] animated:YES];
		}
	}];
}

%end

%ctor {
	loadPreferences();
}