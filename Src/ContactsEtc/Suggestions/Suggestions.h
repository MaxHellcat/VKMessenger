//
//  Requests.h
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CellSuggestion;

typedef enum { eFriendInvitation=0, eFriendRequest, eFriendSuggestion} CellType;

@interface Suggestions : UITableViewController // <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSArray * friendRequests;
@property (strong, nonatomic) NSArray * friendSuggestions;

@property (strong, nonatomic) NSMutableArray * users;
@property (strong, nonatomic) IBOutlet CellSuggestion * cellSuggestion;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *waitIndicator;


@end
