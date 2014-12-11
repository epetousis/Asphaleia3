#import <UIKit/UIKit.h>

__attribute__((visibility("hidden")))
@interface asphaleiaTVC : UITableViewCell {
@private
	UIImageView *profileView;
	UIImageView *birdView;
	
	UILabel *nameLabel;
	UILabel *handleLabel;
	UILabel *infoLabel;
}

- (void)loadImage:(NSString *)imageName nameText:(NSString *)nameText handleText:(NSString *)handleText infoText:(NSString *)infoText;

@end
