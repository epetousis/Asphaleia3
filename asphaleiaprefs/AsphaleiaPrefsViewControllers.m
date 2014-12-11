#import "AsphaleiaPrefsViewControllers.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define prefpath @"/var/mobile/Library/Preferences/com.a3tweaks.asphaleia.plist"
#define bundlePath @"/Library/PreferenceBundles/AsphaleiaPrefs.bundle"

#pragma mark Passcode Options View Controller
@interface passcodeOptionsVC () {
    NSMutableDictionary *prefs;
    BOOL isIphone5S;
}

@end

@implementation passcodeOptionsVC

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
            prefs = [[NSMutableDictionary alloc]initWithContentsOfFile:prefpath];
        } else {
            prefs = [[NSMutableDictionary alloc]init];
        }
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = (char *)malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        if ([[NSString stringWithCString:machine encoding:NSUTF8StringEncoding] rangeOfString:@"iPhone6"].location != NSNotFound) {
            isIphone5S = YES;
        }
    }
    return self;
}
- (void)viewDidAppear:(BOOL)animated
{
    if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
        prefs = [[NSMutableDictionary alloc]initWithContentsOfFile:prefpath];
    } else {
        prefs = [[NSMutableDictionary alloc]init];
    }
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates]; 
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Passcode Options";
    self.navigationItem.backBarButtonItem   = [[UIBarButtonItem alloc] initWithTitle:@"Options"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (isIphone5S) {
        return 6;
    }
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 2;
    }
    if (section == 1 && isIphone5S) {
        if([prefs objectForKey:@"touchID"]) {
            if ([[prefs objectForKey:@"touchID"]boolValue]) {
                return 2;
            }
        }
    } 
    return 1;
}

