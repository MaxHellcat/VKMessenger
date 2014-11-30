//
//  Messages.m
//  VKM
//
//  Created by Max on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LatestDialogues.h"
#import "CellLatestDialogue.h"
#import "ChatHistory.h"
#import "JSONKit.h"
#import "VKReq.h"
#import "QuartzCore/QuartzCore.h" // For fast image corner rounding

#import "CMessage.h"
#import "CUser.h"
#import "CAttachment.h"
#import "CChat.h"

#import "Cache.h"

#import "UIImageView+WebCache.h" // Images lazy load and caching

#import "AppDelegate.h"

#import "Controller.h" // To quickly jump to friends on message compose touch

#import "RedPin.h"


@implementation LatestDialogues

@synthesize waitIndicator = _waitIndicator;
@synthesize searchController;
@synthesize latestMessages = _latestMessages;
@synthesize loading = _reloading;
@synthesize readCount = _readCount;
@synthesize pin = _pin;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
		self.title = NSLocalizedString(@"Messages", @"Messages");
		_reloading = NO;
		_readCount = 0;
    }
    return self;
}

// TODO: Handle please
- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];

	// Mesage compose button on the navigation bar, in the right
	// ORIGINAL
	UIImage * image = [[UIImage imageNamed:@"Header_Button"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:15.0f];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
																						   target:self action:@selector(touchCompose:)];
	[self.navigationItem.rightBarButtonItem setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

//	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
//																						  target:self action:@selector(touchMessage:)];
	// Mesage compose button on the navigation bar, in the right
//	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//																						   target:self action:@selector(touchUser:)];

	// The navbar tab title/image
	self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Messages", @"Messages")
													image:[UIImage imageNamed:@"DockMessages"] tag:0];

	// PullToRefresh view above the table
	_refreshView = [[PullToRefreshView alloc]
					initWithFrame:CGRectMake(0.0f,
											 0.0f-self.tableView.bounds.size.height,
											 self.view.frame.size.width,
											 self.tableView.bounds.size.height) header:YES];
	_refreshView.delegate = self;
	[self.tableView addSubview:_refreshView];

	// TODO: Configure indicator here as to where it should on first show
	[self.tableView addSubview:self.waitIndicator];
	self.waitIndicator.hidden = YES;

	// Ask our cache for the latest dialogues, before we make any requests to VK
	[self readCache];

	self.waitIndicator.center = CGPointMake(320.0f*0.5f, 480.0f*0.5f-44.0f*2.0f);
	[self.waitIndicator startAnimating];

	[self refreshData];

//	[self performSelectorInBackground:@selector(readLatestDialogues) withObject:nil];
//	[self readLatestDialogues]; // Once restored from cache, ask VK for the updates
}

- (void)readCache
{
//	[NSFetchedResultsController deleteCacheWithName:@"LatestMessages"];

	_latestMessages = [[Cache instance]
					   fetchController:@"CMessage"
					   predicate:[NSPredicate predicateWithFormat:@"(latest == YES)"]
					   sortDescriptor:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] // Newest first
					   sectionNameKeyPath:nil
					   delegate:self];

//	[[Cache instance] usersFetchController:nil];
}

// TODO: All properties to nil, please
- (void)viewDidUnload
{
	[self setSearchController:nil];
	[self setLatestMessages:nil];
	[self setWaitIndicator:nil];

	[super viewDidUnload];
}

// TODO: Do we update the list upon return from ChatHistory? Message are quite likely to have changed
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self readUnreadMessagesCountWithOffset:0];

//	[self refreshData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Table data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tableView)
    {}
    else // Search controller fork
    {}

	static NSString * cellId = @"CellLatestDialogue";
    CellLatestDialogue * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	if (cell == nil)
		cell = [[CellLatestDialogue alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];

	[cell makeUpWithMessage:[_latestMessages objectAtIndexPath:indexPath]];

	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//	return 1;
	return [[_latestMessages sections] count]; // Only one anyway
}

