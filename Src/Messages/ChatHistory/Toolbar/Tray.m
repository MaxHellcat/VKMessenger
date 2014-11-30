//
//  Tray.m
//  VKM
//
//  Created by Max on 12.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Tray.h"

@implementation Tray

@synthesize items = _items;

static const CGFloat kTrayHeight = 100;
static const CGFloat kItemSize = 70;
static const CGFloat kItemOffset = 20.0f;

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
    if (self)
	{
		self.backgroundColor = [UIColor clearColor];
		[self setScrollEnabled:YES];
		[self setShowsHorizontalScrollIndicator:NO];
		[self setShowsVerticalScrollIndicator:NO];

//		[self setUserInteractionEnabled:YES];

		_items = [[NSMutableArray alloc] init];

//		[self addItem];
    }
    return self;
}

- (void)addItem:(UIImage *)image
{
//	NSLog(@"Adding item, count %i", _items.count);

	Item * item = [[Item alloc] initWithFrame:CGRectNull
										image:image
										target:self
										close:@selector(touchClose:)];
	item.tag = _items.count;
	[self addSubview:item];

	[_items addObject:item];

	float offset = _items.count*kItemSize + _items.count*kItemOffset + kItemOffset;
	[self setContentSize:CGSizeMake(offset, kTrayHeight)]; // Adjust tray content size
}

- (void)removeItems
{
	for (short i=0; i<_items.count; ++i)
	{
		Item * item = [_items objectAtIndex:i];
		[item removeFromSuperview];
	}

	[_items removeAllObjects];

}

- (void)touchClose:(id)item
{
	[_items removeObject:item];

//	NSLog(@"Item removed, count %i", _items.count);

	for (short i=0; i<_items.count; ++i)
	{
		Item * item = [_items objectAtIndex:i];
		[item setTag:i];
		[item setNeedsLayout]; // Ask item to realign
	}

	// Adjust scrolling size
	float offset = _items.count*kItemSize + _items.count*kItemOffset + kItemOffset;
	[self setContentSize:CGSizeMake(offset, kTrayHeight)]; // Adjust tray content size
}

- (void)dealloc
{
	self.items = nil;
}

+ (CGFloat)trayHeight
{
	return kTrayHeight;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end


@implementation Item

@synthesize target=_target;
@synthesize didClose;
@synthesize originalImage=_originalImage;

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image target:(id)target close:(SEL)close
{
	self = [super initWithFrame:CGRectMake(0.0f, 0.0f, kItemSize, kItemSize)];
	if (self)
	{
		[self setUserInteractionEnabled:YES];
		self.target = target;
		self.didClose = close;

		_originalImage = image; // Store full-sized image

//		NSLog(@"Item init, image size %@", NSStringFromCGSize(image.size));


//		float k = fabs(image.size.width / image.size.height);
/*		CGSize size;
		if (image.size.width < image.size.height)
			size = CGSizeMake(kItemSize*k, kItemSize);
		else
			size = CGSizeMake(kItemSize, kItemSize*k);

		UIImage * smallImage = [self resizeImage:image newSize:size];
*/

		self.contentMode = UIViewContentModeScaleAspectFit;
		self.image = image;

		_buttonClose = [UIButton buttonWithType:UIButtonTypeCustom];
		[_buttonClose addTarget:self action:@selector(didClose:) forControlEvents:UIControlEventTouchUpInside];
		[_buttonClose setImage:[UIImage imageNamed:@"Delete_attach"] forState:UIControlStateNormal];
		_buttonClose.contentMode = UIViewContentModeCenter;
		_buttonClose.bounds = CGRectMake(0.0f, 0.0f, 50.0f, 50.0f);
		_buttonClose.center = CGPointMake(kItemSize, 0.0f);
		[self addSubview:_buttonClose];
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	float offset = (self.tag)*kItemSize + (self.tag)*kItemOffset + kItemOffset;
	CGRect frame = CGRectMake(offset, kTrayHeight*0.5f-kItemSize*0.5f, kItemSize, kItemSize);

	// Smoothly animate with nice delays
	[UIView animateWithDuration:0.25f delay:(self.tag)*0.1f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
								{
									self.frame = frame;
								}
					 completion:nil];
}

- (void)didClose:(id)sender
{
	[self removeFromSuperview];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[self.target performSelector:self.didClose withObject:self];
#pragma clang diagnostic pop
}

// When touch imageView
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"Item %i", self.tag);

}

- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize
{
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
	
    CGContextConcatCTM(context, flipVertical);  
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
	
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
	
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();    
	
    return newImage;
}

- (void)dealloc
{
	_buttonClose = nil;
}

@end