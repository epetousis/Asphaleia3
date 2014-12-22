#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
 
@interface ASControlPanel : NSObject <LAListener>
+(instancetype)sharedInstance;
- (void)load;
-(void)unload;
@end