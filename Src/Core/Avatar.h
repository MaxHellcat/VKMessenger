//
//  Avatar.h
//  VKM
//
//  Created by Max on 18.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// Class for fast displaying loaded in background, cached, rounded images
// TODO: Switch UIImage to ImageCached
@interface Avatar : UIView
{
@private
	float fw, fh;
}

@property (strong, nonatomic) UIImage * image;

- (id)initWithFrame:(CGRect)frame;

@end
