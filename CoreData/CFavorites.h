//
//  CFavorites.h
//  VKM
//
//  Created by Max on 20.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CFavorites : NSManagedObject

@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSString * nameFirst;
@property (nonatomic, retain) NSString * nameLast;

@end
