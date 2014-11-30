//
//  LatestDialogues+Network.m
//  VKM
//
//  Created by Max on 08.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LatestDialogues.h"

#import "JSONKit.h"
#import "VKReq.h"
#import "Cache.h"

#import "CUser.h"
#import "CMessage.h"
#import "CAttachment.h"

#import "AppDelegate.h"
#import "Constants.h"


@implementation LatestDialogues (Network)

#pragma mark -
#pragma mark Network interaction

- (void)readLatestDialogues
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

	self.loading = YES;

	NSString * nscode = [NSString stringWithFormat:@"var dialogs=API.messages.getDialogs({\"offset\":%i,\"count\":20,\"preview_length\":50});var users=API.users.get({\"uids\":dialogs@.chat_active+dialogs@.uid,\"fields\":\"uid,first_name,last_name,photo_medium_rec,online\"});return {\"dialogs\":dialogs,\"users\":users};", self.readCount];
	[VKReq execute:nscode
			target:self
			action:@selector(didGetDialogs:)
			  fail:@selector(didGetDialogsFail:)];

	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
	[[Cache instance] userById:delegate.udUserId.intValue];
	
}

// TODO: Ideally this should go in back thread
// TODO: Handle all errors
- (void)didGetDialogs:(VKReq *)req
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	if (self.waitIndicator.isAnimating)
		[self.waitIndicator stopAnimating];

	NSDictionary * data = [req.responseData mutableObjectFromJSONData];

	if ([data objectForKey:@"error"])
	{
//		NSDictionary * errorDict = [data objectForKey:@"error"];
//		NSInteger errorCode = [[errorDict objectForKey:@"error_code"] integerValue];
//		NSString * errorMsg = [errorDict objectForKey:@"error_msg"];
//		NSLog(@"Error response, error_code: %i, error_msg: %@ ", errorCode, errorMsg);
		return ;
	}

	id remoteMessages = [[data objectForKey:@"response"] objectForKey:@"dialogs"];
	if ([remoteMessages respondsToSelector:@selector(count)] == NO) // If not an array, then no messages
	{
		// The user appears to signup up recently, update the table with no messages info
//		NSLog(@"No messages for this user");
		return ;
	}

	// We have two arrays, messages and users (their authors)
	[remoteMessages removeObjectAtIndex:0];
	NSArray * remoteUsers = [[data objectForKey:@"response"] objectForKey:@"users"];

//	self.loading = YES;

	//
	// Cache refreshing magic
	//
	// Caching principles:
	// Cache only first 20 latest dialogs
	// Cache only first 20 messages per user
	// User optionally has message(s)
	//
	// First, refresh/add new users (User entity) with the newly received server data
	[[Cache instance] updateUsers:remoteUsers];

	// TODO: Mark all procesed as read messages.markAsRead/messages.markAsNew
	// It's worth explaining why we're using latest flag and don't just fetch messages date desc and distinct users
	// Because Core Data can only return distinct returning dictionary, which doesn't suit us
	// Before latest messages refresh, reset latest flag on each latest (to handle remote removal that we don't know of)
	// TODO: Note the we hence accumulate entries in cache - a housekeeer to take care?

	// Unmark latest for current set of fetched controller, to correctly handle further updates
	// Do this only for the very first fetch/reload
	if (self.readCount == 0)
	{
		[self.latestMessages.fetchedObjects enumerateObjectsUsingBlock:^(CMessage * obj, NSUInteger idx, BOOL * stop)
		 {
			 obj.latest = NO;
		 }];
		[[Cache instance] save];
	}

	// TODO: This must be run in a separate thread
	// The latestMessages set empty at this point, so no ways to avoid fetch that I can think of 

	// Execute messages procesing in a separate thread
//	dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
//	{
		// Add code here to do background processing
		for (NSMutableDictionary * remoteMessage in remoteMessages)
		{
			NSInteger mid = [[remoteMessage objectForKey:@"mid"] integerValue];

			// TODO: We could've searched in self.latestMessages if we hadn't cleared it
			NSArray * fetchedArray = [[Cache instance] fetch:@"CMessage"
												   predicate:[NSPredicate predicateWithFormat:@"(mid == %i)", mid]];
			if (fetchedArray.count) // Message found in cache, update it
				[[Cache instance] updateMessage:[fetchedArray objectAtIndex:0] withRemoteMessage:remoteMessage latest:YES];
			else // New message, add to cache
				[[Cache instance] addMessageLatestDialogs:remoteMessage];
		}

