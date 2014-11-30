//
//  ChatHistory+Network.m
//  VKM
//
//  Created by Max on 08.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatHistory.h"
#import "VKReq.h"
#import "JSONKit.h"
#import "Cache.h"

#import "CUser.h"
#import "CChat.h"

#import "Tray.h"

#import "AppDelegate.h"

#import "Constants.h" // Only for testing post, remove in release


@implementation ChatHistory (Network)

#pragma mark -
#pragma mark Network interaction


- (void)readChatHistory
{
	[self.waitIndicator startAnimating];

	if (self.isChat)
	{
		[VKReq getMethod:@"messages.getHistory"
			  withParams:[NSString stringWithFormat:@"chat_id=%i&count=%i", self.message.chat.cid.intValue, 20] // Default count appears to be 20
				  target:self
				  action:@selector(didGetChatHistory:)
					fail:@selector(didGetChatHistoryFail:)];
	}
	else
	{
		[VKReq getMethod:@"messages.getHistory"
			  withParams:[NSString stringWithFormat:@"uid=%i&count=%i", self.user.uid.intValue, 20] // Default count appears to be 20
				  target:self
				  action:@selector(didGetChatHistory:)
					fail:@selector(didGetChatHistoryFail:)];
	}
}

//
// Cache refreshing magic for chat history
//
// Principles:
// Cache only first 20 messages
// Cache only first 20 messages per user
// User optionally has message(s)
//
// TODO: We show messages already deleted from server externally!
- (void)didGetChatHistory:(VKReq *)req
{
	NSMutableDictionary * data = [req.responseData mutableObjectFromJSONData];

	if ([data objectForKey:@"error"]) // Check for error response
	{
//		NSDictionary * errorDict = [data objectForKey:@"error"];
//		NSInteger errorCode = [[errorDict objectForKey:@"error_code"] integerValue];
//		NSString * errorMsg = [errorDict objectForKey:@"error_msg"];
		// NSLog(@"Error response, error_code: %i, error_msg: %@ ", errorCode, errorMsg);
		return ;
	}

	NSMutableArray * remoteMessages = [data objectForKey:@"response"];
	[remoteMessages removeObjectAtIndex:0];  // Strip first elem (total number of messages)

	// Pickup current user from the cache to relate to possibly new messages
	NSArray * users = [[Cache instance] fetch:@"CUser"
									  predicate:[NSPredicate predicateWithFormat:@"(uid == %i)", self.user.uid.intValue]];

	for (NSMutableDictionary * remoteMessage in remoteMessages)
	{
		NSInteger mid = [[remoteMessage objectForKey:@"mid"] integerValue];

		// Check if such message exists in cache for such user
		NSArray * fetchedArray = [[Cache instance] fetch:@"CMessage"
											   predicate:[NSPredicate predicateWithFormat:@"(mid == %i)", mid]]; // Message id is enough
//												 predicate:[NSPredicate predicateWithFormat:@"(mid == %i and user.uid == %i)", mid, self.message.user.uid.intValue]];

		if (self.isChat)
		{
			NSInteger uid = [[remoteMessage objectForKey:@"from_id"] integerValue];
			CUser * user = [[Cache instance] userById:uid];

			if (fetchedArray.count) // Message found in cache, update it
				[[Cache instance] updateMessage:[fetchedArray objectAtIndex:0] withRemoteMessage:remoteMessage latest:NO];
			else // New message, add to cache
				[[Cache instance] addMessageChatHistory:remoteMessage forUser:user forChat:self.message.chat];
		}
		else
		{
			if (fetchedArray.count) // Message found in cache, update it
				[[Cache instance] updateMessage:[fetchedArray objectAtIndex:0] withRemoteMessage:remoteMessage latest:NO];
			else // New message, add to cache
				[[Cache instance] addMessageChatHistory:remoteMessage forUser:[users objectAtIndex:0] forChat:self.message.chat];
		}
	}

	[self.waitIndicator stopAnimating];
	
	// TODO: Why do we always call this even though we might not have pulled the refresh
	[_refreshView dataSourceDidFinishLoading:self.tableView];
}

// Handle failed server requests, e.g request timed out
- (void)didGetChatHistoryFail:(VKReq *)req
{
	[self.waitIndicator stopAnimating];
	[_refreshView dataSourceDidFinishLoading:self.tableView];
}