- (void)updateSettings
{
    [prefs writeToFile:prefpath atomically:YES];
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}
- (BOOL)switchStateForTag:(NSInteger)tag
{
    if(tag == 1 && [prefs objectForKey:@"simplePassocde"]) {
        return [[prefs objectForKey:@"simplePassocde"]boolValue];
    } else if(tag == 2 && [prefs objectForKey:@"touchID"]) {
        return [[prefs objectForKey:@"touchID"]boolValue];
    } else if(tag == 20 && [prefs objectForKey:@"vibrateOnFail"]) {
        return [[prefs objectForKey:@"vibrateOnFail"]boolValue];
    } else {
        return NO;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"A3SwitchCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    int section = indexPath.section;
    if (section > 0 && !isIphone5S) {
        section++;
    }
    if (section == 0) {
        if (indexPath.row == 0) {
            if ([(NSString *)[[[NSDictionary alloc]initWithContentsOfFile:prefpath] objectForKey:@"passcode"] length] == 0) {
                cell.textLabel.text = @"Set Passcode";
            } else {
                cell.textLabel.text = @"Change Passcode";
            }
            cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
        } else {
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Passcode";
            switchview.tag = 1;
            [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
            cell.accessoryView = switchview;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    } else if (section == 1) {
        if (indexPath.row == 0) {
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Touch ID";
            switchview.tag = 2;
            [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
            cell.accessoryView = switchview;
            cell.selectionStyle = UITableViewCellSelectionStyleNone; 
        } else {
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Vibrate On Fail";
            switchview.tag = 20;
            [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
            cell.accessoryView = switchview;
            cell.selectionStyle = UITableViewCellSelectionStyleNone; 
        }
    } else if (section == 2) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"special cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = @"Require Authorization";
        if ([prefs objectForKey:@"timeInterval"]) {
            int timeInterval = [(NSNumber *)[prefs objectForKey:@"timeInterval"] intValue];
            if (timeInterval == 0) {
                cell.detailTextLabel.text = @"Immediately";
            } else if (timeInterval < 60) { 
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ds",timeInterval];
            } else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%dm",(timeInterval/60)];
            }
        }
    } else if (section == 3) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = @"Advanced Options";
    } else if (section == 4) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = @"Asphaleia Control Panel";
    } else if (section == 5) {
        cell.textLabel.text = @"Reset All Settings";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor redColor];
    }
    
    return cell;
}
- (void)updateSwitchAtIndexPath:(UISwitch *)selSwitch{
    if (selSwitch.tag == 1) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"simplePassocde"];
        if (!selSwitch.on && isIphone5S) {
            [prefs setObject:[NSNumber numberWithBool:NO] forKey:@"touchID"];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } else if (selSwitch.tag == 2) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"touchID"];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (selSwitch.on && isIphone5S) {
            [prefs setObject:[NSNumber numberWithBool:YES] forKey:@"simplePassocde"];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } else if (selSwitch.tag == 20) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"vibrateOnFail"];
    }
    [self updateSettings];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section > 0 && !isIphone5S) {
        section++;
    }
    switch (section) {
        case 0:
            return @"Open Secured Apps with a 4 digit number.";
            break;
        case 1:
            return @"Open Secured Apps by scanning your fingerprint. Tap icon again to enter passcode instead, or tap anywhere to cancel.";
            break;
        default:
            return @"";
            break;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    int section = indexPath.section;
    if (section > 0 && !isIphone5S) {
        section++;
    }
    if (section == 0 && indexPath.row == 0) {
        if ([(NSString *)[[[NSDictionary alloc]initWithContentsOfFile:prefpath] objectForKey:@"passcode"] length] == 0) {
            [(UIViewController *)[[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder] presentViewController:[[modalPinVC alloc] initToSetPasscode:self] animated:YES completion:NULL];
        } else {
            [(UIViewController *)[[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder] presentViewController:[[modalPinVC alloc] initWithDelegate:self] animated:YES completion:NULL];
        }
    } else if (section == 2) {
        [self.navigationController pushViewController:[[timeLockVC alloc] init] animated:YES];
    } else if (section == 3) {
        [self.navigationController pushViewController:[[AdvancedTVC alloc] init] animated:YES];
    } else if (section == 4) {
        [self.navigationController pushViewController:[[controlPanelVC alloc] init] animated:YES];
    } else if (section == 5) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to Reset all settings?\n(will respring device)" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Yes, I'm sure", nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        [actionSheet showInView:self.view];
    }
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{ 
    if (buttonIndex == 0) {
        NSError *error; 
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        if ([fileMgr removeItemAtPath:prefpath error:&error] == YES) {}
        system("killall -9 SpringBoard");
    }
}
@end
/*
#pragma mark Creators & Support
@interface creators: PSListController {
}
@end
@implementation creators
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"creators" target:self];
    }
    return _specifiers;
}

@end
@interface support: PSListController {
}
@end
@implementation support
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"support" target:self];
    }
    return _specifiers;
}

@end*/

#pragma mark Advanced T View Controller
@interface AdvancedTVC ()<UITextFieldDelegate> {
    NSMutableDictionary *prefs;
    NSArray *times;
    BOOL isIphone5S;
}

@end

@implementation AdvancedTVC

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
       if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
           prefs = [[NSMutableDictionary alloc]initWithContentsOfFile:prefpath];
       } else {
           prefs = [[NSMutableDictionary alloc]init];
       }
        // prefs = [[NSMutableDictionary alloc]initWithDictionary:@{@"removeLSAuth":[NSNumber numberWithBool:NO],@"obscureAppContent":[NSNumber numberWithBool:YES],@"delayAfterLock":[NSNumber numberWithBool:NO],@"timeIntervalLock":[NSNumber numberWithInt:60]}];
        times = @[@10,@30,@60,@300,@900,@1800];
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = (char *)malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        if ([[NSString stringWithCString:machine encoding:NSUTF8StringEncoding] rangeOfString:@"iPhone6"].location != NSNotFound) {
            isIphone5S = YES;
        }
       
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Advanced Options";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (isIphone5S) 
        return 5;
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 2) {
        if([prefs objectForKey:@"delayAfterLock"]) {
            if ([[prefs objectForKey:@"delayAfterLock"]boolValue]) {
                return 7;
            }
        }
    } else if (section == 3) {
        if ([self switchStateForTag:20]) {
            if ([self currentWifiSSID] != nil) {
                return 3;
            } else {
                return 2;
            }
        }
    }
    return 1;
}
- (BOOL)switchStateForTag:(NSInteger)tag
{
    if(tag == 1 && [prefs objectForKey:@"removeLSAuth"]) {
        return [[prefs objectForKey:@"removeLSAuth"]boolValue];
    } else if(tag == 2 && [prefs objectForKey:@"obscureAppContent"]) {
        return [[prefs objectForKey:@"obscureAppContent"]boolValue];
    } else if(tag == 3 && [prefs objectForKey:@"delayAfterLock"]) {
        return [[prefs objectForKey:@"delayAfterLock"]boolValue];
    } else if(tag == 10 && [prefs objectForKey:@"easyUnlockIntoApp"]) {
        return [[prefs objectForKey:@"easyUnlockIntoApp"]boolValue];
    } else if(tag == 20 && [prefs objectForKey:@"wifiUnlock"]) {
        return [[prefs objectForKey:@"wifiUnlock"]boolValue];
    } else {
        return NO;
    }
}
- (UITableViewCellAccessoryType)accessoryTypeForTag:(NSUInteger)tag
{
    if ([prefs objectForKey:@"timeIntervalLock"]) {
        if ([(NSNumber *)[times objectAtIndex:tag-4] intValue] == [(NSNumber *)[prefs objectForKey:@"timeIntervalLock"] intValue]) {
            return UITableViewCellAccessoryCheckmark;
        }
        
    }
    return UITableViewCellAccessoryNone;
}
- (void)updateSettings
{
   [prefs writeToFile:prefpath atomically:YES];
   CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"A3SwitchCell";
    static NSString *checkCell = @"A3checkCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    if (indexPath.section == 0 || indexPath.section == 1) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        if (indexPath.section == 0) {
            cell.textLabel.text = @"Obscure App Content";
            switchview.tag = 2;
        } else if (indexPath.section == 1) {
            cell.textLabel.text = @"Unlock to App unsecured";
            switchview.tag = 10;
        }
        [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
        cell.accessoryView = switchview;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if(indexPath.section == 4) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = @"Fingerprints";
    } else if(indexPath.section == 3) {
        //wifi names
        if (indexPath.row == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"WI-FI Unlock";
            switchview.tag = 20;
            [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
            cell.accessoryView = switchview;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.row == 1) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryNone;
            UITextField *wifiTextField = [[UITextField alloc] initWithFrame:CGRectMake(150, 8, 145, 30)];
            wifiTextField.adjustsFontSizeToFitWidth = YES;
            wifiTextField.textColor = [UIColor blackColor];
            wifiTextField.keyboardType = UIKeyboardTypeDefault;
            wifiTextField.returnKeyType = UIReturnKeyDone;
            wifiTextField.backgroundColor = [UIColor whiteColor];
            wifiTextField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
            wifiTextField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
            wifiTextField.textAlignment = UITextAlignmentLeft;
            wifiTextField.tag = 0;
            wifiTextField.delegate = self;
            @try {
                wifiTextField.text = [prefs objectForKey:@"wifiNetwork"];
            } @catch (NSException *exception) {
                wifiTextField.text = @"";
            }

            // wifiTextField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
            [wifiTextField setEnabled: YES];
            [cell.contentView addSubview:wifiTextField];
            // NSLog(@"=======wifiTextField %@",wifiTextField);
            cell.textLabel.text = @"Network Name:";
        } else {
            cell.textLabel.text = @"Add Current network";
            // cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
        }


    } else {
        if (indexPath.row == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            switchview.tag = 3;
            [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
            cell.textLabel.text = @"Delay Asphaleia";
        } else if (indexPath.row == 1) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:checkCell];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.tag = 4;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"For 10 seconds";
        } else if (indexPath.row == 2) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:checkCell];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.tag = 5;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"For 30 seconds";
        } else if (indexPath.row == 3) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:checkCell];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.tag = 6;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"For 1 minute";
        } else if (indexPath.row == 4) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:checkCell];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.tag = 7;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"For 5 minutes";
        } else if (indexPath.row == 5) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:checkCell];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.tag = 8;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"For 15 minutes";
        } else if (indexPath.row == 6) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:checkCell];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.tag = 9;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"For 30 minutes";
        }
    }
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textfield {
    [textfield resignFirstResponder];
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [prefs setObject:textField.text forKey:@"wifiNetwork"];
    [self updateSettings];
}
- (void)updateSwitchAtIndexPath:(UISwitch *)selSwitch{
    if (selSwitch.tag == 1) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"removeLSAuth"];
    } else if (selSwitch.tag == 2) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"obscureAppContent"];
    } else if (selSwitch.tag == 3) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"delayAfterLock"];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (selSwitch.tag == 20) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"wifiUnlock"];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (selSwitch.tag == 10) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"easyUnlockIntoApp"];
    }
    [self updateSettings];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        // case 0:
        //     if (isIphone5S) {
        //         return @"Disable Touch ID or Passcode authorization requirements on the Lock Screen.";
        //     }
        //     return @"Disable Passcode authorization requirements on the Lock Screen.";
        //     break;
        case 0:
            return @"Blur multitasking previews for secured apps.";
            break;
        case 2:
            return @"Set a limited amount of time after unlocking before App Security is enabled.";
            break;        
        case 3:
            return @"Unprotect everything when on your home network. Add multiple networks seperating them with a comma and a space e.g. 'A, B'";
            break;
        case 1:
            return @"Do not require re-authorization of a secured app if it is already open upon unlocking.";
            break;
        default:
            return @"";
            break;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 2 && indexPath.row != 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        for (NSInteger i = 0; i < [tableView numberOfRowsInSection:2]; ++i)
        {
            NSIndexPath *loopPath = [NSIndexPath indexPathForRow:i inSection:2];
            if ([loopPath compare:indexPath] != NSOrderedSame) {
                [tableView cellForRowAtIndexPath:loopPath].accessoryType = UITableViewCellAccessoryNone;
            }
        }
        NSNumber *timeSelected = [times objectAtIndex:cell.tag-4];
        [prefs setObject:timeSelected forKey:@"timeIntervalLock"];
        [self updateSettings];
    } else if (indexPath.section == 4) {
        [self.navigationController pushViewController:[[fingerprintSelection alloc]init] animated:YES];
    } else if (indexPath.section == 3 && indexPath.row == 2) {
        UITableViewCell *textCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:3]];
        for (UIView *subview in textCell.contentView.subviews) {
            if ([subview isKindOfClass:[UITextField class]]) {
                NSMutableString *currentWifiString = [NSMutableString stringWithString:[(UITextField *)subview text]];
                NSString *currentSSID = [self currentWifiSSID];
                NSArray *networks = [currentWifiString componentsSeparatedByString:@", "];
                if (![networks containsObject:currentSSID]) {
                    if(currentWifiString.length != 0) {
                        [currentWifiString appendString:@", "];
                    }
                    [currentWifiString appendString:currentSSID];
                    [(UITextField *)subview setText:currentWifiString];
                    [prefs setObject:currentWifiString forKey:@"wifiNetwork"];
                    [self updateSettings];
                }
            }
        }
    }

}
- (NSString *)currentWifiSSID {
    // Does not work on the simulator.
    NSString *ssid = nil;
    NSArray *ifs = (id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"]) {
            ssid = info[@"SSID"];
        }
    }
    return ssid;
}
@end

