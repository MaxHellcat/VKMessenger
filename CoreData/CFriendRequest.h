//
//  CFriendRequest.h
//  VKM
//
//  Created by Max on 20.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CFriendRequest : NSManagedObject

@property (nonatomic, retain) NSString * nameFirst;
@property (nonatomic, retain) NSString * nameLast;
@property (nonatomic, retain) NSString * photo;
@property (nonatomic, retain) NSNumber * processed;
@property (nonatomic, retain) NSNumber * uid;

@end