// TODO: If we get 0 here, reflect that on screen (user doesn't yet have any messages)
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.tableView)
    {    }
    else
    {    }

	id <NSFetchedResultsSectionInfo> sectionInfo = [[_latestMessages sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

// Light blue color for unread message
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	CMessage * message = [_latestMessages objectAtIndexPath:indexPath];
	if (![message.read boolValue])
		 cell.backgroundColor = [UIColor colorWithRed:0.9216f green:0.9412f blue:0.9608f alpha:1.0f];

	// TODO: If user has scrolled down to the bottom, load next 20 records
	NSInteger rows = [[self.latestMessages.sections objectAtIndex:0] numberOfObjects];
	if (indexPath.row == rows-1 && !self.loading)
	{
		CGSize contentSize = self.tableView.contentSize;
		contentSize.height += 50.0f;
		[self.tableView setContentSize:contentSize];

		self.waitIndicator.center = CGPointMake(contentSize.width*0.5f, contentSize.height-30.0f);
		[self.waitIndicator startAnimating];

		self.readCount += 20;
		[self readLatestDialogues];
	}
}

// TODO: Silently preload each of first 20 last dialogs history
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.tableView)
    {
		NSLog(@"Clicked on cell of DIALOGS controller");
    }
    else
    {
		NSLog(@"Clicked on cell of SEARCH controller");
    }

// TODO: Note that self still continues to listen for core data changes (according to its fetched controller predicate)
	CMessage * message = [_latestMessages objectAtIndexPath:indexPath];
	ChatHistory * chat = [[ChatHistory alloc] initWithMessage:message];

//	CellLatestDialogue * cell = (CellLatestDialogue *)[self.tableView cellForRowAtIndexPath:indexPath];
//	[chat setHeaderAvatar:cell.imageAuthor.image];

	[self.navigationController pushViewController:chat animated:YES];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate related

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{
	CMessage * message = anObject;
//	NSLog(@"WARNING: We MUST NOT update table if we are NOT VISIBLE!");	
//	if (self.view.window)
//		NSLog(@"We are visible");
//	else
//		NSLog(@"We are NOT visible");
	
	UITableView * tableView = self.tableView;
	CellLatestDialogue * cell = (CellLatestDialogue *)[tableView cellForRowAtIndexPath:indexPath];

	if (type == NSFetchedResultsChangeInsert)
	{
		[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
	}
	else if (type == NSFetchedResultsChangeDelete)
	{
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	}
	else if (type == NSFetchedResultsChangeUpdate)
	{
		[cell makeUpWithMessage:message];
	}
	else if (type == NSFetchedResultsChangeMove)
	{
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
		[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView endUpdates];
}

- (void)touchCompose:(id)sender
{
	// Let it be so
	[self.tabBarController setSelectedIndex:2]; // Head to contacts
	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
	[delegate.segmentControl setSelectedSegmentIndex:1];
	[delegate.controller indexDidChangeForSegmentedControl:delegate.segmentControl];

/*
	NSLog(@"See Messages:");
	int i = 0;

	NSArray * arr = [[Cache instance] fetch:@"CMessage"
									predicate:nil sortDescriptor:[[NSSortDescriptor alloc]
																  initWithKey:@"date" ascending:NO]];
	for (CMessage * message in arr)
	{
		NSLog(@"Message %i, mid %i, from %@, isGroup %i, attaches %i, text: %@",
			  i++,
			  [message.mid intValue],
			  message.user.nameLast,
			  (message.chat!=NULL),
			  message.attachments.count,
			  message.text);
	}
 */
}

#pragma mark -
#pragma mark PullToRefreshDelegate related

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[_refreshView parentViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[_refreshView parentViewDidEndDragging:scrollView];
}

// TODO: Here must drop all records > 20
- (void)pullToRefreshDidTriggerRefresh:(PullToRefreshView *)view
{
	[self refreshData];

//	[self performSelectorInBackground:@selector(readLatestDialogues) withObject:nil];

//	NSThread * thread = [[NSThread alloc] init];
//	[self performSelector:@selector(readLatestDialogues) onThread:thread withObject:nil waitUntilDone:NO];
}

- (void)refreshData
{
	self.readCount = 0;
	[self readLatestDialogues];
	[self readUnreadMessagesCountWithOffset:0];
}

#pragma mark -
#pragma mark UISearchDisplayDelegate related

// TODO: Implement search asap!
- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
//	NSLog(@"searchDisplayControllerDidBeginSearch");
}

// TODO: Implement search asap!
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
//	NSLog(@"searchDisplayControllerDidEndSearch");
}

#pragma mark -
#pragma mark UISearchBarDelegate related

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
//	NSLog(@"searchBar textDidChange");
}


@end
