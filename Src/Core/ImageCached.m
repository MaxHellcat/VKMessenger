//
//  ImageCached.m
//  VKM
//
//  Created by Max on 18.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageCached.h"
#import "AvatarGroup.h"

@implementation ImageCached

@synthesize image=_image;
@synthesize delegate=_delegate;

- (id)initWithDelegate:(id<ImageCachedDelegate>)delegate
{
    self = [super init];
    if (self)
	{
		self.delegate = delegate;
    }
    return self;
}

- (void)drawInRect:(CGRect)rect
{
	[self.image drawInRect:rect];
}

- (void)loadImage:(NSURL *)url
{
    SDWebImageManager * manager = [SDWebImageManager sharedManager];

    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];

//	[self setImage:placeholder];

    if (url)
    {
        [manager downloadWithURL:url delegate:self options:0];
    }
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
{
    [self setImage:image];
	[self.delegate didLoad:self];
}

@end
