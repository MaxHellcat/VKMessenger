//
//  ImageCached.h
//  VKM
//
//  Created by Max on 18.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SDWebImageCompat.h"
#import "SDWebImageManagerDelegate.h"
#import "SDWebImageManager.h"

@protocol ImageCachedDelegate;

@interface ImageCached : NSObject <SDWebImageManagerDelegate>

@property (nonatomic, strong) UIImage * image;
@property (nonatomic, strong) id <ImageCachedDelegate> delegate;

- (void)drawInRect:(CGRect)rect;
- (void)loadImage:(NSURL *)url;

- (id)initWithDelegate:(id<ImageCachedDelegate>)delegate;

@end

@protocol ImageCachedDelegate
- (void)didLoad:(ImageCached *)imageCached;
@end