//		dispatch_async( dispatch_get_main_queue(), ^
//		{
			// Add code here to update the UI/send notifications based on the
			// results of the background processing
//		});
//	});

	[_refreshView dataSourceDidFinishLoading:self.tableView];

	self.loading = NO;
}

// Handle failed server requests, e.g request timed out
- (void)didGetDialogsFail:(VKReq *)req
{
	// TODO: Shall we re-request here?
	self.loading = NO;
	[self.waitIndicator stopAnimating];
	[_refreshView dataSourceDidFinishLoading:self.tableView];
}

// Obtain number of unread messages
- (void)readUnreadMessagesCountWithOffset:(NSInteger)offset
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	[VKReq execute:[NSString stringWithFormat:@"var unread=API.messages.get({\"offset\":%i,\"time_offset\":0,\"count\":100,\"filters\":1});return unread@.out;", offset]
			target:self
			action:@selector(didGetUnreadMessagesCount:)
			  fail:@selector(didGetUnreadMessagesCountFail:)];
}

- (void)didGetUnreadMessagesCountFail:(VKReq *)req
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)didGetUnreadMessagesCount:(VKReq *)req
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

	NSMutableDictionary * data = [req.responseData mutableObjectFromJSONData];

	if ([data objectForKey:@"error"])
	{
		return ;
	}

	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];

	static int offset = 0;

	NSInteger count = [[data objectForKey:@"response"] count]-1;

	[delegate setUnreadCount:count];

	if (count == 100) // If count==100, rerequst anew with increased offset
	{
		offset += count;
		[self readUnreadMessagesCountWithOffset:offset];
	}
}

// Message with geo
/*
{
	"mid":17130,
	"date":1333922229,
	"out":0,
	"uid":168209039,
	"read_state":1,
	"title":" ... ",
	"body":"Макс вот гео",
	"geo":
	{
		"type":"point",
		"coordinates":"55.8078013594 37.9440122885"
	}
}
*/
// Message with photo, song and video (weirdly doesn't show anything in getDialogs req, but ok when getHistory)
// getDialogs
/*
{
	"mid":17122,
	"date":1333918611,
	"out":0,
	"uid":168209039,
	"read_state":1,
	"title":"",
	"body":""
}
// getHistory
{
	"body":"Макс реально вот фото песня и видос",
	"mid":17122,
	"from_id":168209039,
	"date":1333918611,
	"read_state":1,
	"attachment":
	{
		"type":"photo",
		"photo":
		{
			"pid":281745755,
			"aid":-6,
			"owner_id":168209039,
			"src":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/m_53efccc4.jpg",
			"src_big":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/x_b15d7dd3.jpg",
			"src_small":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/s_7a858564.jpg",
			"width":258,
			"height":195,
			"text":"",
			"created":1332547148,
			"access_key":"c0c560e62ba0b9e8f8"
		}
	},
	"attachments":
	[{
		"type":"photo",
		"photo":
		{
			"pid":281745755,
			"aid":-6,
			"owner_id":168209039,
			"src":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/m_53efccc4.jpg",
			"src_big":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/x_b15d7dd3.jpg",
			"src_small":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/s_7a858564.jpg",
			"width":258,
			"height":195,
			"text":"",
			"created":1332547148,
			"access_key":"c0c560e62ba0b9e8f8"
		}
	},
	{
		"type":"audio",
		"audio":
		{
			"aid":148177894,
			"owner_id":168209039,
			"artist":"Ёлка",
			"title":"Около Тебя",
			"duration":222,
			"url":"http:\/\/cs5575.vkontakte.ru\/u8053645\/audio\/57d1f7fd1ef9.mp3",
			"performer":"Ёлка",
			"lyrics_id":"20619138"
		}
	},
	{
		"type":"video",
		"video":
		{
			"vid":162519468,
			"owner_id":168209039,
			"title":"Вот он Король футбола&#33;",
			"duration":211,
			"image":"http:\/\/cs6029.userapi.com\/u49552013\/video\/m_85b29974.jpg",
			"image_big":"http:\/\/cs6029.userapi.com\/u49552013\/video\/l_78a9582e.jpg",
			"image_small":"http:\/\/cs6029.userapi.com\/u49552013\/video\/s_660fa713.jpg",
			"access_key":"44e3d59f8108a5964b"
		}
	}]
}

*/


