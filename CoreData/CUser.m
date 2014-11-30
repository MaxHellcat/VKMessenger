//
//  CUser.m
//  VKM
//
//  Created by Max on 20.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CUser.h"
#import "CChat.h"
#import "CMessage.h"


@implementation CUser

@dynamic friend;
@dynamic nameFirst;
@dynamic nameLast;
@dynamic online;
@dynamic photo;
@dynamic uid;
@dynamic adminOfChats;
@dynamic memberOfChats;
@dynamic messages;

// TODO: Move to category somewhere
- (NSString *)nameFirstLetter
{
	//	return [self.nameLast substringWithRange:[self.nameLast rangeOfComposedCharacterSequenceAtIndex:1]];

//	[self willAccessValueForKey:@"nameFirstLetter"];
	NSString * stringToReturn = [self.nameLast substringToIndex:1];
//	[self didAccessValueForKey:@"nameFirstLetter"];

	NSLog(@"Called nameFirstLetter, returning %@", stringToReturn);

	return stringToReturn;
}


@end