#pragma mark Control Panel View Controller

@interface controlPanelVC () {
    NSMutableDictionary *CPPrefs;
    BOOL isIphone5S;
}

@end

@implementation controlPanelVC
- (void)viewDidAppear:(BOOL)animated
{
    NSUInteger numOfNows = [self tableView:self.tableView numberOfRowsInSection:0];
    if (numOfNows > 1) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(numOfNows -1) inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates]; 
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Control Panel";
}
- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
            CPPrefs = [[NSMutableDictionary alloc]initWithContentsOfFile:prefpath];
        } else {
            CPPrefs = [[NSMutableDictionary alloc]init];
        }
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = (char *)malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        if ([[NSString stringWithCString:machine encoding:NSUTF8StringEncoding] rangeOfString:@"iPhone6"].location != NSNotFound) {
            isIphone5S = YES;
        }
    }
    return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0 && [CPPrefs objectForKey:@"controlPanel"]) {
        if ([[CPPrefs objectForKey:@"controlPanel"] boolValue]) {
            if (isIphone5S) {
                return 3;
            }
            return 2;
        }
    }
    return 1;
}
- (BOOL)switchStateForTag:(NSInteger)tag
{
    if(tag == 1 && [CPPrefs objectForKey:@"controlPanel"]) {
        return [[CPPrefs objectForKey:@"controlPanel"]boolValue];
    } else if(tag == 2 && [CPPrefs objectForKey:@"controlPanelAllowedInApps"]) {
        return [[CPPrefs objectForKey:@"controlPanelAllowedInApps"]boolValue];
    } else if(tag == 3 && [CPPrefs objectForKey:@"controlPanelTouchID"]) {
        return [[CPPrefs objectForKey:@"controlPanelTouchID"]boolValue];
    } else {
        return NO;
    }
}

- (void)updateSettings
{
    [CPPrefs writeToFile:prefpath atomically:YES];
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"A3SwitchCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    if (indexPath.row == 1 || indexPath.row == 2) {
        if (indexPath.row == 1 && isIphone5S) {
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Via TouchID Hold";
            switchview.tag = 3;
            [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
            cell.accessoryView = switchview;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.row == 1 || indexPath.row == 2) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"special cell"];
            @try {
                cell.detailTextLabel.text = [[LAActivator sharedInstance] localizedTitleForEventName:[[[[LAActivator sharedInstance] eventsAssignedToListenerWithName:@"Control Panel"] objectAtIndex:0] name]];
            } @catch (NSException *exception) {
                //filler
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Activator Action";
        }
    } else {
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        if (indexPath.section == 0) {
            cell.textLabel.text = @"Control Panel";
            cell.textLabel.font = [UIFont systemFontOfSize:17.f];
            switchview.tag = 1;
        } else {
            cell.textLabel.text = @"Allow Access in Apps";
            switchview.tag = 2;
        }
        [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
        cell.accessoryView = switchview;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    // Configure the cell...
    
    return cell;
}
- (void)updateSwitchAtIndexPath:(UISwitch *)selSwitch{
    if (selSwitch.tag == 1) {
        [CPPrefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"controlPanel"];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (selSwitch.tag == 2) {
        [CPPrefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"controlPanelAllowedInApps"];
    } else if (selSwitch.tag == 3) {
        [CPPrefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"controlPanelTouchID"];
    }
    [self updateSettings];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            if (isIphone5S) {
                return @"Use Activator or Touch ID on the home screen to access Asphaleia's Control Panel.";
            }
            return @"Use Activator on the home screen to access Asphaleia's Control Panel.";
            break;
        default:
            return @"";
            break;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1 && isIphone5S) {
        //padding
    } else if (indexPath.row == 1 || indexPath.row == 2) {
        // NSLog(@"=======selecting row at index path");
        [self.navigationController pushViewController:[[activatorListenerVC alloc]initWithListener:@"Control Panel"] animated:YES];
    }

}

@end

#pragma mark Activator Listener View Controller
@implementation activatorListenerVC
- (id)initWithListener:(NSString *)listener
{
    if ((self = [super init])) {
        [self setListenerName:listener];
        self.title = @"Activation Methods";
        // self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    return self;
}
@end

#pragma mark Time Lock View Controller
@interface timeLockVC () {
    NSMutableDictionary *prefs;
    NSArray *times;
}

@end

@implementation timeLockVC

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
            prefs = [[NSMutableDictionary alloc]initWithContentsOfFile:prefpath];
        } else {
            prefs = [[NSMutableDictionary alloc]init];
        }
        // prefs = [[NSMutableDictionary alloc]initWithDictionary:@{@"removeLSAuth":[NSNumber numberWithBool:NO],@"obscureAppContent":[NSNumber numberWithBool:YES],@"delayAfterLock":[NSNumber numberWithBool:NO],@"timeIntervalLock":[NSNumber numberWithInt:60]}];
        times = @[@0,@10,@30,@60,@300,@900,@1800];
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Require Authorization";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.

    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) {
        if ([prefs objectForKey:@"timeInterval"]) {
            if ([(NSNumber *)[prefs objectForKey:@"timeInterval"] intValue] == 0) {
                return 0;
            }
            
        }
        return 1;
    }
    return 7;
}

- (UITableViewCellAccessoryType)accessoryTypeForTag:(NSUInteger)tag
{
    if ([prefs objectForKey:@"timeInterval"]) {
        if ([(NSNumber *)[times objectAtIndex:tag-1] intValue] == [(NSNumber *)[prefs objectForKey:@"timeInterval"] intValue]) {
            return UITableViewCellAccessoryCheckmark;
        }
        
    }
    return UITableViewCellAccessoryNone;
}
- (void)updateSettings
{
    [prefs writeToFile:prefpath atomically:YES];
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"A3SwitchCell";
    static NSString *checkCell = @"A3checkCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    if (indexPath.section == 0) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:checkCell];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        if (indexPath.row == 0) {
            cell.tag = 1;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"Immediately";
        } else if (indexPath.row == 1) {
            cell.tag = 2;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"After 10 seconds";
        } else if (indexPath.row == 2) {
            cell.tag = 3;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"After 30 seconds";
        } else if (indexPath.row == 3) {
            cell.tag = 4;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"After 1 minute";
        } else if (indexPath.row == 4) {
            cell.tag = 5;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"After 5 minutes";
        } else if (indexPath.row == 5) {
            cell.tag = 6;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"After 15 minutes";
        } else if (indexPath.row == 6) {
            cell.tag = 7;
            cell.accessoryType = [self accessoryTypeForTag:cell.tag];
            cell.textLabel.text = @"After 30 minutes";
        }
    } else {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
        cell.textLabel.text = @"Reset on Lock";
        switchview.tag = 8;
        if ([prefs objectForKey:@"ResetTimerOnLock"]) {
            [switchview setOn:[[prefs objectForKey:@"ResetTimerOnLock"]boolValue] animated:NO];
        } else {
            [switchview setOn:NO animated:NO];
        }
        cell.accessoryView = switchview;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}
- (void)updateSwitchAtIndexPath:(UISwitch *)selSwitch{
    [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"ResetTimerOnLock"];
    [self updateSettings];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        for (NSInteger i = 0; i < [tableView numberOfRowsInSection:0]; ++i)
        {
            NSIndexPath *loopPath = [NSIndexPath indexPathForRow:i inSection:0];
            if ([loopPath compare:indexPath] != NSOrderedSame) {
                [tableView cellForRowAtIndexPath:loopPath].accessoryType = UITableViewCellAccessoryNone;
            }
        }
        NSNumber *timeSelected = [times objectAtIndex:cell.tag-1];
        [prefs setObject:timeSelected forKey:@"timeInterval"];
        [self updateSettings];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }

    
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if(section == 0) {
        return @"Set how long after exiting an app before authorization is required to open again.";
    }
    return @"";
}
@end

