@interface SBIconController : NSObject
+(id)sharedInstance;
-(BOOL)isEditing;
-(void)setIsEditing:(BOOL)editing;
// Custom method
-(void)asphaleia_resetAsphaleiaIconView;
@end