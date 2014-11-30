//
//  Settings.h
//  VKM
//
//  Created by Max on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Settings : UIViewController


@property (strong, nonatomic) IBOutlet UIImageView *imageAvatar;
@property (strong, nonatomic) IBOutlet UILabel *labelName;



@property (strong, nonatomic) IBOutlet UIButton *touchChangePhoto;
@property (strong, nonatomic) IBOutlet UIButton *touchLogout;

@end