// Message with simple text and one video
/*
{
	"mid":17117,
	"date":1333918112,
	"out":0,
	"uid":168209039,
	"read_state":0,
	"title":" ... ",
	"body":"Макс смотри видео",
	"attachment":
	{
		"type":"video",
		"video":
		{
			"vid":162519469,
			"owner_id":168209039,
			"title":"ТРК Футбол &quot;дает заднюю&quot;",
			"duration":603,
			"image":"http:\/\/cs6051.userapi.com\/u21301776\/video\/m_1dca42d7.jpg",
			"image_big":"http:\/\/cs6051.userapi.com\/u21301776\/video\/l_eec26afa.jpg",
			"image_small":"http:\/\/cs6051.userapi.com\/u21301776\/video\/s_1047d43a.jpg",
			"access_key":"9da3366c5fb3724e4f"
		}
	},
	"attachments":
	[{
		"type":"video",
		"video":
		{
			"vid":162519469,
			"owner_id":168209039,
			"title":"ТРК Футбол &quot;\320\264ает заднюю&quot;",
			"duration":603,
			"image":"http:\/\/cs6051.userapi.com\/u21301776\/video\/m_1dca42d7.jpg",
			"image_big":"http:\/\/cs6051.userapi.com\/u21301776\/video\/l_eec26afa.jpg",
			"image_small":"http:\/\/cs6051.userapi.com\/u21301776\/video\/s_1047d43a.jpg",
			"access_key":"9da3366c5fb3724e4f"
		}
	}]
}
*/
// Message with simple text and one photo
/*
{
	"mid":17116,
	"date":1333917816,
	"out":0,
	"uid":168209039,
	"read_state":0,
	"title":" ... ",
	"body":"Макс фото",
	"attachment":
	{
		"type":"photo",
		"photo":
		{
			"pid":281745755,
			"aid":-6,
			"owner_id":168209039,
			"src":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/m_53efccc4.jpg",
			"src_big":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/x_b15d7dd3.jpg",
			"src_small":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/s_7a858564.jpg",
			"width":258,
			"height":195,
			"text":"",
			"created":1332547148,
			"access_key":"c0c560e62ba0b9e8f8"
		}
	},
	"attachments":
	[{
		"type":"photo",
		"photo":
		{
			"pid":281745755,
			"aid":-6,
			"owner_id":168209039,
			"src":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/m_53efccc4.jpg",
			"src_big":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/x_b15d7dd3.jpg",
			"src_small":"http:\/\/cs304701.userapi.com\/u168209039\/-6\/s_7a858564.jpg",
			"width":258,
			"height":195,
			"text":"",
			"created":1332547148,
			"access_key":"c0c560e62ba0b9e8f8"
		}
	}]
}
*/
// Message with simple text and one audio
/*
		{
			"mid":17115,
			"date":1333917382,
			"out":0,
			"uid":168209039,
			"read_state":0,
			"title":" ... ",
			"body":"Макс смотри песня",
			"attachment":
			{
				"type":"audio",
				"audio":
				{
					"aid":148177897,
					"owner_id":168209039,
					"artist":"Michel Teló",
					"title":"Ai Se Eu Te Pego",
					"duration":165,
					"url":"http:\/\/cs5464.vkontakte.ru\/u70809059\/audio\/07bb8b57e3fb.mp3",
					"performer":"Michel Teló",
					"lyrics_id":"20488492"
				}
			},
			"attachments":
			[{
				"type":"audio",
				"audio":
				{
					"aid":148177897,
					"owner_id":168209039,
					"artist":"Michel Teló",
					"title":"Ai Se Eu Te Pego",
					"duration":165,
					"url":"http:\/\/cs5464.vkontakte.ru\/u70809059\/audio\/07bb8b57e3fb.mp3",
					"performer":"Michel Teló",
					"lyrics_id":"20488492"
				}
			}]
		}
*/


@end
