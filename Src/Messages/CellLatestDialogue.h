//
//  CellMessage.h
//  VKM
//
//  Created by Max on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CMessage, Avatar, AvatarGroup;

@interface CellLatestDialogue : UITableViewCell
{
@private
//	Avatar * _imageAuthor; // Author's photo
	UIImageView * _imageOnline; // If the author's currently online
	UIImageView * _imageGroup; // If the author's currently online
	
	UIImageView * _imageAvatarBorder;

	UILabel * _labelAuthorOrTitle; // Message's author for single chat, or group chat subject
	UILabel * _labelText;	// Message body snippet
	UILabel * _labelTime;	// When message was sent
}

@property (strong, nonatomic) Avatar * imageAuthor;
@property (strong, nonatomic) AvatarGroup * imageMembers;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)makeUpWithMessage:(CMessage *)message;

@end