#pragma mark Fingerprint Selection
@interface fingerprintSelection () {
    NSMutableDictionary *prefs;
    NSArray *fingerPrints;
}

@end

@implementation fingerprintSelection

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
            prefs = [[NSMutableDictionary alloc]initWithContentsOfFile:prefpath];
        } else {
            prefs = [[NSMutableDictionary alloc]init];
        }
        // prefs = [[NSMutableDictionary alloc]initWithDictionary:@{@"removeLSAuth":[NSNumber numberWithBool:NO],@"obscureAppContent":[NSNumber numberWithBool:YES],@"delayAfterLock":[NSNumber numberWithBool:NO],@"timeIntervalLock":[NSNumber numberWithInt:60]}];
        fingerPrints = [NSArray arrayWithArray:[[objc_getClass("BiometricKit") manager] identities:nil]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Fingerprints";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.09) {return 3;}

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.09) {return [fingerPrints count];}
    return 0;
}

- (void)updateSettings
{
    [prefs writeToFile:prefpath atomically:YES];
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *CellIdentifier = @"A3SwitchCell";
    static NSString *checkCell = @"A3checkCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:checkCell];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.text = [(BiometricKitIdentity *)[fingerPrints objectAtIndex:indexPath.row] name];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    NSString *key = @"";
    if (indexPath.section == 0) {
        key = @"invalidFingerPrintsApp";
    } else if (indexPath.section == 1) {
        key = @"invalidFingerPrintsCPDS";
    } else {
        key = @"invalidFingerPrintsPower";
    }
    if ([prefs objectForKey:key]) {
        for (NSString *invalid in [prefs objectForKey:key]) {
            if ([invalid isEqualToString:[(NSUUID *)[(BiometricKitIdentity *)[fingerPrints objectAtIndex:indexPath.row] uuid] UUIDString]]) {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *key = @"";
    if (indexPath.section == 0) {
        key = @"invalidFingerPrintsApp";
    } else if (indexPath.section == 1) {
        key = @"invalidFingerPrintsCPDS";
    } else {
        key = @"invalidFingerPrintsPower";
    }
    NSMutableArray *invalidArray;
    if([prefs objectForKey:key]){
        invalidArray = [NSMutableArray arrayWithArray:[prefs objectForKey:key]];
    } else {
        invalidArray = [[NSMutableArray alloc]init];
    }

    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [invalidArray addObject:[(NSUUID *)[(BiometricKitIdentity *)[fingerPrints objectAtIndex:indexPath.row] uuid] UUIDString]];
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [invalidArray removeObject:[(NSUUID *)[(BiometricKitIdentity *)[fingerPrints objectAtIndex:indexPath.row] uuid] UUIDString]];
    }

    [prefs setObject:invalidArray forKey:key];
    [self updateSettings];
    
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 7.09) {return @"Sorry. As a result of changes by Apple, individual fingerprint recognition is not currently possible in iOS 7.1 and above.";}   
    if ([fingerPrints count] == 0) {
        if (section == 0) {
            return @"No avaliable fingerprints";
        }
        return @"";
    } else {
        if (section == 0) {
            return @"Fingerprints that can access apps.";
        } else if (section == 1) {
            return @"Fingerprints that can access control Panel and dynamic Selection.";
        } else {
            return @"Fingerprints that can access app options and slide to power off.";
        }
    }
    return @"";
}


@end

#pragma mark Secured apps appList
@implementation securedAppsAL
- (void)viewDidAppear:(BOOL)animated
{
    NSUInteger numOfNows = [dataSource tableView:self.tableView numberOfRowsInSection:0];
    // NSLog(@"viewDidAppear securedAppsAL %ld", (unsigned long)numOfNows);
    if (numOfNows > 1) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(numOfNows -1) inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates]; 
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (![[[dataSource preferences] objectForKey:@"globalAppSecurity"] boolValue]) {
        UIBarButtonItem *nextBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Select All" style:UIBarButtonItemStylePlain target:self action:@selector(enableAllApps)];
        [(UINavigationItem*)self.navigationItem setRightBarButtonItem:nextBarButton animated:NO];
    }
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = dataSource;
    dataSource.tableView = self.tableView;
    dataSource.tableViewController = self;

}

- (void)viewDidUnload
{
    dataSource.tableView = nil;
    [super viewDidUnload];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        dataSource = [[securedAppDS alloc] init];
        dataSource.sectionDescriptors = [ALApplicationTableDataSource standardSectionDescriptors];
        self.title = @"Secured Apps";
    }
    return self;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 1 && [dataSource is5SfromDS]) {
        //padding
    } else if (indexPath.section == 0 && (indexPath.row == 1 || indexPath.row == 2)) {
       [self.navigationController pushViewController:[[activatorListenerVC alloc] initWithListener:@"Dynamic Selection"] animated:YES];
    } else if (indexPath.section == 4 || indexPath.section == 3) {
        NSIndexPath *altPath = [NSIndexPath indexPathForRow:indexPath.row inSection:(indexPath.section-3)];
        NSString *displayIdentifier = [dataSource displayIdentifierForIndexPath:altPath];
        BOOL nowSelected = NO;
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            cell.accessoryType = UITableViewCellSelectionStyleNone;
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            nowSelected = YES;
        }
        [[dataSource preferences] setObject:[NSNumber numberWithBool:nowSelected] forKey:displayIdentifier]; 
        [[dataSource preferences] writeToFile:prefpath atomically:YES];
        CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
    } else if (indexPath.section == 1) {
        //display something
        // NSLog(@"========self: %@",self);
        [self.navigationController pushViewController:[[securityExtraVC alloc]init] animated:YES];
    }
}
- (void)enableAllApps
{
    int upto = 4;
    if ([self.tableView numberOfSections] == 4) {
        upto = 3;
    }
    for (NSInteger j = 3; j <= upto; ++j)
    {
        for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i)
        {
           NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:j];
           NSIndexPath *altPath = [NSIndexPath indexPathForRow:i inSection:(j-3)];
           NSString *displayIdentifier = [dataSource displayIdentifierForIndexPath:altPath];
           UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
           cell.accessoryType = UITableViewCellAccessoryCheckmark;
           [[dataSource preferences] setObject:[NSNumber numberWithBool:YES] forKey:displayIdentifier];

        }
    }
    [[dataSource preferences] writeToFile:prefpath atomically:YES];
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
    UIBarButtonItem *nextBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Select None" style:UIBarButtonItemStylePlain target:self action:@selector(disableAllApps)];
    [(UINavigationItem*)self.navigationItem setRightBarButtonItem:nextBarButton animated:NO];
}
- (void)disableAllApps
{
    int upto = 4;
    if ([self.tableView numberOfSections] == 4) {
        upto = 3;
    }
    for (NSInteger j = 3; j <= upto; ++j)
    {
        for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i)
        {
           NSIndexPath *altPath = [NSIndexPath indexPathForRow:i inSection:(j-3)];
           NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:j];
           NSString *displayIdentifier = [dataSource displayIdentifierForIndexPath:altPath];
           UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
           cell.accessoryType = UITableViewCellAccessoryNone;
           [[dataSource preferences] setObject:[NSNumber numberWithBool:NO] forKey:displayIdentifier];

        }
    }
    [[dataSource preferences] writeToFile:prefpath atomically:YES];
    CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
    UIBarButtonItem *nextBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Select All" style:UIBarButtonItemStylePlain target:self action:@selector(enableAllApps)];
    [(UINavigationItem*)self.navigationItem setRightBarButtonItem:nextBarButton animated:NO];
}
- (void)removeButton
{
    // UIBarButtonItem *nextBarButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(enableAllApps)];
    [(UINavigationItem*)self.navigationItem setRightBarButtonItem:nil animated:YES];
}
- (void)addButton
{
    UIBarButtonItem *nextBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Select All" style:UIBarButtonItemStylePlain target:self action:@selector(enableAllApps)];
    [(UINavigationItem*)self.navigationItem setRightBarButtonItem:nextBarButton animated:YES];
}
@end

