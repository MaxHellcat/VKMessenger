//
//  CellDialogue.m
//  VKM
//
//  Created by Max on 3/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CellChatHistory.h"
#import "AppDelegate.h"
#import "CMessage.h"
#import "CUser.h"
#import "CAttachment.h"
#import "CChat.h"
#import "Constants.h"
#import "UIImageView+WebCache.h" // Images lazy load and caching
#import "Avatar.h"
#import "Avatar+WebCache.h"
#import "VKReq.h"


@implementation CellChatHistory

@synthesize avatarChatMember;

static const NSInteger kMessageFontSize = 15;
static const CGFloat kMessageTextMinHeight = 50.0f;
static const CGFloat kMessageTextMaxHeight = 1000.0f;
static const CGFloat kMessagesGap = 25.0f; // How far messages from each other, vertically

static const float kMessageCapHeight = 5.0f;
static const float kMessageCapWidth = 15.0f;
static const CGFloat kMessageContentMaxWidth = 200.0f; // Max width of content in bubble, applies to text/image/geo
static const CGFloat kMessageImageMaxHeight = 100.0f; // Max width of content in bubble, applies to text/image/geo


// Used by Messages table controller to work out the cell's height
+ (CGFloat)cellHeightWithMessage:(CMessage *)message
{
	// Calculate cell height according to text size, attachments count, etc
	if (message.attachmentType.intValue == eAttachmentMissing)
	{
		CGSize size = [message.text sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize] constrainedToSize:CGSizeMake(kMessageContentMaxWidth, kMessageTextMaxHeight)];
		return MAX(size.height+kMessagesGap, kMessageTextMinHeight); // Maximum between actual cell height and minimal possible
	}
	else //if (message.attachmentType.intValue == eAttachmentTypePhoto) // TODO: In fact we should test all attachments, cos we always show photo
	{
		CGSize textSize = [message.text sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize] constrainedToSize:CGSizeMake(kMessageContentMaxWidth, kMessageTextMaxHeight)];
		float imageHeight = kMessageImageMaxHeight;

		float attStringHeight = 0;
		if (message.attachments.count > 1)
			attStringHeight = kMessageFontSize;

		float cellHeight = kMessageCapHeight+textSize.height+kMessageCapHeight+imageHeight+kMessageCapHeight+attStringHeight+kMessageCapHeight;

		return cellHeight+kMessagesGap;
	}

}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
		self.selectionStyle  = UITableViewCellSelectionStyleNone;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight;

		// Message text
		_labelText = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kMessageContentMaxWidth, 1.0f)];
		_labelText.font = [UIFont systemFontOfSize:kMessageFontSize];
		_labelText.numberOfLines = 0;
		_labelText.lineBreakMode = UILineBreakModeWordWrap;
		_labelText.backgroundColor = [UIColor clearColor];
