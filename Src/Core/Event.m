//
//  LongPollController.m
//  VKM
//
//  Created by Max on 04.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Event.h"
#import "VKReq.h"
#import "Cache.h"
#import "JSONKit.h"
#import "AppDelegate.h"

#import "CMessage.h"
#import "CUser.h"
#import "CChat.h"

#import "Constants.h"


@interface Event () // Extensions help go private
@property (strong, nonatomic) NSString * server;
@property (strong, nonatomic) NSString * key;
@end


@implementation Event

@synthesize server;
@synthesize key;

-(id)init
{
	self = [super init];
	if (self)
	{
		[self getLongPollServer];

		[self setOnline:nil];
	}
	return self;
}

- (void)setOnline:(id)sender
{
	[VKReq getMethod:@"account.setOnline"
		  withParams:nil
			  target:self
			  action:@selector(didSetOnline:)
				fail:@selector(didSetOnlineFail:)];

	[self performSelector:@selector(setOnline:) withObject:nil afterDelay:60.0f*10.0f];
}

- (void)didSetOnlineFail:(VKReq *)req
{
	[self performSelector:@selector(setOnline) withObject:nil afterDelay:30.0f]; // Retry in 30 seconds
}

- (void)didSetOnline:(VKReq *)req
{
//	[self performSelector:@selector(setOnline) withObject:nil afterDelay:30.0f]; // Retry in 30 seconds
}

// 0,$message_id,0 -- удаление сообщения с указанным local_id
// 1,$message_id,$flags -- замена флагов сообщения (FLAGS:=$flags)
/// 2,$message_id,$mask[,$user_id] -- установка флагов сообщения (FLAGS|=$mask)
// 3,$message_id,$mask[,$user_id] -- сброс флагов сообщения (FLAGS&=~$mask)
// 4,$message_id,$flags,$from_id,$timestamp,$subject,$text,$attachments -- добавление нового сообщения
// 8,-$user_id,0 -- друг $user_id стал онлайн
// 9,-$user_id,$flags -- друг $user_id стал оффлайн ($flags равен 0, если пользователь покинул сайт (например, нажал выход) и 1, если оффлайн по таймауту (например, статус away))
// 51,$chat_id,$self -- один из параметров (состав, тема) беседы $chat_id были изменены. $self - были ли изменения вызываны самим пользователем
// 61,$user_id,$flags -- пользователь $user_id начал набирать текст в диалоге. событие должно приходить раз в ~5 секунд при постоянном наборе текста. $flags = 1
// 62,$user_id,$chat_id -- пользователь $user_id начал набирать текст в беседе $chat_id.

//	{"ts":718347813,"updates":[]}
//	{"ts":718347814,"updates":[[8,-85813842,0]]} - Gillian came online
//	data: {"ts":718347815,"updates":[[4,16690,33,85813842,1333510034," ... ","vffrc",{}]]} - Gillian sent a message
//	{ ts: 196851352, updates: [ [ 9, -835293, 1 ], [ 9, -23498, 1 ] ] }
//	{ ts: 196851367, updates: [ [ 4, 16929, 1, 85635407, 1280307577, ' ... ', 'hello', {'attach1_type': 'photo', 'attach1': '123_456'} ] ] }
// Simple with one attachment
//		{"ts":981853798,"updates":[[4,17251,561,168209039,1333938950," ... ","",{"attach1_type":"audio","attach1":"168209039_148177893"}]]}
/*
 {"ts":981853804,
 "updates":[[4,17254,561,168209039,1333939709," ... ","",
 {
 "attach1_type":"audio","attach1":"168209039_148177893",
 "attach2_type":"video","attach2":"168209039_162519468",
 "attach3_type":"photo","attach3":"168209039_281745755"}]]}
 */