#pragma mark Security Extra View Controller
@interface securityExtraVC () {
    NSMutableDictionary *CPPrefs;
    BOOL isIphone5S;
}

@end
@implementation securityExtraVC
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Advanced";
}
- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
           CPPrefs = [[NSMutableDictionary alloc]initWithContentsOfFile:prefpath];
        } else {
            CPPrefs = [[NSMutableDictionary alloc]init];
        }
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = (char *)malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        if ([[NSString stringWithCString:machine encoding:NSUTF8StringEncoding] rangeOfString:@"iPhone6"].location != NSNotFound) {
            isIphone5S = YES;
        }
        free(machine);
    }
    return self;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}
- (BOOL)switchStateForTag:(NSInteger)tag
{
    if(tag == 3 && [CPPrefs objectForKey:@"preventAppDeletion"]) {
        return [[CPPrefs objectForKey:@"preventAppDeletion"]boolValue];
    } else if(tag == 4 && [CPPrefs objectForKey:@"preventPowerOff"]) {
        return [[CPPrefs objectForKey:@"preventPowerOff"]boolValue];
    } else if(tag == 5 && [CPPrefs objectForKey:@"secureSwitcher"]) {
        return [[CPPrefs objectForKey:@"secureSwitcher"]boolValue];
    } else if(tag == 6 && [CPPrefs objectForKey:@"secureCC"]) {
        return [[CPPrefs objectForKey:@"secureCC"]boolValue];
    } else if(tag == 7 && [CPPrefs objectForKey:@"secureSpotlight"]) {
        return [[CPPrefs objectForKey:@"secureSpotlight"]boolValue];
    } else if(tag == 8 && [CPPrefs objectForKey:@"photosProtection"]) {
        return [[CPPrefs objectForKey:@"photosProtection"]boolValue];
    } else {
        return NO;
    }
}
- (void)updateSettings
{
   [CPPrefs writeToFile:prefpath atomically:YES];
   CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"A3SwitchCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
    if (indexPath.section == 0) {
        cell.textLabel.text = @"App Arranging";
        cell.imageView.image = [UIImage imageNamed:@"IconEditMode.png" inBundle:[[NSBundle alloc] initWithPath:bundlePath]];
        switchview.tag = 3;
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"Slide to Power Off";
        cell.imageView.image = [UIImage imageNamed:@"IconPowerOff.png" inBundle:[[NSBundle alloc] initWithPath:bundlePath]];
        switchview.tag = 4;
    } else if (indexPath.section == 2) {
        cell.textLabel.text = @"Multitasking";
        cell.imageView.image = [UIImage imageNamed:@"IconMultitasking.png" inBundle:[[NSBundle alloc] initWithPath:bundlePath]];
        switchview.tag = 5;
    } else if (indexPath.section == 3) {
        cell.textLabel.text = @"Control Center";
        cell.imageView.image = [UIImage imageNamed:@"IconControlCenter.png" inBundle:[[NSBundle alloc] initWithPath:bundlePath]];
        switchview.tag = 6;
    } else if (indexPath.section == 4) {
        cell.textLabel.text = @"Spotlight";
        cell.imageView.image = [UIImage imageNamed:@"IconSpotlight.png" inBundle:[[NSBundle alloc] initWithPath:bundlePath]];
        switchview.tag = 7;
    } else if (indexPath.section == 5) {
        cell.textLabel.text = @"Photos";
        cell.imageView.image = [UIImage imageNamed:@"Icon.png" inBundle:[[NSBundle alloc] initWithPath:bundlePath]];
        switchview.tag = 8;
    }
    [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
    cell.accessoryView = switchview;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    // Configure the cell...
    
    return cell;
}
- (void)updateSwitchAtIndexPath:(UISwitch *)selSwitch{
    if (selSwitch.tag == 3) {
        [CPPrefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"preventAppDeletion"];
    } else if (selSwitch.tag == 4) {
        [CPPrefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"preventPowerOff"];
    } else if (selSwitch.tag == 5) {
        [CPPrefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"secureSwitcher"];
    } else if (selSwitch.tag == 6) {
        [CPPrefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"secureCC"];
    } else if (selSwitch.tag == 7) {
        [CPPrefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"secureSpotlight"];
    } else if (selSwitch.tag == 8) {
        [CPPrefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"photosProtection"];
    }
    [self updateSettings];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 5) {
        return @"EXPERIMENTAL, protect photos access from all unlocked apps";
    }
    return nil;
}
@end

#pragma mark Creators View Controller
@interface creatorsVC () {
    NSMutableDictionary *CPPrefs;
}

