//
//  AvatarGroup.m
//  VKM
//
//  Created by Max on 18.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AvatarGroup.h"

@implementation AvatarGroup

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		self.backgroundColor = [UIColor clearColor];

		frames[eFrameTopLeft] = CGRectMake(0.0f, 0.0f, 24.0f, 24.0f);
		frames[eFrameTopRight] = CGRectMake(25.0f, 0.0f, 25.0f, 24.0f);
		frames[eFrameBottomLeft] = CGRectMake(0.0f, 25.0f, 24.0f, 25.0f);
		frames[eFrameBottomRight] = CGRectMake(25.0f, 25.0f, 25.0f, 25.0f);
		frames[eFrameLeft] = CGRectMake(0.0f, 0.0f, 24.0f, 50.0f);
		frames[eFrameRight] = CGRectMake(25.0f, 0.0f, 25.0f, 50.0f);

		for (int i=0; i<kImagesMaxCount; ++i)
			images[i] = [[ImageCached alloc] initWithDelegate:self];
    }
    return self;
}

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

	if (imagesCount == 2)
	{
		[images[0] drawInRect:frames[eFrameLeft]];
		[images[1] drawInRect:frames[eFrameRight]];
	}
	else if (imagesCount == 3)
	{
		[images[0] drawInRect:frames[eFrameLeft]];
		[images[1] drawInRect:frames[eFrameTopRight]];
		[images[2] drawInRect:frames[eFrameBottomRight]];
	}
	else if (imagesCount == 4)
	{
		for (short i=0; i<imagesCount; ++i) [images[i] drawInRect:frames[i]];
	}

	CGContextRestoreGState(context);
}

- (void)setImage:(NSString *)name index:(NSInteger)index
{
	ImageCached * imageCached = images[index];

	NSURL * url = [NSURL URLWithString:name];
	[imageCached loadImage:url];

	imagesCount = index+1;

	[self setNeedsDisplay];
}

- (void)didLoad:(ImageCached *)imageCached
{
	[self setNeedsDisplay];
}

@end
