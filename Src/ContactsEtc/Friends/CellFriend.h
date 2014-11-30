//
//  CellFriendCell.h
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CUser;

@interface CellFriend : UITableViewCell

- (void)makeUpWithUser:(CUser *)user;

@property (strong, nonatomic) IBOutlet UIImageView * imageAvatar;

@property (strong, nonatomic) IBOutlet UILabel * labelName;

@property (strong, nonatomic) IBOutlet UIImageView *imageOnline;


@end
