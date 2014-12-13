@interface SBDisplayLayout : NSObject
@property (nonatomic,readonly) long long layoutSize;
@property (nonatomic,readonly) NSArray * displayItems;
-(NSArray *)displayItems;
@end