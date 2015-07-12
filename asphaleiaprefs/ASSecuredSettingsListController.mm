#include "ASSecuredItemsListController.h"
#import "ASRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <libactivator/libactivator.h>

//[[[[self navigationController] topViewController] rootListController] specifiers]
//[[[[self navigationController] topViewController] rootListController] numberOfSectionsInTableView:[[[[self navigationController] topViewController] rootListController] table]]
//[[[[self navigationController] topViewController] rootListController] tableView:[[[[self navigationController] topViewController] rootListController] table] numberOfRowsInSection:0]
//[[[[self navigationController] topViewController] rootListController] tableView:[[[[self navigationController] topViewController] rootListController] table] cellForRowAtIndexPath]

@implementation ASSecuredSettingsListController

- (id)specifiers {
	return nil;
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PreferencesPath];
    if (!settings[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return settings[specifier.properties[@"key"]];
}
 
-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PreferencesPath]];
    [defaults setObject:value forKey:specifier.properties[@"key"]];
    [defaults writeToFile:PreferencesPath atomically:YES];
    CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
    if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end