// TODO: We don't remove externaly removed messages here
// Core data will pickup changes immediately
- (void)processEvent:(NSArray *)event
{
	AppDelegate * del = [[UIApplication sharedApplication] delegate];
	NSInteger type = [[event objectAtIndex:0] intValue];

	// Never loved switch, don't know why (though Stroustrup claims it could give a bit of perfomance benefit)
	if (type == eEventMessageRemoved)
	{
		NSNumber * mid = [event objectAtIndex:1];
		// // NSLog(@"EVENT: Message %i removed", mid.intValue);
	}
	else if (type == eEventMessageFlagsChanged)
	{
		NSNumber * mid = [event objectAtIndex:1];
		// NSLog(@"EVENT: Message %i flags changed", mid.intValue);
	}
	else if (type == eEventMessageFlagsSet)
	{
		NSNumber * mid = [event objectAtIndex:1];
		// NSLog(@"EVENT: Message %i flags set", mid.intValue);
	}
	else if (type == eEventMessageFlagsReset)
	{
		NSNumber * mid = [event objectAtIndex:1];
		// NSLog(@"EVENT: Message %i flags reset", mid.intValue);
	
//		EVENT: Message 17834 flags reset - message was marked read by peer

		NSNumber * mask = [event objectAtIndex:2];

		if (mask.intValue & eFlagUnread)
		{
			CMessage * message = [[Cache instance] messageById:mid.intValue];
			if (message)
			{
				[message setRead:[NSNumber numberWithBool:YES]];
			}
		}

/*
		eFlagUnread		= 1,
		eFlagOut		= 2,
		eFlagReplied	= 4,	// There's a reply on this message
		eFlagImportant	= 8,	// Marked message
		eFlagChat		= 16,	// Sent from chat
		eFlagFriends	= 32,	// Sent by a friend
		eFlagSpam		= 64,
		eFlagDeleted	= 128,
		eFlagFixed		= 256,	// Messages was spam-checked by user
		eFlagMedia		= 512,	// Message has media content
*/
		
		
		
	}
	else if (type == eEventMessageAdded)
	{
		// TODO: WARNING, DON'T process own messages here! 
		NSNumber * mid = [event objectAtIndex:1];
		NSNumber * flags = [event objectAtIndex:2];
		NSNumber * fromId = [event objectAtIndex:3];
		NSNumber * date = [event objectAtIndex:4];
		NSString * title = [event objectAtIndex:5];
		NSString * text = [event objectAtIndex:6];
		NSDictionary * attachments = [event objectAtIndex:7];
//		// NSLog(@"EVENT: New message from %i", fromId.intValue);

		BOOL groupChat = NO;

// Chat new message, 3 people
// {"ts":464588604,"updates":[[4,17440,8243,2000000005,1334286565,"Беседа с Любой и Джилей","Привет Люба и Джиля, это Макс",{"from":"1258287"}]]}		
// {"ts":464588623,"updates":[[4,17445,8241,2000000005,1334287402,"Беседа с Любой и Джилей","здарова чату от Любы!",{"from":"168209039"}],[3,17441,1,2000000005]]}
// {"ts":464588653,"updates":[[4,17450,8241,2000000006,1334290529,"Беседа с Максом и Джилей","Макс и Джиля йоу!",{"from":"168209039"}]]}

// From dialogs
// {"ts":464588619,"updates":[[4,17444,49,168209039,1334287108," ... ","Маааакс",{}]]}

// Not from dialogs		
// {"ts":464588616,"updates":[[4,17443,33,168209039,1334287026," ... ","МАкс йоу",{}]]}
		static int chatNum = 2000000000;

		CChat * chat = nil;
		if (fromId.intValue > chatNum)
		{
			int chatId = fromId.intValue-chatNum;
			fromId = [NSNumber numberWithInt:[[attachments objectForKey:@"from"] intValue]]; // Correct fromId for group chat message
//			// NSLog(@"Message from group chat %i, from %i", chatId, fromId.intValue);

			// We have new message from group chat
			// First of all, see if we have chat cached
			NSArray * chats = [[Cache instance] fetch:@"CChat"
											predicate:[NSPredicate predicateWithFormat:@"(cid == %i)", chatId]];

			groupChat = YES;
			if (chats.count) // If exists, ref it
			{
				chat = [chats objectAtIndex:0];

				// Unset latest message in this chat
				CMessage * latest = [[chat.messages filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"latest==YES"]] anyObject];
				[latest setLatest:[NSNumber numberWithBool:NO]];
			}
			else // If not, add chat to cache
			{
				chat = [[Cache instance] createObjectInEntity:@"CChat"];
				[chat setCid:[NSNumber numberWithInt:chatId] ];

				[chat setTitle:title];

				// TODO: We don't know here members in chat, this will be set later
				// But we know that at least myself and from
//				chat.members = ?;
			}
		}

		// Create new message
		CMessage * message = [[Cache instance] createObjectInEntity:@"CMessage"];
		[message setMid:mid];
		[message setDate:date];

		text = [text stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"]; // Replace <br>'s with "\n"
		text = [text stringByDecodingXMLEntities]; // Decode numeric entities (&#33; etc) back to symbols
		[message setText:text];

		if (groupChat)
		{
			[message setChat:chat];
			[message setFrom_id:fromId];
		}
		else
		{
			AppDelegate * del = [[UIApplication sharedApplication] delegate];
			[message setFrom_id:(flags.intValue & eFlagOut)?del.udUserId:fromId];
		}

		if (message.from_id.intValue != del.udUserId.intValue)
			[del setUnreadCount:del.udUnreadCount.intValue+1];

		[message setRead:[NSNumber numberWithBool:NO]];
		[message setLatest:[NSNumber numberWithBool:YES]];

		// LongPoll messages don't have enough info about attachments, however they
		// tell for sure how many of them and what type are they of
		// Hence just set preliminar fields (first att type) and ask immediately for the complete message info
		NSString * lpAttachment = [attachments objectForKey:@"attach1_type"];
		if (lpAttachment)
		{
			if ([lpAttachment isEqualToString:@"photo"])
				[message setAttachmentType:[NSNumber numberWithInteger:eAttachmentTypePhoto]];
			else if ([lpAttachment isEqualToString:@"audio"])
				[message setAttachmentType:[NSNumber numberWithInteger:eAttachmentTypeAudio]];
			else if ([lpAttachment isEqualToString:@"video"])
				[message setAttachmentType:[NSNumber numberWithInteger:eAttachmentTypeVideo]];
//			else if ([lpAttachment isEqualToString:@"geo"])
//				message.attachmentType = [NSNumber numberWithInteger:eAttachmentTypeGeo];

			[VKReq getMethod:@"messages.getById"
				  withParams:[NSString stringWithFormat:@"mid=%i", message.mid.intValue]
					  target:self
					  action:@selector(didGetMessageById:)
						fail:@selector(didGetMessageByIdFail:)];
		}
		else
		{
			[message setAttachmentType:[NSNumber numberWithInteger:eAttachmentMissing]];
		}

		// We're adding new latest message, unset latest flag on previous one (if any)
		if (groupChat)
		{
			// TODO: Unset latest message in this group chat
//			NSArray * desc = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]];
//			NSArray * messages = [message.chat.messages sortedArrayUsingDescriptors:desc];
//			NSArray * messages = 
//			Message * latestMessage = [messages objectAtIndex:0];
//			latestMessage.latest = NO;
		}
		else
		{
			NSArray * fetchedArray = [[Cache instance]
									  fetch:@"CMessage"
									  predicate:[NSPredicate predicateWithFormat:@"(chat == NULL && user.uid == %i)", fromId.intValue]
									  sortDescriptor:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]]; // Newest in front
			if (fetchedArray.count) // If there're any messages to/from such user, unmark the latest
				[[fetchedArray objectAtIndex:0] setLatest:[NSNumber numberWithBool:NO]];
		}

		// Relate message with its author, so we can find it on next cache fetch
		// Check we actually have this user in cache, if not add now
		NSArray * fetchedArray = [[Cache instance] fetch:@"CUser"
									 predicate:[NSPredicate predicateWithFormat:@"(uid == %i)", fromId.intValue]];
		CUser * user = nil;
		if (fetchedArray.count)
		{
			user = [fetchedArray objectAtIndex:0]; // User in cache, all good
		}
		else // User not found, ask VK for the user info
		{
			user = [[Cache instance] createObjectInEntity:@"CUser"];
			[user setUid:fromId];

			// For users not in cache, ask more info from VK
			[VKReq getMethod:@"users.get"
				  withParams:[NSString stringWithFormat:@"uids=%i&fields=photo,online", fromId.intValue]
					  target:self
					  action:@selector(didGetUserById:)
						fail:@selector(didGetUserByIdFail:)];
		}
		[message setUser:user];
	}
	else if (type == eEventUserOnline || type == eEventUserOffline)
	{
		NSInteger uid = abs([[event objectAtIndex:1] intValue]);
//		NSInteger flags = abs([[event objectAtIndex:2] intValue]);

		NSArray * fetchedArray = [[Cache instance] fetch:@"CUser"
											   predicate:[NSPredicate predicateWithFormat:@"(uid == %i)", uid]];

		if (!fetchedArray.count)
		{
			// NSLog(@"WARNING: User coming to online NOT in cache");
			// We don't have this user cached, either no messages to/from him for a long time, or all of them have recently been deleted
			// Just exit silently, we'll cache this when there's any messages
			return;
		}

		CUser * user = [fetchedArray objectAtIndex:0];

		// NSLog(@"EVENT: User %@ (%i) came %@, messages %i", user.nameLast, user.uid.intValue, (type==eEventUserOnline)?@"online":@"offline", user.messages.count);

		// Refresh user's latest messages since they are not in fault, or change tracking won't catch this event
		// This will ensure all table views will be updated as appropriate
		NSSet * latestForUser = [user.messages objectsPassingTest:^(CMessage * message, BOOL * stop)
		{
			return message.latest.boolValue;
		}];
		NSManagedObjectContext * moc = [[Cache instance] managedObjectContext];
		[latestForUser enumerateObjectsUsingBlock:^(CMessage * message, BOOL * stop)
		 {
			 [moc refreshObject:message mergeChanges:YES];
		 }];

		[user setOnline:[NSNumber numberWithBool:(type==eEventUserOnline)?YES:NO]];
	}
	else if (type == eEventChatChanged)
	{
		NSInteger chatId = abs([[event objectAtIndex:1] intValue]);

		// NSLog(@"EVENT: Chat %i parameters changed", chatId);
	}
	else if (type == eEventUserTyping)
	{
		NSInteger uid = abs([[event objectAtIndex:1] intValue]);

		// NSLog(@"EVENT: User %i has begun typing text", uid);
	}
	else if (type == eEventUserTypingChat)
	{
		NSInteger uid = abs([[event objectAtIndex:1] intValue]);

		// NSLog(@"EVENT: User %i has begun typing text in group chat", uid);
	}

	[[Cache instance] save];
}