// TODO: Now we use mechanizm of getting all messages from the LongPoll event, but for outgoing must create before
- (IBAction)touchSend:(id)sender
{
	// NSLog(@"Send message, att count: %i", self.toolbar.tray.items.count);
	
	// Scroll to the bottom, to show the newest messages
//	NSInteger n = [[[self.messages sections] objectAtIndex:0] numberOfObjects];
	// NSLog(@"SendMessage, rows %i", n);

	// If message has photos, we should first upload them to server
	if (self.toolbar.tray.items.count)
	{
		// First, obtain name of upload server
		[VKReq getMethod:@"photos.getMessagesUploadServer"
			  withParams:nil
				  target:self
				  action:@selector(didGetMessagesUploadServer:)
					fail:@selector(didGetMessagesUploadServerFail:)];
	}
	else if (![self.toolbar.textField.text isEqualToString:@""]) // For no attachments, message text is required
	{
		// TODO: Anything to strip?
		NSString * text = self.toolbar.textField.text;

		// TODO: Merge into one
		if (self.isChat)
		{
			[VKReq method:@"messages.send"
				 paramOne:@"chat_id" valueOne:[NSString stringWithFormat:@"%i", self.message.chat.cid.intValue]
				 paramTwo:@"message" valueTwo:text
				   target:self action:@selector(didSendMessage:) fail:@selector(didSendMessageFail:)];
		}
		else
		{
			[VKReq method:@"messages.send"
				 paramOne:@"uid" valueOne:[NSString stringWithFormat:@"%i", self.user.uid.intValue]
				 paramTwo:@"message" valueTwo:text
				   target:self action:@selector(didSendMessage:) fail:@selector(didSendMessageFail:)];
		}

		self.toolbar.textField.text = @"";
	}
}

- (void)didGetMessagesUploadServerFail:(VKReq *)req
{
	// NSLog(@"WARNING: Failed to obtain upload server, message send failed");
}

- (void)didGetMessagesUploadServer:(VKReq *)req
{
	NSDictionary * data = [req.responseData mutableObjectFromJSONData];
	NSString * url = [[data objectForKey:@"response"] objectForKey:@"upload_url"];
	
	// TODO: Support multiple attaches
	// Second, actually upload photo to server
	UIImage * image = [[self.toolbar.tray.items objectAtIndex:0] originalImage];
	[VKReq postPhoto:url withImage:image target:self action:@selector(didGetPostPhoto:)
				fail:@selector(didGetPostPhotoFail:)];
}

- (void)didGetPostPhotoFail:(VKReq *)req
{
	// NSLog(@"WARNING: Failed to upload photo on server, message send failed");
}

- (void)didGetPostPhoto:(VKReq *)req
{
	NSDictionary * data = [req.responseData mutableObjectFromJSONData];

	NSNumber * server = [data objectForKey:@"server"];
	NSString * photo = [data objectForKey:@"photo"];
	NSString * hash = [data objectForKey:@"hash"];
	
//	{"server":11164,"photo":"[{\"photo\":\"8609348f15:z\",\"sizes\":[[\"s\",\"11164287\",\"11\",\"EuVU94q1is0\",50,75],[\"m\",\"11164287\",\"12\",\"AxlUuOkXQHM\",87,130],[\"x\",\"11164287\",\"13\",\"1vd4sz_V9CY\",403,604],[\"y\",\"11164287\",\"14\",\"MnzfjfG-eps\",538,807],[\"z\",\"11164287\",\"15\",\"5y_sgxDYRCU\",640,960],[\"o\",\"11164287\",\"16\",\"r1svjxRGCuQ\",130,195],[\"p\",\"11164287\",\"17\",\"xjdXAM-wvBU\",200,300],[\"q\",\"11164287\",\"18\",\"_AlCIYx4ygY\",320,480],[\"r\",\"11164287\",\"19\",\"hWi-QYq_QGA\",510,765]],\"kid\":\"a60fa16333ddeb62a922ea6dca9d4e30\"}]","hash":"5b9d29b635851729c221ead5b9cc7253"}

	[VKReq method:@"photos.saveMessagesPhoto"
		 paramOne:@"server" valueOne:server.stringValue
		 paramTwo:@"photo" valueTwo:photo
	   paramThree:@"hash" valueThree:hash
		   target:self action:@selector(didSaveMessagesPhoto:) fail:@selector(didSaveMessagesPhotoFail:)];

	
/* OLD
	[VKReq method:@"photos.saveMessagesPhoto"
		 paramOne:@"server" valueOne:server
		 paramTwo:@"photo" valueTwo:photo
	   paramThree:@"hash" valueThree:hash
		   target:self action:@selector(didSaveMessagesPhoto:) fail:@selector(didSaveMessagesPhotoFail:)];
*/
/*
	// Third, save photo using info provided in previous response
	AppDelegate * del = [[UIApplication sharedApplication] delegate];

	// Don't encode url for MD5 calculation
	NSString * urlMD5 = [NSString stringWithFormat:@"/method/photos.saveMessagesPhoto?server=%@&photo=%@&hash=%@&access_token=%@", server, photo, hash, del.udAccessToken];
	NSString * strMD5 = [NSString stringWithFormat:@"%@%@", urlMD5, del.udSecret];

	// But encode for sending req to the server
	NSString * url = [NSString stringWithFormat:@"/method/photos.saveMessagesPhoto?server=%@&photo=%@&hash=%@&access_token=%@",
					   [server urlEncodeUsingEncoding:NSUTF8StringEncoding],
					   [photo urlEncodeUsingEncoding:NSUTF8StringEncoding],
					   [hash urlEncodeUsingEncoding:NSUTF8StringEncoding],
					  del.udAccessToken];

	NSString * finalUrl = [NSString stringWithFormat:@"%@%@%@&sig=%@", kPrefixHttp, kVKApiHost, url, [strMD5 MD5]];

	[[[VKReq alloc] initWithTarget:self action:@selector(didSaveMessagesPhoto:) fail:@selector(didSaveMessagesPhotoFail::)] get:finalUrl];
*/
}

