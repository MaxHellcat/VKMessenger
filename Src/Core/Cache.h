//
//  VKCache.h
//  VKM
//
//  Created by Max on 31.03.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMessage, CChat, CUser;

// Type of remote message, to help addMessage parse message dictionary
typedef enum { eRemoteFormatLatestDialogs=0, eRemoteFormatChatHistory } RemoteType;

// To help AddMessage to work out whether remote messages should be considered as group chat messages or not
// Only used for messages coming NOT from getDialogues
typedef enum { eRequestTypeSingleChat=0, eRequestTypeGroupChat, eRequestTypeDontCare } RequestType;

// Class providing efficient caching of received data, see VKM.xcdatamodel for the object model details, relations, etc.
// Based on Core Data framework (underlying data in SQLite)
// Uses automatic change tracking, all view controllers are chages-aware through delegation
// Supports redo/undo operations
@interface Cache : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext * managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel * managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator * persistentStoreCoordinator;

+ (id)instance;

// Methods returning specific and optionally sorted set of cache data
- (NSArray *)fetch:(NSString *)entity predicate:(NSPredicate *)predicate;
- (NSArray *)fetch:(NSString *)entity predicate:(NSPredicate *)predicate sortDescriptor:(NSSortDescriptor *)descriptor;

// Method returning specific and optionally sorted set of cache data, which is updated (move/remove/update/insert)
// automatically using change tracking mechanism
- (NSFetchedResultsController *)fetchController:(NSString *)entity
									  predicate:(NSPredicate *)predicate
								 sortDescriptor:(NSSortDescriptor *)descriptor
							 sectionNameKeyPath:(NSString *)sectionNameKeyPath
										  delegate:(id<NSFetchedResultsControllerDelegate>)del;

- (id)createObjectInEntity:(NSString *)entity;


// Commit pending changes on managed objects
- (void)save; // Use wisely
- (void)saveContext;

- (NSURL *)applicationDocumentsDirectory;

// Aux methods
// Add new message to cache, user is fetched based on remote message info
// Use when creating messages for many users, usecase for messages.getDialogs
// Whenever possible use addMessage: forUser
- (CMessage *)addMessage:(NSDictionary *)remoteMessage latest:(BOOL)latest;

// Add new message to cache for given user, no fetches from cache
// Use when adding bunch of messages for single user, usecase for messages.getHistory
- (CMessage *)addMessage:(NSDictionary *)remoteMessage forUser:(CUser *)localUser latest:(BOOL)latest requestType:(RequestType)reqType;


- (void)addMessageLatestDialogs:(NSDictionary *)remoteMessage;
- (void)addMessageChatHistory:(NSDictionary *)remoteMessage forUser:(CUser *)localUser forChat:(CChat *)localChat;



// TODO: Universal method, should go private really
- (void)addMessage:(NSDictionary *)remoteMessage forUser:(CUser *)localUser messageType:(RemoteType)messageType forChat:(CChat *)localChat;


- (void)updateUsers:(NSArray *)remoteUsers;
- (void)updateOrAddUserWithRemote:(NSDictionary *)remoteUser save:(BOOL)save;
- (CMessage *)updateMessage:(CMessage *)message withRemoteMessage:(NSDictionary *)remoteMessage latest:(BOOL)latest;
- (CMessage *)updateMessageWithRemote:(NSDictionary *)remoteMessage latest:(BOOL)latest;

// Return cached user by uid, creates new if not found
- (CUser *)userById:(NSInteger)uid;

- (CMessage *)messageById:(NSInteger)mid;

@end
