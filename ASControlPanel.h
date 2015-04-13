#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
 
@interface ASControlPanel : NSObject <LAListener> {
	NSData *smallIconData;
}
+(instancetype)sharedInstance;
- (void)load;
-(void)unload;
@end