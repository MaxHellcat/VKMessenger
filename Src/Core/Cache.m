//
//  VKCache.m
//  VKM
//
//  Created by Max on 31.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Cache.h"

#import "VKReq.h"
#import "AppDelegate.h"

#import "CMessage.h"
#import "CUser.h"
#import "CAttachment.h"
#import "CChat.h"

#import "Constants.h"

#import "JSONKit.h"


static Cache * _instance = nil;

@implementation Cache

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

//@synthesize users = _users;

#pragma mark -
#pragma mark Aux methods

// Aux method to refresh cached users with newly received ones over network
- (void)updateUsers:(NSArray *)remoteUsers
{
	for (NSDictionary * remoteUser in remoteUsers)
	{
		[self updateOrAddUserWithRemote:remoteUser save:NO];
	}
	[[Cache instance] save];
}

- (void)updateOrAddUserWithRemote:(NSDictionary *)remoteUser save:(BOOL)save
{
	NSArray * fetchedArray = [[Cache instance] fetch:@"CUser"
											 predicate:[NSPredicate predicateWithFormat:@"(uid == %i)", [[remoteUser objectForKey:@"uid"] integerValue]]];

	CUser * user = nil;
	if (fetchedArray.count)
	{
		// // NSLog(@"UPDATE user %@ (%i) in cache", [remoteUser objectForKey:@"last_name"], [[remoteUser objectForKey:@"uid"] intValue]);
		user = [fetchedArray objectAtIndex:0];
	}
	else // New user, add to cache
	{
		// // NSLog(@"ADD user %@ (%i) to cache", [remoteUser objectForKey:@"last_name"], [[remoteUser objectForKey:@"uid"] intValue]);
		user = [[Cache instance] createObjectInEntity:@"CUser"];
	}

	user.uid = [remoteUser objectForKey:@"uid"];
	user.nameFirst = [[remoteUser objectForKey:@"first_name"] stringByReplacingOccurrencesOfString:@" " withString:@""];
	user.nameLast = [[remoteUser objectForKey:@"last_name"] stringByReplacingOccurrencesOfString:@" " withString:@""];
	user.online = [remoteUser objectForKey:@"online"];
	user.photo = [remoteUser objectForKey:@"photo_medium_rec"]; // photo_rec for non-retina
	user.friend = [NSNumber numberWithBool:NO];

	if (save)
		[[Cache instance] save];
}

