#import <Preferences/Preferences.h>
#import <Preferences/PSTableCell.h>
#import <Twitter/Twitter.h>
#import "modalPinVC.h"
#import "TouchIDInfo.h"
#import "AsphaleiaPrefsViewControllers.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define prefpath @"/var/mobile/Library/Preferences/com.a3tweaks.asphaleia.plist"
#define bundlePath @"/Library/PreferenceBundles/AsphaleiaPrefs.bundle"

@interface PSListController ()
-(void)viewDidDisappear:(BOOL)animated;
-(void)viewDidAppear:(BOOL)animated;
@end

@interface AsphaleiaPrefsListController: PSListController {
	BOOL _enteredCorrectly;
	modalPinVC *pinVC;
	NSDate *_resignDate;
}
@property BOOL passcodeViewIsTransitioning;
@property BOOL alreadyAnimatedOnce;
@end

@implementation AsphaleiaPrefsListController
- (id)specifiers {
	UITableView *tv = [self valueForKey:@"_table"];
	tv.scrollEnabled = NO;
	[self setValue:tv forKey:@"_table"];
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"AsphaleiaPrefs" target:self] retain];
	}
	UIBarButtonItem *nextBarButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/AsphaleiaPrefs.bundle/NavHeart@2x.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(loveMeh)];
	UIImageView *A3ImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/AsphaleiaPrefs.bundle/NavA3tweaks@2x.png"]];
	[(UINavigationItem*)self.navigationItem setTitleView:A3ImageView];
	[(UINavigationItem*)self.navigationItem titleView].alpha = 0.0f;
	[(UINavigationItem*)self.navigationItem setRightBarButtonItem:nextBarButton animated:NO];
	[(UINavigationItem*)self.navigationItem setLeftBarButtonItem:nil];
	[(UINavigationItem*)self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Asphaleia"
			   style:UIBarButtonItemStylePlain
			   target:nil
			   action:nil]];

	return _specifiers;
}

- (void)loveMeh
{
	if ([TWTweetComposeViewController canSendTweet]) {		
		TWTweetComposeViewController *controller = [[TWTweetComposeViewController alloc] init];
		[controller setInitialText:@"Securing my apps with #Asphaleia from @A3tweaks!"];
		
		[(UIViewController *)[[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder] presentViewController:controller animated:YES completion:NULL];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia" message:@"You don't seem to be able to tweet right now." delegate:nil cancelButtonTitle:@"Okay." otherButtonTitles:nil];
		[alert show];
	}
}

-(void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	//[(UINavigationItem*)self.navigationItem titleView].alpha = 0.0f;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (!_enteredCorrectly && !self.passcodeViewIsTransitioning) {
		[self presentAuthView];
		_enteredCorrectly = NO;
	} else {
		if (!self.alreadyAnimatedOnce) {
			self.alreadyAnimatedOnce = YES;
			[(UINavigationItem*)self.navigationItem titleView].alpha = 0.0f;
			[UIView animateWithDuration:0.3f animations:^{
				[(UINavigationItem*)self.navigationItem titleView].alpha = 1.0f;
			}];
		}
	}
}

-(void)presentAuthView
{
	// NSLog(@"================presentAuthView");
	if([[NSFileManager defaultManager]fileExistsAtPath:prefpath] && [(NSString *)[[NSDictionary dictionaryWithContentsOfFile:prefpath] objectForKey:@"passcode"] length] == 4) {
		// NSLog(@"================presentAuthView def");
		pinVC = [[modalPinVC alloc] initToAuthWithDelegate:self];
		[(UIViewController *)self presentViewController:pinVC animated:YES completion:NULL];
	} else {
		// NSLog(@"================presentAuthView set");
		pinVC = [[modalPinVC alloc] initToSetPasscodeFirst:self];
		[(UIViewController *)self presentViewController:pinVC animated:YES completion:NULL];
	}
}

- (void)goBack
{
	// NSLog(@"=========poping view");
	[[[self parentController] navigationController] popViewControllerAnimated:YES];
}

-(void)authenticated
{
	_enteredCorrectly = YES;
}

-(void)showSecurity
{
	[self pushController:[[securedAppsAL alloc]init]];
}

-(void)showCreators
{
	[self pushController:[[creatorsVC alloc]init]];
}

-(void)showPasscodeOptions
{
	[self pushController:[[passcodeOptionsVC alloc]init]];
}

/*static inline void LoadDeviceKey(NSMutableDictionary *dict, NSString *key)
{
	CFStringRef result = (const __CFString *)@"";
	result = (const __CFString *)MGCopyAnswer((__bridge CFStringRef)key);
	if (result) {
		[dict setObject:[NSString stringWithString:(__bridge NSString *)result] forKey:key];
	}
}*/

- (void)showMailDialog
{
	// NSLog(@"showMailDialog");
	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
		mailViewController.mailComposeDelegate = (id<MFMailComposeViewControllerDelegate>)self;
		[mailViewController setSubject:@"Asphaleia Support"];
		[mailViewController setToRecipients:[NSArray arrayWithObject:@"asphaleia@a3tweaks.com"]];
		size_t size;
		sysctlbyname("hw.machine", NULL, &size, NULL, 0);
		char *machine = (char *)malloc(size);
		sysctlbyname("hw.machine", machine, &size, NULL, 0);
		CFStringRef udid = (const __CFString *)MGCopyAnswer(kMGUniqueDeviceID);

		[mailViewController setMessageBody:[NSString stringWithFormat:@"\n\n UUID: %@\nDevice: %@\nFirmware: %@",udid, [NSString stringWithCString:machine encoding:NSUTF8StringEncoding], [[UIDevice currentDevice] systemVersion] ] isHTML:NO];
		[(UINavigationController *)self presentViewController:mailViewController animated:YES completion:NULL];
		free(machine);
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Asphaleia" message:@"Something went wrong while trying to compose the support email." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
		[alert show];
	}
}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[controller dismissViewControllerAnimated:YES completion:NULL];
}
@end

// vim:ft=objc
