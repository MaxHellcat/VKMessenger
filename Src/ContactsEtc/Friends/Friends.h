//
//  Friends.h
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CellFriend;

@interface Friends : UITableViewController
<
NSFetchedResultsControllerDelegate,
UISearchDisplayDelegate,
UISearchBarDelegate
>

@property (strong, nonatomic) NSArray * friends;
@property (strong, nonatomic) NSArray * collatedFriends;
@property (strong, nonatomic) IBOutlet CellFriend * cellFriend;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView * waitIndicator;




@end