@end
@implementation creatorsVC
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Creators";
}
- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
           CPPrefs = [[NSMutableDictionary alloc]initWithContentsOfFile:prefpath];
        } else {
            CPPrefs = [[NSMutableDictionary alloc]init];
        }
    }
    return self;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{    
    return 4;
}
- (id)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    return 1;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *handleString;
    switch (indexPath.section) {
        case 0:
            handleString = @"Sentry_NC";
            break;
        case 1:
            handleString = @"evilgoldfish01";
            break;
        case 2:
            handleString = @"CallumRyan314";
            break;
        case 3:
            handleString = @"A3tweaks";
            break;
        default:
            return;
    }
    UIApplication *app = [UIApplication sharedApplication];
    NSURL *tweetbot = [NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:handleString]];
    if ([app canOpenURL:tweetbot])
        [app openURL:tweetbot];
    else {
        NSURL *twitterapp = [NSURL URLWithString:[@"twitter:///user?screen_name=" stringByAppendingString:handleString]];
        if ([app canOpenURL:twitterapp])
            [app openURL:twitterapp];
        else {
            NSURL *twitterweb = [NSURL URLWithString:[@"http://twitter.com/" stringByAppendingString:handleString]];
            [app openURL:twitterweb];
        }
    }
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSString *reuseIdentifier = @"Profile";
    asphaleiaTVC *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (cell == nil) {
        cell = [[asphaleiaTVC alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    switch (section) {
        case 0:
            [cell loadImage:@"Sentry" nameText:@"Sentry" handleText:@"(@Sentry_NC)" infoText:@"Visual Interaction Designer,\rAuxo, Apex, AltKB, Aplo,\rFounder of A³tweaks."];
            break;
        case 1:
            [cell loadImage:@"Evan" nameText:@"Evan" handleText:@"(@evilgoldfish01)" infoText:@"iOS and OSX Developer,\nLockGlyph, NoPlayerBlur,\nStudent."];
            break;
        case 2:
            [cell loadImage:@"Callum" nameText:@"Callum" handleText:@"(@CallumRyan314)" infoText:@"iOS Developer,\nSMS Stats,\nOriginal Asphaleia developer."];
            break;
        case 3:
            [cell loadImage:nil nameText:nil handleText:nil infoText:nil];
            cell.textLabel.text = @"Follow A3tweaks";
            cell.imageView.image = [UIImage imageNamed:@"GroupLogo.png" inBundle:[[NSBundle alloc] initWithPath:bundlePath] compatibleWithTraitCollection:nil];
            break;
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < 3) return 106.0f;
    else return 44.0f;
}
@end

#pragma mark Asphaleia ALTV Cell
const NSString *ALSectionDescriptorTitleKey = @"title"; const NSString *ALSectionDescriptorFooterTitleKey = @"footer-title"; const NSString *ALSectionDescriptorPredicateKey = @"predicate"; const NSString *ALSectionDescriptorCellClassNameKey = @"cell-class-name"; const NSString *ALSectionDescriptorIconSizeKey = @"icon-size"; const NSString *ALSectionDescriptorItemsKey = @"items"; const NSString *ALSectionDescriptorSuppressHiddenAppsKey = @"suppress-hidden-apps"; const NSString *ALSectionDescriptorVisibilityPredicateKey = @"visibility-predicate"; const NSString *ALItemDescriptorTextKey = @"text"; const NSString *ALItemDescriptorDetailTextKey = @"detail-text"; const NSString *ALItemDescriptorImageKey = @"image";

static NSInteger DictionaryTextComparator(id a, id b, void *context) { return [[(__bridge NSDictionary *)context objectForKey:a] localizedCaseInsensitiveCompare:[(__bridge NSDictionary *)context objectForKey:b]];}

// nice typo.
@interface aspheliaALTVCell : UITableViewCell
@end
@implementation aspheliaALTVCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.backgroundColor = [UIColor clearColor];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGSize cellSize = self.bounds.size;
        CGRect frame = spinner.frame;
        frame.origin.x = (cellSize.width - frame.size.width) * 0.5f;
        frame.origin.y = (cellSize.height - frame.size.height) * 0.5f;
        spinner.frame = frame;
        spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [spinner startAnimating];
        [self addSubview:spinner];
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

@end

@interface ALApplicationTableDataSource ()
- (void)sectionRequestedSectionReload:(id)section animated:(BOOL)animated;
@end

#pragma mark Asphaleia Table Section Source
__attribute__((visibility("hidden")))
static NSArray *hiddenDisplayIdentifiers; static NSMutableArray *iconsToLoad; static OSSpinLock spinLock; static UIImage *defaultImage;

@implementation asphaleiaTableSectionSource
+ (void)initialize
{
    if (self == [asphaleiaTableSectionSource class]) {
        defaultImage = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:@"com.apple.WebSheet"];
        hiddenDisplayIdentifiers = [[NSArray alloc] initWithObjects:@"com.apple.AdSheet",@"com.apple.AdSheetPhone",@"com.apple.AdSheetPad",@"com.apple.DataActivation",@"com.apple.DemoApp",@"com.apple.fieldtest",@"com.apple.iosdiagnostics",@"com.apple.iphoneos.iPodOut",@"com.apple.TrustMe",@"com.apple.WebSheet",@"com.apple.springboard",@"com.apple.purplebuddy",@"com.apple.datadetectors.DDActionsService",@"com.apple.FacebookAccountMigrationDialog",@"com.apple.iad.iAdOptOut",@"com.apple.ios.StoreKitUIService",@"com.apple.TextInput.kbd",@"com.apple.MailCompositionService",@"com.apple.mobilesms.compose",@"com.apple.quicklook.quicklookd",@"com.apple.ShoeboxUIService",@"com.apple.social.remoteui.SocialUIService",@"com.apple.WebViewService",@"com.apple.gamecenter.GameCenterUIService",@"com.apple.appleaccount.AACredentialRecoveryDialog",@"com.apple.CompassCalibrationViewService",@"com.apple.WebContentFilter.remoteUI.WebContentAnalysisUI",@"com.apple.PassbookUIService",@"com.apple.uikit.PrintStatus",@"com.apple.Copilot",@"com.apple.MusicUIService",@"com.apple.AccountAuthenticationDialog",@"com.apple.MobileReplayer",@"com.apple.SiriViewService",nil];
    }
}
+ (void)loadIconsFromBackground
{
    OSSpinLockLock(&spinLock);
    ALApplicationList *appList = [ALApplicationList sharedApplicationList];
    while ([iconsToLoad count]) {
        NSDictionary *userInfo = [iconsToLoad objectAtIndex:0];
        [iconsToLoad removeObjectAtIndex:0];
        OSSpinLockUnlock(&spinLock);
        CGImageRelease([appList copyIconOfSize:[[userInfo objectForKey:ALIconSizeKey] integerValue] forDisplayIdentifier:[userInfo objectForKey:ALDisplayIdentifierKey]]);
        OSSpinLockLock(&spinLock);
    }
    iconsToLoad = nil;
    OSSpinLockUnlock(&spinLock);
}
- (id)initWithDescriptor:(NSDictionary *)descriptor dataSource:(ALApplicationTableDataSource *)dataSource loadsAsynchronously:(BOOL)loadsAsynchronously
{
    if ((self = [super init])) {
        _dataSource = dataSource;
        _descriptor = [descriptor copy];
        NSArray *items = [_descriptor objectForKey:@"items"];
        if ([items isKindOfClass:[NSArray class]]) {
            _displayNames = [items copy];
            isStaticSection = YES;
        } else {
            if (loadsAsynchronously) {
                loadingState = 1;
                loadStartTime = CACurrentMediaTime();
                [self performSelectorInBackground:@selector(loadContent) withObject:nil];
                loadCondition = [[NSCondition alloc] init];
            } else {
                [self loadContent];
            }
        }
    }
    return self;
}
- (void)loadContent
{
    NSDictionary *descriptor = _descriptor;
    NSString *predicateText = [descriptor objectForKey:ALSectionDescriptorPredicateKey];
    ALApplicationList *appList = [ALApplicationList sharedApplicationList];
    NSDictionary *applications;
    if (predicateText)
        applications = [appList applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:predicateText]];
    else
        applications = [appList applications];
    NSMutableArray *displayIdentifiers = [[applications allKeys] mutableCopy];
    if ([[descriptor objectForKey:ALSectionDescriptorSuppressHiddenAppsKey] boolValue]) {
        for (NSString *displayIdentifier in hiddenDisplayIdentifiers)
            [displayIdentifiers removeObject:displayIdentifier];
    }
    [displayIdentifiers sortUsingFunction:DictionaryTextComparator context:(void *)applications];
    NSMutableArray *displayNames = [[NSMutableArray alloc] init];
    for (NSString *displayId in displayIdentifiers)
        [displayNames addObject:[applications objectForKey:displayId]];
    [loadCondition lock];
    _displayIdentifiers = displayIdentifiers;
    _displayNames = displayNames;
    iconSize = [[descriptor objectForKey:ALSectionDescriptorIconSizeKey] floatValue];
    loadingState = 2;
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(completedLoading) withObject:nil waitUntilDone:NO];
    }
    [loadCondition signal];
    [loadCondition unlock];
}
- (void)completedLoading
{
    if (loadingState) {
        loadingState = 0;
        [_dataSource sectionRequestedSectionReload:self animated:CACurrentMediaTime() - loadStartTime > 0.1];
    }
}
- (BOOL)waitForContentUntilDate:(NSDate *)date
{
    if (loadingState) {
        [loadCondition lock];
        BOOL result;
        if (loadingState == 1) {
            if (date)
                result = [loadCondition waitUntilDate:date];
            else {
                [loadCondition wait];
                result = YES;
            }
        } else {
            result = YES;
        }
        [loadCondition unlock];
        if (loadingState == 2) {
            [self completedLoading];
        }
        return result;
    }
    return YES;
}
@synthesize descriptor = _descriptor;
static inline NSString *Localize(NSBundle *bundle, NSString *string)
{
    return bundle ? [bundle localizedStringForKey:string value:string table:nil] : string;
}
#define Localize(string) Localize(_dataSource.localizationBundle, string)
- (NSString *)title
{
    return Localize([_descriptor objectForKey:ALSectionDescriptorTitleKey]);
}
- (NSString *)footerTitle
{
    return Localize([_descriptor objectForKey:ALSectionDescriptorFooterTitleKey]);
}
- (NSString *)displayIdentifierForRow:(NSInteger)row
{
    @try {
        NSString *title = (NSString *)[_displayIdentifiers objectAtIndex:row];
        return title;
    } @catch (NSException *exception) {
        return @"";
    }
}
- (id)cellDescriptorForRow:(NSInteger)row
{
    return isStaticSection ? [_displayNames objectAtIndex:row] : [_displayIdentifiers objectAtIndex:row];
}
- (NSInteger)rowCount
{
    return loadingState ? 1 : [_displayNames count];
}
static inline UITableViewCell *CellWithClassName(NSString *className, UITableView *tableView)
{
    return [tableView dequeueReusableCellWithIdentifier:className] ?: [[NSClassFromString(className) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:className];
}
// the method below is causing a crash - fix it.
#define CellWithClassName(className) \
    CellWithClassName(className, tableView)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRow:(NSInteger)row
{
    NSLog(@"AsphaleiaPrefs -- tableView:cellForRow: was called");
    if (isStaticSection) {
        NSLog(@"AsphaleiaPrefs -- isStaticSection was called");
        NSDictionary *itemDescriptor = [_displayNames objectAtIndex:row];
        UITableViewCell *cell = CellWithClassName([itemDescriptor objectForKey:ALSectionDescriptorCellClassNameKey] ?: [_descriptor objectForKey:ALSectionDescriptorCellClassNameKey] ?: @"UITableViewCell");
        cell.textLabel.text = Localize([itemDescriptor objectForKey:ALItemDescriptorTextKey]);
        cell.detailTextLabel.text = Localize([itemDescriptor objectForKey:ALItemDescriptorDetailTextKey]);
        NSString *imagePath = [itemDescriptor objectForKey:ALItemDescriptorImageKey];
        UIImage *image = nil;
        if (imagePath) {
            CGFloat scale;
            if ([UIScreen instancesRespondToSelector:@selector(scale)] && ((scale = [[UIScreen mainScreen] scale]) != 1.0f))
                image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@@%gx.%@", [imagePath stringByDeletingPathExtension], scale, [imagePath pathExtension]]];
            if (!image)
                image = [UIImage imageWithContentsOfFile:imagePath];
        }
        cell.imageView.image = image;
        return cell;
    }
    if (loadingState) {
        NSLog(@"AsphaleiaPrefs -- loadingState was called");
        return [tableView dequeueReusableCellWithIdentifier:@"aspheliaALTVCell"] ?: [[aspheliaALTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"aspheliaALTVCell"];
    }
    UITableViewCell *cell = CellWithClassName([_descriptor objectForKey:ALSectionDescriptorCellClassNameKey] ?: @"UITableViewCell");
    cell.textLabel.text = [_displayNames objectAtIndex:row];
    if (iconSize > 0) {
        NSString *displayIdentifier = [_displayIdentifiers objectAtIndex:row];
        ALApplicationList *appList = [ALApplicationList sharedApplicationList];
        if ([appList hasCachedIconOfSize:iconSize forDisplayIdentifier:displayIdentifier]) {
            cell.imageView.image = [appList iconOfSize:iconSize forDisplayIdentifier:displayIdentifier];
            cell.indentationWidth = 10.0f;
            cell.indentationLevel = 0;
        } else {
            if (defaultImage.size.width == iconSize) {
                cell.imageView.image = defaultImage;
                cell.indentationWidth = 10.0f;
                cell.indentationLevel = 0;
            } else {
                cell.indentationWidth = iconSize + 7.0f;
                cell.indentationLevel = 1;
                cell.imageView.image = nil;
            }
            cell.imageView.image = defaultImage;
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInteger:iconSize], ALIconSizeKey,
                                      displayIdentifier, ALDisplayIdentifierKey,
                                      nil];
            OSSpinLockLock(&spinLock);
            if (iconsToLoad)
                [iconsToLoad insertObject:userInfo atIndex:0];
            else {
                iconsToLoad = [[NSMutableArray alloc] initWithObjects:userInfo, nil];
                [asphaleiaTableSectionSource performSelectorInBackground:@selector(loadIconsFromBackground) withObject:nil];
            }
            OSSpinLockUnlock(&spinLock);
        }
    } else {
        cell.imageView.image = nil;
    }
    return cell;
}
- (void)updateCell:(UITableViewCell *)cell forRow:(NSInteger)row withLoadedIconOfSize:(CGFloat)newIconSize forDisplayIdentifier:(NSString *)displayIdentifier
{
    if ([displayIdentifier isEqual:[_displayIdentifiers objectAtIndex:row]] && newIconSize == iconSize) {
        UIImageView *imageView = cell.imageView;
        UIImage *image = imageView.image;
        if (!image || (image == defaultImage)) {
            cell.indentationLevel = 0;
            cell.indentationWidth = 10.0f;
            imageView.image = [[ALApplicationList sharedApplicationList] iconOfSize:newIconSize forDisplayIdentifier:displayIdentifier];
            [cell setNeedsLayout];
        }
    }
}
- (void)detach
{
    _dataSource = nil;
}
@end