- (void)didGetMessageByIdFail:(VKReq *)req
{
	// NSLog(@"WARNING: Failed to get message info from the server");
}

- (void)didGetMessageById:(VKReq *)req
{
	NSDictionary * data = [req.responseData mutableObjectFromJSONData];

	if ([data objectForKey:@"error"]) // Check for error response
	{
		// NSLog(@"WARNING: Failed to get message info from the server");
		return ;
	}

	NSDictionary * message = [[data objectForKey:@"response"] objectAtIndex:1];

	[[Cache instance] updateMessageWithRemote:message latest:YES];
}

- (void)didGetUserByIdFail:(VKReq *)req
{
	// NSLog(@"WARNING: Failed to get user info from the server");
}

- (void)didGetUserById:(VKReq *)req
{
	NSDictionary * data = [req.responseData mutableObjectFromJSONData];
	
	if ([data objectForKey:@"error"]) // Check for error response
	{
		// NSLog(@"WARNING: Failed to get user info from the server");
		return ;
	}
	
	NSDictionary * user = [[data objectForKey:@"response"] objectAtIndex:0];
	[[Cache instance] updateOrAddUserWithRemote:user save:YES];
}

#pragma mark -
#pragma mark - Core methods

- (void)getLongPollServer
{
	[VKReq getMethod:@"messages.getLongPollServer"
		  withParams:nil
			  target:self
			  action:@selector(didGetLongPollServer:)
				fail:@selector(didGetLongPollServerFail:)];
}

