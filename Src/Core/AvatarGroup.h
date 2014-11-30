//
//  AvatarGroup.h
//  VKM
//
//  Created by Max on 18.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "SDWebImageCompat.h"
//#import "SDWebImageManagerDelegate.h"
//#import "SDWebImageManager.h"
#import "ImageCached.h"


static const short kImagesMaxCount = 4;

enum { eFrameTopLeft=0, eFrameTopRight, eFrameBottomLeft, eFrameBottomRight, eFrameLeft, eFrameRight, eNumFrameTypes };

// Class for fast displaying group chat avatars
// No inheritance and overloading for speed
// TODO: Merge with Avatar
@interface AvatarGroup : UIView <ImageCachedDelegate>
{
@private
	float fw, fh;
	short imagesCount;
	ImageCached * images[kImagesMaxCount];
	CGRect frames[eNumFrameTypes];
}

- (void)setImage:(NSString *)name index:(NSInteger)index;
- (void)didLoad:(ImageCached *)imageCached;

@end
