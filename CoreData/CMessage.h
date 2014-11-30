//
//  CMessage.h
//  VKM
//
//  Created by Max on 20.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CAttachment, CChat, CUser;

@interface CMessage : NSManagedObject

@property (nonatomic, retain) NSNumber * attachmentType;
@property (nonatomic, retain) NSNumber * date;
@property (nonatomic, retain) NSNumber * from_id;
@property (nonatomic, retain) NSNumber * latest;
@property (nonatomic, retain) NSNumber * mid;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSSet *attachments;
@property (nonatomic, retain) CChat *chat;
@property (nonatomic, retain) CUser *user;
@end

@interface CMessage (CoreDataGeneratedAccessors)

- (void)addAttachmentsObject:(CAttachment *)value;
- (void)removeAttachmentsObject:(CAttachment *)value;
- (void)addAttachments:(NSSet *)values;
- (void)removeAttachments:(NSSet *)values;

@end
