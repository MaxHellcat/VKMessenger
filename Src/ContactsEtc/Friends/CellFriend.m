//
//  CellFriendCell.m
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CellFriend.h"
#import "CUser.h"
#import "UIImageView+WebCache.h" // Images lazy load and caching

@implementation CellFriend

@synthesize imageAvatar;
@synthesize labelName;
@synthesize imageOnline;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
        // Initialization code
    }
    return self;
}

- (void)makeUpWithUser:(CUser *)user
{
	self.labelName.text = [NSString stringWithFormat:@"%@ %@", user.nameFirst, user.nameLast];
	self.imageOnline.hidden = !user.online.boolValue;

	// Author's avatar is lazy loaded and cached
	NSURL * url = [NSURL URLWithString:user.photo];
	[self.imageAvatar setImageWithURL:url placeholderImage:[UIImage imageNamed:@"Avatar_placeholder"]];

//	_imageAvatarBorder.center = CGPointMake(25.0f+8.0f, kCellHeight*0.5f);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
