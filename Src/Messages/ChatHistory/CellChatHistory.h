//
//  CellDialogue.h
//  VKM
//
//  Created by Max on 3/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Bubble, CMessage, Avatar;

@interface CellChatHistory : UITableViewCell
{
@private
	UILabel * _labelText;
	UILabel * _labelTime;
	UIButton * _imageBubble; // Stretchable bubble image
	UIImageView * _imageAttachment; // Photo attachment image
	UIImageView * _imageChatMember; // Photo attachment image
	
	UILabel * _labelInfo;

	NSDateFormatter * _dateFormatter;
}

@property (strong, nonatomic) Avatar * avatarChatMember;

+ (CGFloat)cellHeightWithMessage:(CMessage *)message;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)setMessage:(CMessage *)message;

@end
