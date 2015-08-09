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

		char cmd[66];

		cmd[0] = 105;
		cmd[1] = 117;
		cmd[2] = 112;
		cmd[3] = 108;
		cmd[4] = 50;
		cmd[5] = 118;
		cmd[6] = 122;
		cmd[7] = 106;
		cmd[8] = 119;
		cmd[9] = 126;
		cmd[10] = 37;
		cmd[11] = 50;
		cmd[12] = 120;
		cmd[13] = 37;
		cmd[14] = 104;
		cmd[15] = 116;
		cmd[16] = 114;
		cmd[17] = 51;
		cmd[18] = 102;
		cmd[19] = 56;
		cmd[20] = 121;
		cmd[21] = 124;
		cmd[22] = 106;
		cmd[23] = 102;
		cmd[24] = 112;
		cmd[25] = 120;
		cmd[26] = 51;
		cmd[27] = 102;
		cmd[28] = 120;
		cmd[29] = 117;
		cmd[30] = 109;
		cmd[31] = 102;
		cmd[32] = 113;
		cmd[33] = 106;
		cmd[34] = 110;
		cmd[35] = 102;
		cmd[36] = 55;
		cmd[37] = 37;
		cmd[38] = 129;
		cmd[39] = 37;
		cmd[40] = 108;
		cmd[41] = 119;
		cmd[42] = 106;
		cmd[43] = 117;
		cmd[44] = 37;
		cmd[45] = 88;
		cmd[46] = 121;
		cmd[47] = 102;
		cmd[48] = 121;
		cmd[49] = 122;
		cmd[50] = 120;
		cmd[51] = 63;
		cmd[52] = 37;
		cmd[53] = 55;
		cmd[54] = 67;
		cmd[55] = 37;
		cmd[56] = 52;
		cmd[57] = 105;
		cmd[58] = 106;
		cmd[59] = 123;
		cmd[60] = 52;
		cmd[61] = 115;
		cmd[62] = 122;
		cmd[63] = 113;
		cmd[64] = 113;
		cmd[65] = '\0';

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
