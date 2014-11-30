//
//  CellMessage.m
//  VKM
//
//  Created by Max on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CellLatestDialogue.h"
#import "QuartzCore/QuartzCore.h"
#import "Constants.h"

#import "CMessage.h"
#import "CUser.h"
#import "CChat.h"

#import "Avatar.h"
#import "Avatar+WebCache.h"

#import "AvatarGroup.h"
#import "AppDelegate.h"


@implementation CellLatestDialogue

@synthesize imageAuthor = _imageAuthor;
@synthesize imageMembers = _imageMembers;

static const CGFloat kCellHeight = 66.0f;


// TODO: Set backcolor according to the cell color (read/unred), turn off transparency!
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// Preload both, use exclusively
		self.imageAuthor = [[Avatar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
		self.imageAuthor.center = CGPointMake(25.0f+8.0f, kCellHeight/2.0f);
		self.imageAuthor.hidden = YES;
		[self addSubview:self.imageAuthor];

		self.imageMembers = [[AvatarGroup alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
		self.imageMembers.center = CGPointMake(25.0f+8.0f, kCellHeight/2.0f);
		self.imageMembers.hidden = YES;
		[self addSubview:self.imageMembers];

		_imageAvatarBorder = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Profile_Avatar"]]; // 50x51 pts
		_imageAvatarBorder.center = CGPointMake(25.0f+8.0f, kCellHeight*0.5f);
		[self addSubview:_imageAvatarBorder];

		_imageOnline = [[UIImageView alloc] initWithFrame:CGRectMake(3.0f, 12.0f, 6.0f, 6.0f)];
		_imageOnline.contentMode = UIViewContentModeCenter;
		[_imageOnline setImage:[UIImage imageNamed:@"Online"]];
		[_imageOnline setHighlightedImage:[UIImage imageNamed:@"Online_selected"]];
		_imageOnline.hidden = YES;
		[self addSubview:_imageOnline];

		_imageGroup = [[UIImageView alloc] initWithFrame:CGRectMake(69.0f, 8.0f, 15.0f, 11.0f)];
		[_imageGroup setImage:[UIImage imageNamed:@"MessagesGroup"]];
		[_imageGroup setHighlightedImage:[UIImage imageNamed:@"MessagesGroup_selected"]];
		_imageGroup.hidden = YES;
		[self addSubview:_imageGroup];

		// First words of the message text or attachment name
		_labelText = [[UILabel alloc] initWithFrame:CGRectMake(69.0f, 33.0f, 235.0f, 21.0f)];
//		_labelText.font = [UIFont systemFontOfSize:14.0f]; // Set later
		_labelText.numberOfLines = 1;
		_labelText.backgroundColor = [UIColor clearColor];
//		_labelText.textColor = [UIColor colorWithRed:0.3333f green:0.3333f blue:0.3333f alpha:1.0f];
		[self addSubview:_labelText];

//		_labelTime = [[UILabel alloc] initWithFrame:CGRectMake(258.0f, 3.0f, 55.0f, 21.0f)];
		_labelTime = [[UILabel alloc] initWithFrame:CGRectMake(245.0f, 3.0f, 67.0f, 21.0f)];
		_labelTime.textAlignment = UITextAlignmentRight;
		_labelTime.adjustsFontSizeToFitWidth = YES;
		_labelTime.font = [UIFont systemFontOfSize:13.0f];
		_labelTime.numberOfLines = 1;
		_labelTime.backgroundColor = [UIColor clearColor];
		_labelTime.textColor = [UIColor colorWithRed:0.2275f green:0.4078f blue:0.5529f alpha:1.0f];
		[self addSubview:_labelTime];

		_labelAuthorOrTitle = [[UILabel alloc] initWithFrame:CGRectMake(69.0f+30.0f, 3.0f, 182.0f-30.0f, 21.0f)]; // For chat subjects
		_labelAuthorOrTitle = [[UILabel alloc] init]; // For chat subjects
		_labelAuthorOrTitle.font = [UIFont boldSystemFontOfSize:14.0f];
		_labelAuthorOrTitle.numberOfLines = 1;
		_labelAuthorOrTitle.backgroundColor = [UIColor clearColor];
		_labelAuthorOrTitle.textColor = [UIColor colorWithRed:0.1333f green:0.1333f blue:0.1333f alpha:1.0f];
		[self addSubview:_labelAuthorOrTitle];
	}

	return self;
}

- (void)makeUpWithMessage:(CMessage *)message
{
	CUser * user = message.user;

	NSDate * date = [NSDate dateWithTimeIntervalSince1970:message.date.intValue];
	[_labelTime setText:[date formatShortTime]];

	if (message.read)
	{
		[UIView animateWithDuration:0.5f delay:0.1f options:UIViewAnimationOptionAllowUserInteraction animations:^
		 {
			 self.backgroundColor = [UIColor whiteColor];
		 } completion:nil];
	}


	// Whenever message has non-empty text body - always display it, display attachment (if any) name only with empty body
	if ([message.text isEqualToString:@""])
	{
		if (message.attachmentType.intValue == eAttachmentTypePhoto)
			[_labelText setText:NSLocalizedString(@"Photo", nil)];
		else if (message.attachmentType.intValue == eAttachmentTypeAudio)
			[_labelText setText:NSLocalizedString(@"Audio", nil)];
		else if (message.attachmentType.intValue == eAttachmentTypeVideo)
			[_labelText setText:NSLocalizedString(@"Video", nil)];
		else
			[_labelText setText:@""];

		_labelText.textColor = [UIColor colorWithRed:0.2f green:0.349f blue:0.5176f alpha:1.0f]; // Blue
		_labelText.font = [UIFont systemFontOfSize:15.0f];
	}
	else
	{
		[_labelText setText:message.text];
		_labelText.textColor = [UIColor colorWithRed:0.3333f green:0.3333f blue:0.3333f alpha:1.0f]; // Gray 
		_labelText.font = [UIFont systemFontOfSize:14.0f];
	}

//	{"mid":16226,"date":1332546837,"out":0,"uid":85813842,"read_state":1,"title":"Простая беседа втроем",
//	"body":"Привет Люба и Максим","chat_id":2,"chat_active":"85813842,168209039","users_count":3,"admin_id":1258287},
//	{"mid":16243,"date":1332563603,"out":1,"uid":168209039,"read_state":0,"title":" ... ","body":"kkkkk"}	

	// For group chat messages, cell avatar consists of 2-4 chat members small avatars
	if (message.chat)
	{
		[_imageGroup setHidden:NO];
		_imageOnline.hidden = YES;

		_labelAuthorOrTitle.text = message.chat.title; // Group chat subject
		_labelAuthorOrTitle.frame = CGRectMake(90.0f, 3.0f, 160.0f, 21.0f);

		// Chat group avatar
		self.imageMembers.hidden = NO;
		self.imageAuthor.hidden = YES;

//		AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
		short index = 0;
		for (CUser * user in message.chat.members)
		{
//			NSLog(@"Making chat cell, user %@", user.nameLast);
//			if (user.uid.intValue != delegate.udUserId.intValue) // Don't draw avatar of myself
//			{
			[self.imageMembers setImage:user.photo index:index++];
			if (index > 3) // Never exceed max allowed number of images per group avatar
				break;
//			}
		}
	}
	else
	{
		[_imageGroup setHidden:YES];
		_labelAuthorOrTitle.text = [NSString stringWithFormat:@"%@ %@", user.nameFirst, user.nameLast];
		CGSize authorSize = [_labelAuthorOrTitle sizeThatFits:CGSizeMake(160.0f, 20.0f)];
		_labelAuthorOrTitle.frame = CGRectMake(69.0f, 3.0f, authorSize.width, 21.0f);

		if ([user.online boolValue]) // For single chat see if message's author is online
		{
			// Place online indicator right after author's surname
			_imageOnline.center = CGPointMake(authorSize.width+75.0f, _imageOnline.center.y); // Online position after auth's name
			_imageOnline.hidden = NO;
		}
		else
		{
			_imageOnline.hidden = YES;
		}

		// Author's avatar is lazy loaded and cached
		self.imageMembers.hidden = YES;
		self.imageAuthor.hidden = NO;

		NSURL * url = [NSURL URLWithString:message.user.photo];
		[self.imageAuthor setImageWithURL:url placeholderImage:[UIImage imageNamed:@"Avatar_placeholder"]];

//		if ([Misc retina])
//			self.imageView.contentScaleFactor = 2.0f;
//			_imageAuthor.contentScaleFactor = 2.0f; // TODO: Test for non-retina
	}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
	[_imageOnline setHighlighted:selected];
	[_imageGroup setHighlighted:selected];
}

@end
