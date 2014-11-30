//
//  CAttachment.h
//  VKM
//
//  Created by Max on 20.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CMessage;

@interface CAttachment : NSManagedObject

@property (nonatomic, retain) NSNumber * aid;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSString * src;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) CMessage *message;

@end
