//
//  Avatar.m
//  VKM
//
//  Created by Max on 18.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Avatar.h"

@implementation Avatar

@synthesize image;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);

	static float ovalWidth = 10.0f, ovalHeight = 10.0f;

    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh*0.5f);
    CGContextAddArcToPoint(context, fw, fh, fw*0.5f, fh, 1.0f);
    CGContextAddArcToPoint(context, 0.0f, fh, 0.0f, fh*0.5f, 1.0f);
    CGContextAddArcToPoint(context, 0.0f, 0.0f, fw*0.5f, 0.0f, 1.0f);
    CGContextAddArcToPoint(context, fw, 0.0f, fw, fh*0.5f, 1.0f);
    CGContextClosePath(context);
    CGContextRestoreGState(context);

	CGContextClip(context);
	[self.image drawInRect:rect];
	CGContextRestoreGState(context);
}

- (void)dealloc
{
	self.image = nil;
}

@end
