//
//  RedPin.m
//  VKM
//
//  Created by Max on 19.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RedPin.h"

@implementation RedPin

//- (id)initWithFrame:(CGRect)frame
- (id)init
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 20.0f, 20.0f)];
    if (self)
	{
//		UIImage * image = [[UIImage imageNamed:@"NotifyRequest"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:5.0f];
		UIImage * image = [UIImage imageNamed:@"NotifyRequest"];

		[self setImage:image];

//		self.frame = ;
    }
    return self;
}


@end
