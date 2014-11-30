//
//  Messages.h
//  VKM
//
//  Created by Max on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullToRefresh.h"
#import "VKReq.h"

@class RedPin;

@interface LatestDialogues : UITableViewController
<
NSFetchedResultsControllerDelegate,
UISearchDisplayDelegate,
UISearchBarDelegate,  // TODO: Do we need the UISearchBarDelegate?
PullToRefreshDelegate
>
{
	PullToRefreshView * _refreshView;
}


@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *waitIndicator;
@property (strong, nonatomic) IBOutlet UISearchDisplayController * searchController;
@property (strong, nonatomic) NSFetchedResultsController * latestMessages;
@property (nonatomic) BOOL loading;
@property (nonatomic) NSInteger readCount; // Number of read dialogues so far

@property (nonatomic, strong) RedPin * pin;

@end

@interface LatestDialogues (Network)
- (void)readLatestDialogues;
- (void)didGetDialogs:(VKReq *)req;
- (void)didGetDialogsFail:(VKReq *)req;
- (void)readUnreadMessagesCountWithOffset:(NSInteger)offset;
@end