//		_labelText.backgroundColor = [UIColor colorWithRed:0.9490f green:0.9490f blue:0.9490f alpha:1.0f];
//		_labelText.userInteractionEnabled = YES;

		// Attachment image
		_imageAttachment = [[UIImageView alloc] init];
		_imageChatMember = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Avatar_Round"]];

		// Preload both, use exclusively
		self.avatarChatMember = [[Avatar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
//		self.avatarChatMember.center = CGPointMake(25.0f+8.0f, kCellHeight/2.0f);
//		self.avatarChatMember.hidden = YES;
//		[_imageChatMember addSubview:self.avatarChatMember];
		


		// Info string, used to indicate about more attachments
//		_labelInfo = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kMessageContentMaxWidth, 1.0f)];
		_labelInfo = [[UILabel alloc] init];
		_labelInfo.font = [UIFont systemFontOfSize:kMessageFontSize];
		_labelInfo.numberOfLines = 1;
		_labelInfo.lineBreakMode = UILineBreakModeWordWrap;
		_labelInfo.backgroundColor = [UIColor clearColor];
//		_labelInfo.backgroundColor = [UIColor colorWithRed:0.9490f green:0.9490f blue:0.9490f alpha:1.0f];
		

		// Bubble image
		// TODO: Deprecated in iOS 5.0. Deprecated. Use the resizableImageWithCapInsets: instead
		// Create stretchable BG image
		_imageBubble = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage * image = [[UIImage imageNamed:@"Grey_Bubble.png"] stretchableImageWithLeftCapWidth:24.0f topCapHeight:13.0f]; // TODO: Rename to Gray..
//		UIImage * imageTouched = [[UIImage imageNamed:@"Grey_Bubble_Selected.png"] stretchableImageWithLeftCapWidth:24.0f topCapHeight:13.0f]; // TODO: Rename to Gray..
		[_imageBubble setBackgroundImage:image forState:UIControlStateNormal];
//		[_imageBubble setBackgroundImage:imageTouched forState:UIControlStateHighlighted];
		[_imageBubble addTarget:self action:@selector(touchButtonMessage:) forControlEvents:UIControlEventTouchUpInside];

		// Message creation date
		_labelTime = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kMessageContentMaxWidth, 1.0f)];
		_labelTime.font = [UIFont systemFontOfSize:kMessageFontSize];
		_labelTime.textColor = [UIColor colorWithRed:0.6078f green:0.6471f blue:0.7059f alpha:1.0f];
		_labelTime.shadowColor = [UIColor whiteColor];
		_labelTime.shadowOffset = CGSizeMake(0.0f, 0.5f);
		_labelTime.numberOfLines = 0;
		_labelTime.lineBreakMode = UILineBreakModeWordWrap;
		_labelTime.backgroundColor = [UIColor clearColor];

		[self.contentView addSubview:_imageBubble];
		[self.contentView addSubview:_labelText]; // Not part of bubble, as text is flipped for incoming messages
		[self.contentView addSubview:_imageAttachment];
		[self.contentView addSubview:_imageChatMember];
		[self.contentView addSubview:_labelInfo];
		[self.contentView addSubview:_labelTime];
		[self.contentView addSubview:self.avatarChatMember];

		// Date formatter preload
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"HH:mm" options:0 locale:[NSLocale currentLocale]]];
	}

	return self;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { 
//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
- (void)setMessage:(CMessage *)message
{
	// Line-up message elements
	//
	float contentHeight = kMessageCapHeight;
	float contentWidth = 0.0f;
	float contentOffset = 0.0f; // Specifies content offset, when displaying icons of group chat members

	// TODO: Do this only for unread please
	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
	if (/*!message.read &&*/ message.from_id.intValue != delegate.udUserId.intValue) // Mark incoming messages as read, cos we're seeing'em
	{
		[VKReq method:@"messages.markAsRead"
			 paramOne:@"mids" valueOne:message.mid.stringValue 
			   target:self action:@selector(didMarkAsRead:) fail:nil];
	}

	if (message.read)
	{
		[UIView animateWithDuration:0.5f delay:0.1f options:UIViewAnimationOptionAllowUserInteraction animations:^
		 {
			 self.backgroundColor = [UIColor clearColor];
		 } completion:nil];
	}

	_imageChatMember.hidden = YES;
	_imageAttachment.hidden = YES;
	self.avatarChatMember.hidden = YES;

	BOOL isChat = NO;
	if (message.chat)
	{
		isChat = YES;
		contentOffset = 40.0f;
		_imageChatMember.hidden = NO;
		self.avatarChatMember.hidden = NO;
	}

	// Message text always first on top
	CGSize labelSize = [message.text sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize]
								constrainedToSize:CGSizeMake(kMessageContentMaxWidth, kMessageTextMaxHeight)];
	_labelText.frame = CGRectMake(contentOffset+kMessageCapWidth, kMessageCapHeight, labelSize.width, labelSize.height);
	_labelText.text = message.text;

	contentWidth = kMessageCapWidth+_labelText.frame.size.width;
	contentHeight += _labelText.frame.size.height+kMessageCapHeight;

	// For messages with attachments, if first attach is photo show the photo right underneath the text
	// TODO: Enhance to show photo if it just exists in att set, but this will be slower
	NSInteger attachCount = message.attachments.count;
	if (message.attachmentType.intValue == eAttachmentTypePhoto)
	{
		for (CAttachment * attachment in message.attachments)
		{
			if (attachment.type.intValue == eAttachmentTypePhoto)
			{
				NSURL * url = [NSURL URLWithString:attachment.src];
//				[_imageAttachment setImageWithURL:url placeholderImage:[UIImage imageNamed:@"src.jpeg"]];
				[_imageAttachment setImageWithURL:url];
			}
		}

		_imageAttachment.hidden = NO;
		_imageAttachment.frame = CGRectMake(contentOffset+kMessageCapWidth,
											contentHeight,
//											image.size.width,
											kMessageContentMaxWidth,
											kMessageImageMaxHeight);

		contentWidth = MAX(contentWidth, kMessageCapWidth+_imageAttachment.frame.size.width);
		contentHeight += kMessageImageMaxHeight+kMessageCapHeight;

		if (message.attachments.count > 1)
		{
			// If there're other attachments, per design, just display brief info below the photo
			// TODO: Localize
			//_labelInfo.text = [NSString stringWithFormat:@"and %i more...", attachCount - 1];
			_labelInfo.text = [NSString stringWithFormat:@"еще вложения...", attachCount - 1];
			_labelInfo.frame = CGRectMake(contentOffset+kMessageCapWidth,
										  contentHeight,
										  100.0f, // Actually info label text width
										  kMessageFontSize);

			contentWidth = MAX(contentWidth, 100.0f);
			contentHeight += kMessageFontSize+kMessageCapHeight;
		}
	}
	else if (message.attachmentType.intValue == eAttachmentTypeAudio || message.attachmentType.intValue == eAttachmentTypeVideo)
	{
		_labelInfo.text = [NSString stringWithFormat:@"сообщение с вложениями..", attachCount];
		_labelInfo.frame = CGRectMake(contentOffset+kMessageCapWidth,
									  contentHeight,
									  200.0f, // Actually info label text width
									  kMessageFontSize);

		contentWidth = MAX(contentWidth, 200.0f);
		contentHeight += kMessageFontSize+kMessageCapHeight;
	}
	else // if (message.attachmentType.intValue == eAttachmentMissing)
	{
		_labelInfo.frame = CGRectZero;
	}
	
	// Resize bubble to conform to new size
	_imageBubble.frame = CGRectMake(contentOffset, 0.0f,
									contentWidth+kMessageCapWidth,
									contentHeight);

	// Message date sided to bubbble
	// NSDate * date = [NSDate dateWithTimeIntervalSince1970:[[message objectForKey:@"date"] doubleValue]];
	NSDate * date = [NSDate dateWithTimeIntervalSince1970:[message.date doubleValue]];
	NSString * time = [_dateFormatter stringFromDate:date];

	static const float timeOffset = 8.0f; // Position of time relative to text
	CGSize timeSize = [time sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize] constrainedToSize:CGSizeMake(kMessageContentMaxWidth, kMessageTextMaxHeight)];
	_labelTime.frame = CGRectMake(contentOffset+_imageBubble.frame.size.width+timeOffset,
								  _imageBubble.frame.origin.y+_imageBubble.frame.size.height-kMessageCapHeight-kMessageFontSize,
								  timeSize.width,
								  timeSize.height);
	_labelTime.text = time;
	
	// Flip bubble and place at right for outgoing messages
	_imageBubble.transform = CGAffineTransformIdentity; // Reset position
	if (message.from_id.intValue == delegate.udUserId.intValue)
	{
		_imageBubble.transform = CGAffineTransformMakeScale(-1.0f, 1.0f);

		_imageBubble.center = CGPointMake(self.frame.size.width-contentOffset-_imageBubble.frame.size.width/2.0f, _imageBubble.center.y);
		_labelText.center = CGPointMake(self.frame.size.width-contentOffset-_imageBubble.frame.size.width/2.0f, _labelText.center.y);

		if (message.attachmentType.intValue == eAttachmentTypePhoto)
			_imageAttachment.center = CGPointMake(self.frame.size.width-contentOffset-_imageBubble.frame.size.width/2.0f, _imageAttachment.center.y);

		_labelTime.center = CGPointMake(_imageBubble.frame.origin.x-_labelTime.frame.size.width/2.0f-timeOffset, _labelTime.center.y);

		if (isChat)
		{
			_imageChatMember.center = CGPointMake(self.frame.size.width-20.0f, contentHeight-10.0f);
			self.avatarChatMember.center = _imageChatMember.center;
			NSURL * url = [NSURL URLWithString:message.user.photo];
			[self.avatarChatMember setImageWithURL:url];
		}
	}
	else
	{
		if (isChat)
		{
			_imageChatMember.center = CGPointMake(20.0f, contentHeight-10.0f);
			self.avatarChatMember.center = _imageChatMember.center;
			NSURL * url = [NSURL URLWithString:message.user.photo];
			[self.avatarChatMember setImageWithURL:url];
		}
	}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)didMarkAsRead:(VKReq *)req
{
//	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
//	[delegate setUnreadCount:delegate.udUnreadCount.intValue-1];
}

