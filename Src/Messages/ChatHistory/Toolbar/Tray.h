//
//  Tray.h
//  VKM
//
//  Created by Max on 12.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Tray : UIScrollView

@property(strong, nonatomic) NSMutableArray * items;

+ (CGFloat)trayHeight;

- (void)addItem:(UIImage *)image;
- (void)removeItems;

@end

@interface Item : UIImageView
{
	UIButton * _buttonClose;
}

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image target:(id)target close:(SEL)close;
- (UIImage *)resizeImage:(UIImage *)image newSize:(CGSize)newSize;

@property (strong, nonatomic) id target;
@property (nonatomic) SEL didClose;

@property (strong, nonatomic) UIImage * originalImage; // To store full-sized image from Picker

@end