// TODO: Should we pickup and update here for group chat message?
- (CMessage *)updateMessage:(CMessage *)message withRemoteMessage:(NSDictionary *)remoteMessage latest:(BOOL)latest
{
	// // NSLog(@"UPDATE message %i, \"%@\" in cache", [[remoteMessage objectForKey:@"mid"] intValue], [remoteMessage objectForKey:@"body"]);

	NSString * body = [remoteMessage objectForKey:@"body"];
	body = [body stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"]; // Replace <br>'s to "\n"
	body = [body stringByDecodingXMLEntities]; // Decode numeric entities (&#33; etc) to symbols

	// TODO: What else could have been changed externally?
//	message.text = body; // Beware, getDialogs often returns empty body for messages with attachments
	message.date = [remoteMessage objectForKey:@"date"]; // Date should be updated, due to specifics in ChatHistory
	message.read = [remoteMessage objectForKey:@"read_state"]; // Message could've been read remotely

	if (latest)
		message.latest = [NSNumber numberWithBool:YES]; // Important, only update latest if it's true

	// Attachments
	// Only process them if we haven't done so already
	if (message.attachments.count==0)
	{
		NSDictionary * remoteAttachments = [remoteMessage objectForKey:@"attachments"];
		if (remoteAttachments)
			[self addAttachmentsForMessage:message withRemoteAttachments:remoteAttachments];
	}

	// Refresh chat
	CChat * chat = nil;
	NSNumber * chatId = [remoteMessage objectForKey:@"chat_id"];
	if (chatId)
	{
		// Group chat message usecase
		// first of all, work out if we have chat cached
		NSArray * chats = [[Cache instance] fetch:@"CChat"
										predicate:[NSPredicate predicateWithFormat:@"(cid == %i)", chatId.intValue]];
/*
		if (chats.count) // If exists, ref it
		{ 
			chat = [chats objectAtIndex:0];
			for (CUser * user in chat.members)
				[self.managedObjectContext deleteObject:user];
			[self save];

			// Populate chat with members
			NSArray * members = [[remoteMessage objectForKey:@"chat_active"] componentsSeparatedByString:@","]; // TODO: Will it return ok if only one uid there?
			for (NSString * member in members)
			{
				CUser * user = [self userById:member.intValue];
		
				[chat addMembersObject:user];
			}
			AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
			[chat addMembersObject:[self userById:delegate.udUserId.intValue]]; // Including myself ofcourse
		}
*/
	}
		

	return message;
}

- (CMessage *)updateMessageWithRemote:(NSDictionary *)remoteMessage latest:(BOOL)latest
{
	NSArray * fetchedArray = [[Cache instance] fetch:@"CMessage"
											 predicate:[NSPredicate predicateWithFormat:@"(mid == %i)", [[remoteMessage objectForKey:@"mid"] intValue]]];
	CMessage * message = nil;
	if (fetchedArray.count) // Message found in cache, update it
		message = [[Cache instance] updateMessage:[fetchedArray objectAtIndex:0] withRemoteMessage:remoteMessage latest:latest];

	return message;
}

// Group message (getDialogs)
/*
{
	"mid":17420,
	"date":1334214400,
	"out":0,
	"uid":168209039,
	"read_state":0,
	"title":"Беседа с Джилей и Любой",
	"body":"Привет \320\234акс и Джиля, это Люба",
	"chat_id":4,
	"chat_active":"168209039,85813842",
	"users_count":3,
	"admin_id":1258287
}
*/

/* Group message (getHistory)
{
	"body":"а вот в друной чат",
	"mid":17525,
	"from_id":168209039,
	"date":1334389379,
	"read_state":1},
}
*/

// Add new message to cache, for given user
/*
- (Message *)addMessage:(NSDictionary *)remoteMessage latest:(BOOL)latest
{
	return [self addMessage:remoteMessage forUser:nil latest:latest];
}
 */

- (void)addMessageLatestDialogs:(NSDictionary *)remoteMessage
{
	[self addMessage:remoteMessage forUser:nil messageType:eRemoteFormatLatestDialogs forChat:nil];
}

- (void)addMessageChatHistory:(NSDictionary *)remoteMessage forUser:(CUser *)localUser forChat:(CChat *)localChat
{
	[self addMessage:remoteMessage forUser:localUser messageType:eRemoteFormatChatHistory forChat:localChat];
}

//- (Message *)addMessage:(NSDictionary *)remoteMessage forUser:(User *)localUser latest:(BOOL)latest
//- (void)addMessage:(NSDictionary *)remoteMessage forUser:(User *)localUser messageType:(RemoteType)messageType requestType:(RequestType)reqType
- (void)addMessage:(NSDictionary *)remoteMessage forUser:(CUser *)localUser messageType:(RemoteType)messageType forChat:(CChat *)localChat
{
	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];

	CUser * user = nil;
	CChat * chat = nil;

	// Decode message text
	NSString * body = [remoteMessage objectForKey:@"body"];
	body = [body stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"]; // Replace <br>'s with "\n"
	body = [body stringByDecodingXMLEntities]; // Decode numeric entities (&#33; etc) back to symbols

	// Create new message in cache and populate with remote message data
	CMessage * cachedMessage = [[Cache instance] createObjectInEntity:@"CMessage"]; // Add new record in Message entity
	[cachedMessage setMid:[remoteMessage objectForKey:@"mid"]];
	[cachedMessage setText:body]; // May be empty for message with attachments
	[cachedMessage setDate:[remoteMessage objectForKey:@"date"]];
	[cachedMessage setRead:[remoteMessage objectForKey:@"read_state"]];


	// Messages from getDialogs have different format than those from getHistory
	if (messageType == eRemoteFormatLatestDialogs)
	{
		// TODO: Can we avoid fetch here?
		NSInteger uid = [[remoteMessage objectForKey:@"uid"] integerValue];
		user = [[Cache instance] userById:uid];

		// Messages returned by GetDialogs don't have .from_id, but do have .out field
		[cachedMessage setLatest:[NSNumber numberWithBool:YES]]; // Messages from getDialogs are always latest
		if ([[remoteMessage objectForKey:@"out"] boolValue])
			[cachedMessage setFrom_id:delegate.udUserId];
		else
			[cachedMessage setFrom_id:user.uid];

		// For messages from getDialogs, set some preliminar info about attachments (as they often miss full info)
		// But don't update message.attachments field, so that updateMessage would spot incompletness here
		NSDictionary * remoteAttachment = [remoteMessage objectForKey:@"attachment"];
		if (remoteAttachment)
		{
			NSString * types = [remoteAttachment objectForKey:@"type"];
			if ([types isEqualToString:@"photo"])
				[cachedMessage setAttachmentType:[NSNumber numberWithInteger:eAttachmentTypePhoto] ];
			else if ([types isEqualToString:@"audio"])
				[cachedMessage setAttachmentType:[NSNumber numberWithInteger:eAttachmentTypeAudio] ];
			else if ([types isEqualToString:@"video"])
				[cachedMessage setAttachmentType:[NSNumber numberWithInteger:eAttachmentTypeVideo]];
//			else
//				cachedMessage.attachmentType = [NSNumber numberWithInteger:eAttachmentMissing];
		}
		else
		{
			[cachedMessage setAttachmentType: [NSNumber numberWithInteger:eAttachmentMissing]]; // When getDialogs sents empty message
		}

		// Work out if we deal with group chat message
		id chatId = [remoteMessage objectForKey:@"chat_id"];
		if (chatId)
		{
			// // NSLog(@"ADD (from getDialogs) group chat message %i, \"%@\" to cache", [[remoteMessage objectForKey:@"mid"] intValue], [remoteMessage objectForKey:@"body"]);

			// Group chat message usecase
			// first of all, work out if we have chat cached
			NSArray * chats = [[Cache instance] fetch:@"CChat"
											predicate:[NSPredicate predicateWithFormat:@"(cid == %i)", chatId]];
			if (chats.count) // If exists, ref it
			{ 
				// TODO: Should we refresh chat?
				chat = [chats objectAtIndex:0];
			}
			else // If not, add chat to cache (chat was recently created or we've been recently added to it)
			{
				chat = [[Cache instance] createObjectInEntity:@"CChat"];
				[chat setCid:[remoteMessage objectForKey:@"chat_id"]];
				[chat setTitle:[remoteMessage objectForKey:@"title"]];
				[chat setAdmin:[self userById:[[remoteMessage objectForKey:@"admin_id"] intValue]]];

//				chat.usersCount = [remoteMessage objectForKey:@"users_count"]; // TODO: This equals members.count, does it not
				// Populate chat with members
				NSArray * members = [[remoteMessage objectForKey:@"chat_active"] componentsSeparatedByString:@","]; // TODO: Will it return ok if only one uid there?
				for (NSString * member in members)
				{
					CUser * user = [self userById:member.intValue];
					[chat addMembersObject:user];
				}
//				[chat addMembersObject:[self userById:delegate.udUserId.intValue]]; // Including myself ofcourse
			}
		}
		else
		{
			// // NSLog(@"ADD (from getDialogs) single chat message %i, \"%@\" to cache", [[remoteMessage objectForKey:@"mid"] intValue], [remoteMessage objectForKey:@"body"]);
		}
	}
	else // if (messageType == eRemoteFormatChatHistory)
	{
		user = localUser;
		chat = localChat;

		// Similarly, messages from GetHistory don't have .out, but have .from_id
		[cachedMessage setFrom_id:[remoteMessage objectForKey:@"from_id"]];
		
		NSDictionary * remoteAttachments = [remoteMessage objectForKey:@"attachments"];
		if (remoteAttachments)
			[self addAttachmentsForMessage:cachedMessage withRemoteAttachments:remoteAttachments];
		else
			[cachedMessage setAttachmentType:[NSNumber numberWithInteger:eAttachmentMissing]];

//		if (chat)
//			// // NSLog(@"ADD (from getHistory) group chat message %i, \"%@\" to cache", [[remoteMessage objectForKey:@"mid"] intValue], [remoteMessage objectForKey:@"body"]);
//		else
			// NSLog(@"ADD (from getHistory) single chat message %i, \"%@\" to cache", [[remoteMessage objectForKey:@"mid"] intValue], [remoteMessage objectForKey:@"body"]);
	}

	[cachedMessage setUser:user]; // Relate newly added message to its author
	[cachedMessage setChat:chat]; // If passed chat is NULL for getHistory message, we're dealing with single chat message

	[[Cache instance] save]; // This is crucial
}

- (void)addAttachmentsForMessage:(CMessage *)cachedMessage withRemoteAttachments:(NSDictionary *)remoteAttachments
{
	short index = 0; // Attachment index
	for (NSDictionary * remoteAttachment in remoteAttachments)
	{
		CAttachment * attachment = [[Cache instance] createObjectInEntity:@"CAttachment"];

		NSString * types = [remoteAttachment objectForKey:@"type"];

		if ([types isEqualToString:@"photo"])
		{
			NSDictionary * photo = [remoteAttachment objectForKey:@"photo"];
			attachment.type = [NSNumber numberWithInteger:eAttachmentTypePhoto];
			attachment.aid = [photo objectForKey:@"pid"];
			attachment.src = [photo objectForKey:@"src"]; // Also src_big, src_small
			attachment.position = [NSNumber numberWithInteger:index];

			if (index==0) // Store type of 1st attachment, for quick refer when drawing tables
				cachedMessage.attachmentType = [NSNumber numberWithInteger:eAttachmentTypePhoto];
		}
		else if ([types isEqualToString:@"audio"])
		{
			NSDictionary * photo = [remoteAttachment objectForKey:@"audio"];
			attachment.type = [NSNumber numberWithInteger:eAttachmentTypeAudio];
			attachment.aid = [photo objectForKey:@"aid"];
			attachment.src = [photo objectForKey:@"url"]; // Also src_big, src_small
			attachment.title = [photo objectForKey:@"title"];
//			attachment.artist = [photo objectForKey:@"artist"]; // Or "performer"
//			attachment.duration = [photo objectForKey:@"duration"];
			attachment.position = [NSNumber numberWithInteger:index];

			if (index==0) // Store type of 1st attachment, for quick refer when drawing tables
				cachedMessage.attachmentType = [NSNumber numberWithInteger:eAttachmentTypeAudio];
		}
		else if ([types isEqualToString:@"video"])
		{
			NSDictionary * photo = [remoteAttachment objectForKey:@"video"];
			attachment.type = [NSNumber numberWithInteger:eAttachmentTypeVideo];
			attachment.aid = [photo objectForKey:@"vid"];
			attachment.src = [photo objectForKey:@"image"]; // Also image_big, image_small
			attachment.title = [photo objectForKey:@"title"];
//			attachment.duration = [photo objectForKey:@"duration"];
			attachment.position = [NSNumber numberWithInteger:index];

			if (index==0) // Store type of 1st attachment, for quick refer when drawing tables
				cachedMessage.attachmentType = [NSNumber numberWithInteger:eAttachmentTypeVideo];
		}
//		else if (type==eAttachmentTypeGeo)
//		{
//		}

		++index;

		attachment.message = cachedMessage;

		// NSLog(@"Added %i attachment, type %i, src %@", index, attachment.type.intValue, attachment.src);
	}
	[[Cache instance] save];
}

#pragma mark -
#pragma mark Access methods

- (CUser *)userById:(NSInteger)uid
{
	NSArray * fetchedArray = [[Cache instance] fetch:@"CUser"
										   predicate:[NSPredicate predicateWithFormat:@"(uid == %i)", uid]];
	CUser * user = nil;
	if (fetchedArray.count)
	{
		user = [fetchedArray objectAtIndex:0];
	}
	else
	{
//		// NSLog(@"INFO: Creating new user with uid %i", uid);
		user = [[Cache instance] createObjectInEntity:@"CUser"];
		[self save];

		// And immediately ask for more info about user
		// For users not in cache, ask more info from VK
		[VKReq getMethod:@"users.get"
			  withParams:[NSString stringWithFormat:@"uids=%i&fields=uid,first_name,last_name,photo_medium_rec,online", uid]
				  target:self
				  action:@selector(didGetUserById:)
					fail:@selector(didGetUserByIdFail:)];

	}	
	return user;
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
		return ;
	}

	NSDictionary * user = [[data objectForKey:@"response"] objectAtIndex:0];
	[[Cache instance] updateOrAddUserWithRemote:user save:YES];
}