- (void)touchButtonMessage:(id)sender
{
	UIImage * imageTouched = [[UIImage imageNamed:@"Grey_Bubble_Selected"] stretchableImageWithLeftCapWidth:24.0f topCapHeight:13.0f]; // TODO: Rename to Gray..
	[_imageBubble setBackgroundImage:imageTouched forState:UIControlStateNormal];

	[self becomeFirstResponder];

	UIMenuController * menu = [UIMenuController sharedMenuController];

	UIMenuItem * item1 = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copyMessage:)];
	UIMenuItem * item2 = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteMessage:)];

	[menu setMenuItems:[NSArray arrayWithObjects:item1, item2, nil]];

	[menu setTargetRect:self.superview.frame inView:self];

	[menu setMenuVisible:YES animated:YES];
}

- (void)copyMessage:(id)sender
{
	UIImage * imageTouched = [[UIImage imageNamed:@"Grey_Bubble"] stretchableImageWithLeftCapWidth:24.0f topCapHeight:13.0f]; // TODO: Rename to Gray..
	[_imageBubble setBackgroundImage:imageTouched forState:UIControlStateNormal];

}

- (void)deleteMessage:(id)sender
{
	UIImage * imageTouched = [[UIImage imageNamed:@"Grey_Bubble"] stretchableImageWithLeftCapWidth:24.0f topCapHeight:13.0f]; // TODO: Rename to Gray..
	[_imageBubble setBackgroundImage:imageTouched forState:UIControlStateNormal];
}

- (BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
	if (action == @selector(copyMessage:))
    {
		return YES; // logic here for context menu show/hide
    }

    if (action == @selector(deleteMessage:))
    {
		return YES;  // logic here for context menu show/hide
    }

	return [super canPerformAction: action withSender: sender];
}


- (BOOL)canBecomeFirstResponder
{
	return YES;
}

@end
