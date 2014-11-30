//
//  LongPollController.h
//  VKM
//
//  Created by Max on 04.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Class to listen for events from LongPoll server
// Each new event is parsed, processed and synchronized with the Cache
// Core Data will immediately report about any changes to its delegates, via change tracking
@interface Event : NSObject

@end

typedef
enum
{
	eEventMessageRemoved		= 0,
	eEventMessageFlagsChanged	= 1,
	eEventMessageFlagsSet		= 2,
	eEventMessageFlagsReset		= 3,
	eEventMessageAdded			= 4,
	eEventUserOnline			= 8,
	eEventUserOffline			= 9,
	eEventChatChanged			= 51,
	eEventUserTyping			= 61,
	eEventUserTypingChat		= 62
} LongPollEvent;

typedef
enum
{
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
} Flags;
