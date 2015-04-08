#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import "DevicePINController.h"
#import "modalPinVC.h"
#include <sys/socket.h> 
#include <sys/sysctl.h>
#include <AppList/AppList.h>
#import <libactivator/libactivator.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <Preferences/Preferences.h>
#import <CoreFoundation/CoreFoundation.h>
#include <objc/message.h>
#import <Twitter/Twitter.h>
#import <MobileGestalt/MobileGestalt.h>
#import <MessageUI/MessageUI.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "asphaleiaTVC.h"

@interface UIImage(Extras)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

@interface activatorListenerVC : LAListenerSettingsViewController
- (id)initWithListener:(NSString *)listener;
@end

@interface securityExtraVC : UITableViewController
@end
@interface creatorsVC : UITableViewController
@end
@interface passcodeOptionsVC : UITableViewController <UIActionSheetDelegate>
@end
@interface AdvancedTVC : UITableViewController
@end
@interface controlPanelVC : UITableViewController
@end
@interface timeLockVC : UITableViewController 
@end
@interface fingerprintSelection : UITableViewController 
@end

@interface BiometricKit : NSObject 
+(id)manager;
-(id)identities:(id)arg1 ;
@end
@interface BiometricKitIdentity : NSObject 
-(id)uuid;
-(NSString *)name;
@end
@class securedAppsAL;
@interface securedAppDS : NSObject <UITableViewDataSource> {
    NSMutableArray *_sectionDescriptors;
    UITableView *_tableView;
    NSBundle *_localizationBundle;
    BOOL _loadsAsynchronously;
    NSMutableDictionary *prefs;
    BOOL isIphone5S;
}

+ (NSArray *)standardSectionDescriptors;

+ (id)dataSource;
- (id)init;

@property (nonatomic, copy) NSArray *sectionDescriptors;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) securedAppsAL *tableViewController;
@property (nonatomic, retain) NSBundle *localizationBundle;
@property (nonatomic, assign) BOOL loadsAsynchronously;

- (id)cellDescriptorForIndexPath:(NSIndexPath *)indexPath; // NSDictionary if custom cell; NSString if app cell; nil if loading
- (NSString *)displayIdentifierForIndexPath:(NSIndexPath *)indexPath;
- (void)insertSectionDescriptor:(NSDictionary *)sectionDescriptor atIndex:(NSInteger)index;
- (void)removeSectionDescriptorAtIndex:(NSInteger)index;
- (void)removeSectionDescriptorsAtIndexes:(NSIndexSet *)indexSet;
- (BOOL)waitUntilDate:(NSDate *)date forContentInSectionAtIndex:(NSInteger)sectionIndex;
- (void)sectionRequestedSectionReload:(id)section animated:(BOOL)animated;
- (NSMutableDictionary *)preferences;
- (BOOL)is5SfromDS;
@end
@interface asphaleiaTableSectionSource : NSObject {
    ALApplicationTableDataSource *_dataSource;
    NSDictionary *_descriptor;
    NSArray *_displayNames;
    NSArray *_displayIdentifiers;
    CGFloat iconSize;
    BOOL isStaticSection;
    NSInteger loadingState;
    CFTimeInterval loadStartTime;
    NSCondition *loadCondition;
}
@property (nonatomic, readonly) NSDictionary *descriptor;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *footerTitle;
- (void)loadContent;
- (void)detach;
- (NSString *)displayIdentifierForRow:(NSInteger)row;
- (id)cellDescriptorForRow:(NSInteger)row;
- (BOOL)waitForContentUntilDate:(NSDate *)date;
- (NSInteger)rowCount;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRow:(NSInteger)row;
- (id)initWithDescriptor:(NSDictionary *)descriptor dataSource:(ALApplicationTableDataSource *)dataSource loadsAsynchronously:(BOOL)loadsAsynchronously;
@end
@interface securedAppsAL : UITableViewController {
@private
    securedAppDS *dataSource;
    NSMutableDictionary *prefs;
}
- (void)removeButton;
- (void)addButton;
- (void)enableAllApps;
- (void)disableAllApps;
@end