- (void)didSaveMessagesPhotoFail:(VKReq *)req
{
	// NSLog(@"WARNING: Failed to save photo on server, message send failed");
}

- (void)didSaveMessagesPhoto:(VKReq *)req
{
//	{"response":[{"pid":281613807,"id":"photo1258287_281613807","aid":-3,"owner_id":1258287,"src":"http:\/\/cs10241.userapi.com\/u1258287\/-3\/m_c66dabf3.jpg","src_big":"http:\/\/cs10241.userapi.com\/u1258287\/-3\/x_09acb54c.jpg","src_small":"http:\/\/cs10241.userapi.com\/u1258287\/-3\/s_fb369d8e.jpg","width":130,"height":98,"text":"","created":1334198659}]}

	NSDictionary * data = [req.responseData mutableObjectFromJSONData];

	// Now we have complete info to send a message
	NSArray * arr = [data objectForKey:@"response"];
	NSString * sId = [[arr objectAtIndex:0] objectForKey:@"id"];

	// TODO: Merge into one
	if (self.isChat)
	{
		[VKReq method:@"messages.send"
			 paramOne:@"chat_id" valueOne:[NSString stringWithFormat:@"%i", self.message.chat.cid.intValue]
			 paramTwo:@"message" valueTwo:self.toolbar.textField.text // Can be empty
		   paramThree:@"attachment" valueThree:sId // Not attachments, or maybe because only one for now
			   target:self action:@selector(didSendMessage:) fail:@selector(didSendMessageFail:)];
	}
	else
	{
		[VKReq method:@"messages.send"
			 paramOne:@"uid" valueOne:[NSString stringWithFormat:@"%i", self.user.uid.intValue]
			 paramTwo:@"message" valueTwo:self.toolbar.textField.text // Can be empty
		   paramThree:@"attachment" valueThree:sId // Not attachments, or maybe because only one for now
			   target:self action:@selector(didSendMessage:) fail:@selector(didSendMessageFail:)];
	}
}

- (void)didSendMessageFail:(VKReq *)req
{
	// // NSLog(@"WARNING: Failed to send message");
}

/*
 TODO: Handle errors:
 1 Unknown error occurred.
 2 Application is disabled. Enable your application or use test mode.
 4 Incorrect signature.
 5 User authorization failed.
 6 Too many requests per second.
 7 Permission to perform this action is denied by user
 14 Captcha is needed
 100 One of the parameters specified was missing or invalid
 */
// We assume here that newly created message will be picked up by LongPoll and brought to us.
// TODO: Although we're trying hard to be synced with LonPoll as much as possible, what if we don't receive that heartbeat? 
// As a solution here, we could compare message id and block adding of message of the module that comes second
- (void)didSendMessage:(VKReq *)req
{
	NSDictionary * data = [req.responseData mutableObjectFromJSONData];

	if ([data objectForKey:@"error"]) // Check for error response
	{
//		NSDictionary * errorDict = [data objectForKey:@"error"];
//		NSInteger errorCode = [[errorDict objectForKey:@"error_code"] integerValue];
//		NSString * errorMsg = [errorDict objectForKey:@"error_msg"];
		// // NSLog(@"Error response, error_code: %i, error_msg: %@ ", errorCode, errorMsg);
		return ;
	}

	self.toolbar.textField.text = @"";
	[self.toolbar.tray removeItems];

	[UIView animateWithDuration:0.5f delay:0.1f options:UIViewAnimationOptionAllowUserInteraction animations:^
	 {
		 self.toolbar.buttonRecommend.hidden = NO;
		 self.toolbar.buttonAddToChat.hidden = NO;
	 }
					 completion:nil];
}

@end
