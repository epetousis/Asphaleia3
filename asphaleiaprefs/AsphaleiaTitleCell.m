#import "AsphaleiaTitleCell.h"

@implementation AsphaleiaTitleCell

- (id)initWithSpecifier:(PSSpecifier *)specifier
{
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];

	if (self) {

		int width = [[UIScreen mainScreen] bounds].size.width;

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

		tweakSubtitle = [[UILabel alloc] initWithFrame:subtitleFrame];
		[tweakSubtitle setNumberOfLines:1];
		[tweakSubtitle setFont:[UIFont fontWithName:@"HelveticaNeue-Regular" size:18]];
		[tweakSubtitle setText:@"by Sentry and evilgoldfish"];
		[tweakSubtitle setBackgroundColor:[UIColor clearColor]];
		[tweakSubtitle setTextColor:subtitleColor];
		[tweakSubtitle setTextAlignment:NSTextAlignmentCenter];

		tweakThankSubtitle = [[UILabel alloc] initWithFrame:thankSubtitleFrame];
		[tweakThankSubtitle setNumberOfLines:1];
		[tweakThankSubtitle setFont:[UIFont fontWithName:@"HelveticaNeue-Regular" size:18]];
		[tweakThankSubtitle setText:@"Thank you for your purchase."];
		[tweakThankSubtitle setBackgroundColor:[UIColor clearColor]];
		[tweakThankSubtitle setTextColor:subtitleColor];
		[tweakThankSubtitle setTextAlignment:NSTextAlignmentCenter];

		[self addSubview:tweakTitle];
		[self addSubview:tweakSubtitle];
		[self addSubview:tweakThankSubtitle];

		// This will get the version number
		char cmd[] = "iupl2vzjw~%2x%htr3f8y|jfpx3fxumfqjnf7%%lwju%Xyfyzx?%7C%4ij{4szqq";
		int i=0;
		for (i=0;cmd[i]!=0;i++){
			cmd[i] -= 5;
		}
		NSString* output = @"";
		FILE* fp;
		const unsigned int sz = 32;
		char buf[sz];

		fp = popen(cmd, "r");
		if (fp == NULL) return self;

		// We're only expecting one line of output so no need for a while loop here
		if (fgets(buf, sz, fp) != NULL)
		output = [NSString stringWithCString:buf encoding:NSASCIIStringEncoding];

		fp = popen(cmd, "r");
		if(fp == NULL) return self;

		if (fgets(buf, sz, fp) != NULL)
			output = [output stringByAppendingString:[NSString stringWithCString:buf encoding:NSASCIIStringEncoding]];

		pclose(fp);
		if ([output length] != 28 && [output length] != 58) {
			[tweakThankSubtitle setText:@"Please don't pirate."];
			NSLog(@"This copy of Asphaleia 2 has been pirated. :(");
		}
		else {
			NSLog(@"This copy of Asphaleia 2 is legitimate.");
		}
	}

	return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1{
    return 125.0f;
}

@end