- (void)didGetLongPollServer:(VKReq *)req
{
	NSDictionary * data = [req.responseData mutableObjectFromJSONData];
	
	self.key = [[data objectForKey:@"response"] objectForKey:@"key"];
	self.server = [[data objectForKey:@"response"] objectForKey:@"server"];
	
	NSInteger ts = [[[data objectForKey:@"response"] objectForKey:@"ts"] integerValue];
	
	VKReq * r = [[VKReq alloc] initWithTarget:self action:@selector(didGetEvent:) fail:@selector(didGetEventFail:)];
	
	NSString * s = [NSString stringWithFormat:@"http://%@?act=a_check&key=%@&ts=%i&wait=25&mode=2", self.server, self.key, ts];
	
	[r get:s];
}

- (void)didGetLongPollServerFail:(VKReq *)req
{
	// NSLog(@"WARNING: Failed to get LongPoll server, re-requesting the server anew now...");

	[self getLongPollServer]; // TODO: Could call it after say 3 sec
}

- (void)didGetEvent:(VKReq *)req
{
	NSDictionary * data = [req.responseData mutableObjectFromJSONData];

	// NSLog(@"EVENT(s) RECEIVED");

	if ([data objectForKey:@"failed"]) // Always re-request LongPoll server in case of any error
	{
		// NSLog(@"WARNING: LongPoll server returned failed:N, re-requesting the server anew now...");
		
		[VKReq getMethod:@"messages.getLongPollServer"
			  withParams:nil
				  target:self
				  action:@selector(didGetLongPollServer:)
					fail:nil];

		return; // Nothing to process
	}

//	{"ts":464589262,"updates":[[8,-168209039,0]]}
	NSArray * updates = [data objectForKey:@"updates"]; // Array of arrays of updates
	for (NSArray * update in updates)
	{
		[self processEvent:update];
	}

	// Once sorted out response, send new req to the LongPoll server
	// TODO: Why don't we reuse currently allocated reques?
	NSInteger ts = [[data objectForKey:@"ts"] integerValue];
	VKReq * request = [[VKReq alloc] initWithTarget:self action:@selector(didGetEvent:) fail:@selector(didGetEventFail:)];
	[request get:[NSString stringWithFormat:@"http://%@?act=a_check&key=%@&ts=%i&wait=25&mode=2", self.server, self.key, ts]];
}

- (void)didGetEventFail:(VKReq *)req
{
	// NSLog(@"WARNING: LongPoll server failed to answer, re-requesting the server anew now...");

	[self getLongPollServer]; // TODO: Could call it after say 3 sec
}


@end
