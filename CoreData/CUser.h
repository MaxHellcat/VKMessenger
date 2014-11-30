//
//  CUser.h
//  VKM
//
//  Created by Max on 20.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CChat, CMessage;

@interface CUser : NSManagedObject

@property (nonatomic, retain) NSNumber * friend;
@property (nonatomic, retain) NSString * nameFirst;
@property (nonatomic, retain) NSString * nameLast;
@property (nonatomic, retain) NSNumber * online;
@property (nonatomic, retain) NSString * photo;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSSet *adminOfChats;
@property (nonatomic, retain) NSSet *memberOfChats;
@property (nonatomic, retain) NSSet *messages;
@end

@interface CUser (CoreDataGeneratedAccessors)

- (void)addAdminOfChatsObject:(CChat *)value;
- (void)removeAdminOfChatsObject:(CChat *)value;
- (void)addAdminOfChats:(NSSet *)values;
- (void)removeAdminOfChats:(NSSet *)values;

- (void)addMemberOfChatsObject:(CChat *)value;
- (void)removeMemberOfChatsObject:(CChat *)value;
- (void)addMemberOfChats:(NSSet *)values;
- (void)removeMemberOfChats:(NSSet *)values;

- (void)addMessagesObject:(CMessage *)value;
- (void)removeMessagesObject:(CMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

- (NSString *)nameFirstLetter;

@end