- (CMessage *)messageById:(NSInteger)mid
{
	NSArray * fetchedArray = [[Cache instance] fetch:@"CMessage"
										   predicate:[NSPredicate predicateWithFormat:@"(mid == %i)", mid]];
	CMessage * message = nil;
	if (fetchedArray.count)
		message = [fetchedArray objectAtIndex:0];

	return message;
}



#pragma mark -
#pragma mark Core Methods

+ (id)instance
{
    @synchronized (self)
	{
        if (_instance == nil)
            _instance = [[self alloc] init];
    }
    return _instance;
}

- (id)init
{
    if (self = [super init])
	{
		[self managedObjectContext]; // Pre-initialize upon creation (this also inits POS/PSC)
    }
	return self;
}

/*
- (void)usersFetchController:(id)delegate
{
	_users = [[Cache instance]
			  fetchController:@"CUser"
			  predicate:nil
			  sortDescriptor:nil
			  delegate:delegate];
}
*/

- (NSArray *)fetch:(NSString *)entity predicate:(NSPredicate *)predicate
{
	return [self fetch:entity predicate:predicate sortDescriptor:nil];
}

- (NSArray *)fetch:(NSString *)entity predicate:(NSPredicate *)predicate sortDescriptor:(NSSortDescriptor *)descriptor
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription * ent = [NSEntityDescription entityForName:entity inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:ent];
	[fetchRequest setFetchBatchSize:20];

	fetchRequest.predicate = predicate;

	if (descriptor)
	{
		NSArray * sortDescriptors = [NSArray arrayWithObject:descriptor];
		[fetchRequest setSortDescriptors:sortDescriptors];
	}

	NSArray * array = [__managedObjectContext executeFetchRequest:fetchRequest error:nil];