#pragma mark Secured App Data Source
@implementation securedAppDS
+ (NSArray *)standardSectionDescriptors
{
    NSNumber *iconSize = [NSNumber numberWithUnsignedInteger:ALApplicationIconSizeSmall];
    return [NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys: @"System Applications", ALSectionDescriptorTitleKey, @"isSystemApplication = TRUE", ALSectionDescriptorPredicateKey, @"UITableViewCell", ALSectionDescriptorCellClassNameKey, iconSize, ALSectionDescriptorIconSizeKey, (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey, nil],
        [NSDictionary dictionaryWithObjectsAndKeys: @"User Applications", ALSectionDescriptorTitleKey, @"isSystemApplication = FALSE", ALSectionDescriptorPredicateKey, @"UITableViewCell", ALSectionDescriptorCellClassNameKey, iconSize, ALSectionDescriptorIconSizeKey, (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey, nil], nil];
}
+ (id)dataSource
{
    return [[self alloc] init];
}
- (id)init
{
    if ((self = [super init])) {
        _loadsAsynchronously = YES;
        _sectionDescriptors = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iconLoadedFromNotification:) name:ALIconLoadedNotification object:nil];
        if([[NSFileManager defaultManager]fileExistsAtPath:prefpath]){
            prefs = [[NSMutableDictionary alloc]initWithContentsOfFile:prefpath];
        } else {
            prefs = [[NSMutableDictionary alloc]init];
        }
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = (char *)malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        if ([[NSString stringWithCString:machine encoding:NSUTF8StringEncoding] rangeOfString:@"iPhone6"].location != NSNotFound) {
            isIphone5S = YES;
        }
        free(machine);
    }
    return self;
}
@synthesize tableView = _tableView, localizationBundle = _localizationBundle, loadsAsynchronously = _loadsAsynchronously;
- (void)setSectionDescriptors:(NSArray *)sectionDescriptors
{
    for (asphaleiaTableSectionSource *section in _sectionDescriptors) {
        [section detach];
    }
    [_sectionDescriptors removeAllObjects];
    for (NSDictionary *descriptor in sectionDescriptors) {
        asphaleiaTableSectionSource *section = [[asphaleiaTableSectionSource alloc] initWithDescriptor:descriptor dataSource:(ALApplicationTableDataSource *)self loadsAsynchronously:_loadsAsynchronously];
        [_sectionDescriptors addObject:section];
    }
    [_tableView reloadData];
}
- (NSArray *)sectionDescriptors
{
    // Recreate the array
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[_sectionDescriptors count]];
    for (asphaleiaTableSectionSource *section in _sectionDescriptors) {
        [result addObject:section.descriptor];
    }
    return result;
}
- (void)removeSectionDescriptorsAtIndexes:(NSIndexSet *)indexSet
{
    if (indexSet) {
        NSUInteger index = [indexSet firstIndex];
        if (index != NSNotFound) {
            NSUInteger lastIndex = [indexSet lastIndex];
            for (;;) {
                [[_sectionDescriptors objectAtIndex:index] detach];
                if (index == lastIndex) {
                    break;
                }
                index = [indexSet indexGreaterThanIndex:index];
            }
        }
    }
    [_sectionDescriptors removeObjectsAtIndexes:indexSet];
    [_tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}
- (void)removeSectionDescriptorAtIndex:(NSInteger)index
{
    [self removeSectionDescriptorsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
}
- (void)insertSectionDescriptor:(NSDictionary *)sectionDescriptor atIndex:(NSInteger)index
{
    asphaleiaTableSectionSource *section = [[asphaleiaTableSectionSource alloc] initWithDescriptor:sectionDescriptor dataSource:(ALApplicationTableDataSource *)self loadsAsynchronously:_loadsAsynchronously];
    [_sectionDescriptors insertObject:section atIndex:index];
    [_tableView insertSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationFade];
}
- (void)setLocalizationBundle:(NSBundle *)localizationBundle
{
    if (_localizationBundle != localizationBundle) {
        _localizationBundle = localizationBundle;
        [_tableView reloadData];
    }
}
- (NSString *)displayIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    return [[_sectionDescriptors objectAtIndex:[indexPath section]] displayIdentifierForRow:[indexPath row]];
}
- (id)cellDescriptorForIndexPath:(NSIndexPath *)indexPath
{
    return [[_sectionDescriptors objectAtIndex:[indexPath section]] cellDescriptorForRow:[indexPath row]];
}
- (void)iconLoadedFromNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *displayIdentifier = [userInfo objectForKey:ALDisplayIdentifierKey];
    CGFloat iconSize = [[userInfo objectForKey:ALIconSizeKey] floatValue];
    for (NSIndexPath *indexPath in _tableView.indexPathsForVisibleRows) {
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
        if(section == 4 || section == 3) {
            asphaleiaTableSectionSource *sectionObject = [_sectionDescriptors objectAtIndex:(section-3)];
            [sectionObject updateCell:[_tableView cellForRowAtIndexPath:indexPath] forRow:row withLoadedIconOfSize:iconSize forDisplayIdentifier:displayIdentifier];
        }
    }
}
- (void)sectionRequestedSectionReload:(asphaleiaTableSectionSource *)section animated:(BOOL)animated
{
    [_tableView reloadData];
}
- (BOOL)waitUntilDate:(NSDate *)date forContentInSectionAtIndex:(NSInteger)sectionIndex
{
    asphaleiaTableSectionSource *section = [_sectionDescriptors objectAtIndex:sectionIndex];
    return [section waitForContentUntilDate:date];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (!_tableView) {
        _tableView = tableView;
        // NSLog(@"ALApplicationTableDataSource warning: Assumed control over %@", tableView);
    }
    if ([self switchStateForTag:10]) 
        return 3;
    return ([_sectionDescriptors count] + 3);
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 4 || section == 3) {
        return [[_sectionDescriptors objectAtIndex:(section-3)] title];
    }
    return @"";
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            if (isIphone5S) {
                return @"Use Activator or Touch ID in an app to add or remove it from your Secured Apps list.";
            }
            return @"Use Activator in an app to add or remove it from your Secured Apps list.";
            break;
        default:
            return @"";
            break;
    }
}
- (void)updateSwitchAtIndexPath:(UISwitch *)selSwitch{
    if (selSwitch.tag == 1) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"dynamicSelection"];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (selSwitch.tag == 2) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"dynamicSelectionTouchID"];
    } else if (selSwitch.tag == 10) {
        [prefs setObject:[NSNumber numberWithBool:selSwitch.on] forKey:@"globalAppSecurity"];
        [prefs setObject:[NSNumber numberWithBool:!selSwitch.on] forKey:@"prefsListEnabled"];

        if (selSwitch.on) {
            [self.tableViewController removeButton];

            [_tableView beginUpdates];
            [_tableView deleteSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
            if ([_sectionDescriptors count] == 2)
                [_tableView deleteSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationAutomatic];
            [_tableView endUpdates];

        } else {
            [self.tableViewController addButton];

            [_tableView beginUpdates];
            [_tableView insertSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
            if ([_sectionDescriptors count] == 2)
                [_tableView insertSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationAutomatic];
            [_tableView endUpdates];
        }

    }
    [self updateSettings];
}
- (BOOL)switchStateForTag:(NSInteger)tag
{
    if(tag == 1 && [prefs objectForKey:@"dynamicSelection"]) {
        return [[prefs objectForKey:@"dynamicSelection"]boolValue];
    } else if(tag == 2 && [prefs objectForKey:@"dynamicSelectionTouchID"]) {
        return [[prefs objectForKey:@"dynamicSelectionTouchID"]boolValue];
    } else if(tag == 10 && [prefs objectForKey:@"globalAppSecurity"]) {
        return [[prefs objectForKey:@"globalAppSecurity"]boolValue];
    } else {
        return NO;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // NSLog(@"=======numberOfRowsInSection");
    if (section == 4 || section == 3) {
        return [[_sectionDescriptors objectAtIndex:(section-3)] rowCount];
    } else if (section == 0) {
        if ([[prefs objectForKey:@"dynamicSelection"] boolValue]) {
            if (isIphone5S) {
                return 3;
            }
            return 2;
        }
    }
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"A3SwitchCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    if (indexPath.section == 4 || indexPath.section == 3) {
        NSIndexPath *altPath = [NSIndexPath indexPathForRow:indexPath.row inSection:(indexPath.section-3)];
        asphaleiaTableSectionSource *section = [_sectionDescriptors objectAtIndex:altPath.section];
        cell = [section tableView:tableView cellForRow:altPath.row];

        NSString *displayIdentifier = [self displayIdentifierForIndexPath:altPath];
        BOOL selected = NO;
        if([prefs objectForKey:displayIdentifier]) {
            selected = [[prefs objectForKey:displayIdentifier] boolValue];
        }
        if (selected) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark; 
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone; 
        }
    } else if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Dynamic Selection";
            switchview.tag = 1;
            [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
            cell.accessoryView = switchview;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.row == 1 && isIphone5S) {
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Via TouchID Hold";
            switchview.tag = 2;
            [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
            cell.accessoryView = switchview;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.row == 1 || indexPath.row == 2) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"special cell"];
            @try {
                // NSLog(@"rechecking");
                cell.detailTextLabel.text = [[LAActivator sharedInstance] localizedTitleForEventName:[[[[LAActivator sharedInstance] eventsAssignedToListenerWithName:@"Dynamic Selection"] objectAtIndex:0] name]];
            } @catch (NSException *exception) { }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Activator Action";
        }
    } else if (indexPath.section == 1) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Advanced Security";
    } else if (indexPath.section == 2) {
            UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(updateSwitchAtIndexPath:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Global App Security";
            switchview.tag = 10;
            [switchview setOn:[self switchStateForTag:switchview.tag] animated:NO];
            cell.accessoryView = switchview;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}
- (NSMutableDictionary *)preferences
{
    return prefs;
}
- (BOOL)is5SfromDS
{
    return isIphone5S;
}
- (void)updateSettings
{
   [prefs writeToFile:prefpath atomically:YES];
   CFNotificationCenterPostNotification (CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.a3tweaks.asphaleia/ReloadPrefs"), NULL, NULL,true);
}
@end