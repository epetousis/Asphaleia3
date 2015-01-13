#import <UIKit/UIKit.h>

@interface SBIconLabelImageParameters : NSObject <NSCopying, NSMutableCopying>
@property(readonly, copy, nonatomic) NSString* text;
-(id)mutableCopyWithZone:(NSZone*)zone;
-(id)copyWithZone:(NSZone*)zone;
-(void)setText:(NSString *)text;
-(void)dealloc;
-(id)initWithParameters:(id)parameters;
-(id)init;
@end

