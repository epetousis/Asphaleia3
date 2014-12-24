#import "SBApplication.h"

@interface SpringBoard : NSObject
-(void)_revealSpotlight;
-(SBApplication *)_accessibilityFrontMostApplication;
-(void)_applicationOpenURL:(id)url withApplication:(id)application sender:(id)sender publicURLsOnly:(BOOL)only animating:(BOOL)animating activationSettings:(id)settings withResult:(id)result;
-(BOOL)_requestPermissionToOpenURL:(id)openURL withApplication:(id)application sender:(id)sender;
-(void)applicationOpenURL:(id)url;
@end

@interface SpringBoard (SBApplicationTesting)
- (void)failedTest:(id)arg1 withResults:(id)arg2;
//- (void)finishedTest:(id)arg1 extraResults:(id)arg2 waitForNotification:(id)arg3 withTeardownBlock:(CDUnknownBlockType)arg4;
- (void)startedTest:(id)arg1;
- (void)_handleApplicationExit:(id)arg1;
- (_Bool)_shouldPendAlertsForTest:(id)arg1;
- (void)_runControlCenterBringupTest;
- (void)_runControlCenterDismissTest;
- (void)_runNotificationCenterWidgetLaunchTest:(id)arg1;
- (void)_runScrollNotificationCenterTest:(id)arg1;
- (void)_runNotificationCenterBringupTest;
- (void)_runNotificationCenterDismissTest;
- (void)_runAppSwitcherBringupTest;
- (void)_runAppSwitcherDismissTest;
- (void)_runScrollAppSwitcherTest:(id)arg1;
- (void)_runDisplayAlertTest:(id)arg1;
- (void)_runScrollIconListTest;
- (void)runRotationTest:(int)arg1;
- (void)endLaunchTest;
- (void)startResumeTestNamed:(id)arg1 options:(id)arg2;
- (void)startLaunchTestNamed:(id)arg1 options:(id)arg2;
- (void)_cleanUpLaunchTestState;
- (void)_retryLaunchTestWithOptions:(id)arg1;
- (void)_workspaceTransactionCompleted:(id)arg1;
- (void)_unscatterWillBegin:(id)arg1;
- (void)_runUnlockTest;
- (_Bool)runTest:(id)arg1 options:(id)arg2;
@end