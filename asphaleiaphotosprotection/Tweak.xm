#import "../ASCommon.h"

%hook UIImagePickerController

-(void)viewWillAppear:(BOOL)animated {
	[self dismissViewControllerAnimated:YES completion:nil];
	return;
}

%end

%hook ALAssetsLibrary

- (void)enumerateGroupsWithTypes:(unsigned int)arg1 usingBlock:(id /* block */)arg2 failureBlock:(id /* block */)arg3 {
	[[ASCommon sharedInstance] showAuthenticationAlertOfType:ASAuthenticationAlertControlCentre beginMesaMonitoringBeforeShowing:YES dismissedHandler:^(BOOL wasCancelled) {
		if (!wasCancelled) {
			%orig;
		}
	}];
}

%end

%hook PHPhotoLibrary

/*- (id)fetchPHObjectsForOIDs:(id)arg1 propertyHint:(unsigned int)arg2 includeTrash:(BOOL)arg3 { %log; return nil; }
- (id)fetchPHObjectsForUUIDs:(id)arg1 entityName:(id)arg2 { %log; return nil; }
- (id)fetchResults { %log; return nil; }
- (id)fetchUpdatedObject:(id)arg1 { %log; return nil; }*/
- (id)initSharedLibrary {
	return nil;
}

%end