//	// NSLog(@"FETCH FROM %@ WHERE %@: %i record(s)", entity, [predicate debugDescription], [array count]);

	return array;
}

// A controller thus effectively has three modes of operation, determined by whether it has a delegate and whether the cache file name is set.
// - No tracking: the delegate is set to nil.
//		The controller simply provides access to the data as it was when the fetch was executed.
// - Memory-only tracking: the delegate is non-nil and the file cache name is set to nil.
//		The controller monitors objects in its result set and updates section and ordering information in response to relevant changes.
// - Full persistent tracking: the delegate and the file cache name are non-nil.
//		The controller monitors objects in its result set and updates section and ordering information in response to relevant changes. The controller maintains a persistent cache of the results of its computation.

// Important If you are using a cache, you must call deleteCacheWithName: before changing any
// of the fetch request, its predicate, or its sort descriptors.
// You must not reuse the same fetched results controller for multiple queries unless you set the cacheName to nil.
// (void)deleteCacheWithName:(NSString *)name;
- (NSFetchedResultsController *)fetchController:(NSString *)entity
									  predicate:(NSPredicate *)predicate
								 sortDescriptor:(NSSortDescriptor *)descriptor
							 sectionNameKeyPath:(NSString *)sectionNameKeyPath
										  delegate:(id<NSFetchedResultsControllerDelegate>)del
{
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription * ent = [NSEntityDescription entityForName:entity inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:ent];
//	[fetchRequest setFetchBatchSize:20];

	fetchRequest.predicate = predicate;

	if (descriptor)
	{
		NSArray * sortDescriptors = [NSArray arrayWithObject:descriptor];
		[fetchRequest setSortDescriptors:sortDescriptors];
	}
	

    NSFetchedResultsController * frc = [[NSFetchedResultsController alloc]
										initWithFetchRequest:fetchRequest
										managedObjectContext:self.managedObjectContext
										sectionNameKeyPath:sectionNameKeyPath
										cacheName:nil]; // If you do not specify a cache name, the controller does not cache data.
	if (del!=nil)
		frc.delegate = del;

	NSError * error = nil;
	if (![frc performFetch:&error])
	{
		// NSLog(@"Fetch controller error %@, %@", error, [error userInfo]);
//		abort(); // Only for debug
	}

    return frc;
}

- (id)createObjectInEntity:(NSString *)entity
{
	return [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:self.managedObjectContext];
}

- (void)save
{
	[self saveContext];
}

#pragma mark - Core Data stack

- (void)saveContext
{
    NSError * error = nil;
	NSManagedObjectContext * managedObjectContext = self.managedObjectContext;
//	if (managedObjectContext != nil)
	{
//		if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
		if (![managedObjectContext save:&error])
		{
			// Replace this implementation with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
			// NSLog(@"CORE DATA: Unresolved error when saving %@, %@", error, [error userInfo]);
//			abort();
        } 
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
	{
        return __managedObjectContext;
    }

	NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil)
	{
		__managedObjectContext = [[NSManagedObjectContext alloc] init];
		[__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
	{
        return __managedObjectModel;
    }
    NSURL * modelURL = [[NSBundle mainBundle] URLForResource:@"VKM" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
	{
        return __persistentStoreCoordinator;
    }

    NSURL * storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"VKM.sqlite"];

    NSError * error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
	{
        /*
         Replace this implementation with code to handle the error appropriately.

         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 

         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.


         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.

         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]

         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         */
        // NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
