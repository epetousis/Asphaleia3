#import "AsphaleiaTitleCell.h"

@implementation AsphaleiaTitleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)reuseIdentifier specifier:(id)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		int width = self.contentView.bounds.size.width;

		CGRect frame = CGRectMake(0, 10, width, 60);
		CGRect subtitleFrame = CGRectMake(0, 45, width, 60);
		CGRect thankSubtitleFrame = CGRectMake(0, 65, width, 60);
		UIColor *subtitleColor = [UIColor colorWithRed:119/255.0f green:119/255.0f blue:122/255.0f alpha:1.0f];

		tweakTitle = [[UILabel alloc] initWithFrame:frame];
		[tweakTitle setNumberOfLines:1];
		[tweakTitle setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:48]];
		[tweakTitle setText:@"Asphaleia 2"];
		[tweakTitle setBackgroundColor:[UIColor clearColor]];
		[tweakTitle setTextColor:[UIColor blackColor]];
		[tweakTitle setTextAlignment:NSTextAlignmentCenter];
		tweakTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		tweakTitle.contentMode = UIViewContentModeScaleToFill;

		tweakSubtitle = [[UILabel alloc] initWithFrame:subtitleFrame];
		[tweakSubtitle setNumberOfLines:1];
		[tweakSubtitle setFont:[UIFont fontWithName:@"HelveticaNeue-Regular" size:18]];
		[tweakSubtitle setText:@"by Sentry and evilgoldfish"];
		[tweakSubtitle setBackgroundColor:[UIColor clearColor]];
		[tweakSubtitle setTextColor:subtitleColor];
		[tweakSubtitle setTextAlignment:NSTextAlignmentCenter];
		tweakSubtitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		tweakSubtitle.contentMode = UIViewContentModeScaleToFill;

		tweakThankSubtitle = [[UILabel alloc] initWithFrame:thankSubtitleFrame];
		[tweakThankSubtitle setNumberOfLines:1];
		[tweakThankSubtitle setFont:[UIFont fontWithName:@"HelveticaNeue-Regular" size:18]];
		[tweakThankSubtitle setText:@"Thank you for your purchase."];
		[tweakThankSubtitle setBackgroundColor:[UIColor clearColor]];
		[tweakThankSubtitle setTextColor:subtitleColor];
		[tweakThankSubtitle setTextAlignment:NSTextAlignmentCenter];
		tweakThankSubtitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		tweakThankSubtitle.contentMode = UIViewContentModeScaleToFill;

		[self addSubview:tweakTitle];
		[self addSubview:tweakSubtitle];
		[self addSubview:tweakThankSubtitle];
	}

	return self;
}

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
  return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AsphaleiaTitleCell" specifier:specifier];
}

- (void)setFrame:(CGRect)frame {
	frame.origin.x = 0;
	[super setFrame:frame];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1{
    return 125.0f;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView {
	return [self preferredHeightForWidth:width];
}

@end
