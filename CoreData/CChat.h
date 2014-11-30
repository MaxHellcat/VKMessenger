//
//  CChat.h
//  VKM
//
//  Created by Max on 20.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CMessage, CUser;

@interface CChat : NSManagedObject

@property (nonatomic, retain) NSNumber * cid;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * usersCount;
@property (nonatomic, retain) CUser *admin;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) NSSet *messages;
@end

@interface CChat (CoreDataGeneratedAccessors)

- (void)addMembersObject:(CUser *)value;
- (void)removeMembersObject:(CUser *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

- (void)addMessagesObject:(CMessage *)value;
- (void)removeMessagesObject:(CMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
