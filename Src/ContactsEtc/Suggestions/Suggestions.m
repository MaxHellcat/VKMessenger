//
//  Requests.m
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Suggestions.h"
#import "CellSuggestion.h"
#import "VKReq.h"
#import "JSONKit.h"
#import "Cache.h"
#import "CFriendRequest.h"
#import "CFriendSuggestion.h"
#import "UIImageView+WebCache.h" // Images lazy load and caching
#import "AppDelegate.h"
#import "Controller.h"

@interface Suggestions ()

@end

@implementation Suggestions

@synthesize friendRequests;
@synthesize friendSuggestions;
@synthesize users;
@synthesize cellSuggestion;
@synthesize waitIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
//		self.title = NSLocalizedString(@"Contacts", @"Contacts");
		self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Contacts", @"Contacts")
														image:[UIImage imageNamed:@"DockContacts"] tag:0];
//		self.friendRequests = [[NSMutableArray alloc] init];
		self.friendSuggestions = [[NSMutableArray alloc] init];
//		self.users = [[NSMutableArray alloc] initWithObjects:self.friendRequests, self.friendSuggestions, nil];

//		for (int i=0; i<5; ++i)
//			[[self.users objectAtIndex:eFriendRequest] addObject:[NSString stringWithFormat:@"Request %i", i]];

//		for (int i=0; i<15; ++i)
//			[[self.users objectAtIndex:eFriendSuggestion] addObject:[NSString stringWithFormat:@"Suggestion %i", i]];

	}
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[self getFriendRequests];
	[self getFriendSuggestions];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

//	self.title = NSLocalizedString(@"Requests", @"Requests"); // Hidden by segmented control anyway
	self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Contacts", @"Contacts")
													image:[UIImage imageNamed:@"DockContacts"] tag:0];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	self.waitIndicator.center = CGPointMake(320.0f*0.5f, 480.0f*0.5-44.0f*2.0f);
	[self.view addSubview:self.waitIndicator];
	[self.view bringSubviewToFront:self.waitIndicator];

	[self readFriendRequestsFromCache];
//	[self getFriendRequests];

	[self readFriendSuggestionsFromCache];
//	[self getFriendSuggestions];
}

- (void)viewDidUnload
{
	[self setCellSuggestion:nil];
	[self setWaitIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark - Core Data related

- (void)readFriendRequestsFromCache
{
	self.friendRequests = [[Cache instance] fetch:@"CFriendRequest"
										   predicate:nil
									  sortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"nameLast" ascending:YES]];

//	[self.tableView setEditing:YES animated:YES];
}

- (void)readFriendSuggestionsFromCache
{
	self.friendSuggestions = [[Cache instance] fetch:@"CFriendSuggestion"
										   predicate:nil sortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"nameLast" ascending:YES]];
}

#pragma mark -
#pragma mark - Network Interaction

- (void)getFriendRequests
{
	[self.waitIndicator startAnimating];

	// TODO: Shorten this in release (at least white-spaces) to reduce traffic
	// Get list of user's contacts who have accounts in VK
	char code[] = "\
	 var requests = API.friends.getRequests(); \
	 var users = API.users.get({\"uids\":requests, \"fields\":\"uid,first_name,last_name,photo_medium_rec,online\"}); \
	 return {\"users\":users}; \
	 ";

	 [VKReq execute:[NSString stringWithUTF8String:code]
	 target:self
	 action:@selector(didGetFriendRequests:)
	 fail:@selector(didGetFriendRequestsFail:)];
}

- (void)didGetFriendRequestsFail:(VKReq *)req
{
	[self.waitIndicator stopAnimating];
}

// TODO: Execute in background
- (void)didGetFriendRequests:(VKReq *)req
{
	NSMutableDictionary * data = [req.responseData mutableObjectFromJSONData];
	if ([data objectForKey:@"error"]) // Check for error response
	{
		return ;
	}

	// Cache received friend requests
	id remoteUsers = [[data objectForKey:@"response"] objectForKey:@"users"];

//	NSLog(@"Got friend req response, array.count %i ", remoteUsers.count);

	if (![remoteUsers respondsToSelector:@selector(count)])
		return;

	// Just remove all existing friend requests before cache update
	for (CFriendRequest * user in self.friendRequests)
	{
		[[[Cache instance] managedObjectContext] deleteObject:user];
	}
	[[Cache instance] save];

	for (NSDictionary * remoteUser in remoteUsers)
	{
		CFriendRequest * request = [[Cache instance] createObjectInEntity:@"CFriendRequest"];
		request.uid = [remoteUser objectForKey:@"uid"];
		request.nameFirst = [[remoteUser objectForKey:@"first_name"] stringByReplacingOccurrencesOfString:@" " withString:@""];
		request.nameLast = [[remoteUser objectForKey:@"last_name"] stringByReplacingOccurrencesOfString:@" " withString:@""];
		request.photo = [remoteUser objectForKey:@"photo_medium_rec"]; // photo_rec for non-retina
		request.processed = [NSNumber numberWithBool:NO];
	}
	[[Cache instance] save];

	[self.waitIndicator stopAnimating];
	
//	[self performSelector:@selector(getSuggestions) withObject:nil afterDelay:10.0f];
}

- (void)getFriendSuggestions
{
	[self.waitIndicator startAnimating];

	// TODO: Shorten this in release (at least white-spaces) to reduce traffic
	// Get list of user's contacts who have accounts in VK
	char code[] = "\
	var suggestions = API.friends.getSuggestions({\"filter\":\"mutual,contacts,mutual_contacts\"}); \
	var users = API.users.get({\"uids\":suggestions@.uid, \"fields\":\"uid,first_name,last_name,photo_medium_rec\"}); \
	return {\"users\":users}; \
	";

	[VKReq execute:[NSString stringWithUTF8String:code]
			target:self
			action:@selector(didGetFriendSuggestions:)
			  fail:@selector(didGetFriendSuggestionsFail:)];
	
/*
	// Get list of user's contacts who have accounts in VK
	[VKReq method:@"friends.getSuggestions"
		 paramOne:@"filter" valueOne:@"mutual,contacts,mutual_contacts"
		   target:self action:@selector(didGetFriendSuggestions:) fail:@selector(didGetFriendSuggestionsFail:)];
*/
}

- (void)didGetFriendSuggestionsFail:(VKReq *)req
{
	[self.waitIndicator stopAnimating];
}

// TODO: Execute in background
- (void)didGetFriendSuggestions:(VKReq *)req
{
	NSMutableDictionary * data = [req.responseData mutableObjectFromJSONData];
	if ([data objectForKey:@"error"]) // Check for error response
	{
//		NSDictionary * errorDict = [data objectForKey:@"error"];
//		NSInteger errorCode = [[errorDict objectForKey:@"error_code"] integerValue];

//		if (errorCode == 9) // Flood control
//			[self performSelector:@selector(getSuggestions) withObject:nil afterDelay:60.0*5.0]; // Retry after 5 min
		
		return ;
	}

//	{"response":[{"uid":36850740,"first_name":"Юрий","last_name":"Сопин"},{"uid":91338493,"first_name":"Евгения","last_name":"Халимендик"}

	// Just remove all existing suggestions before cache update
	for (CFriendSuggestion * user in self.friendSuggestions)
	{
		[[[Cache instance] managedObjectContext] deleteObject:user];
	}
	[[Cache instance] save];

	// Cache received friend requests
	NSArray * remoteUsers = [[data objectForKey:@"response"] objectForKey:@"users"];
	for (NSDictionary * remoteUser in remoteUsers)
	{
		CFriendSuggestion * suggestion = [[Cache instance] createObjectInEntity:@"CFriendSuggestion"];

		suggestion.uid = [remoteUser objectForKey:@"uid"];
		suggestion.nameFirst = [[remoteUser objectForKey:@"first_name"] stringByReplacingOccurrencesOfString:@" " withString:@""];
		suggestion.nameLast = [[remoteUser objectForKey:@"last_name"] stringByReplacingOccurrencesOfString:@" " withString:@""];
		suggestion.photo = [remoteUser objectForKey:@"photo_medium_rec"]; // photo_rec for non-retina
		suggestion.processed = [NSNumber numberWithBool:NO];
	}
	[[Cache instance] save];

	[self.waitIndicator stopAnimating];

	[self readFriendSuggestionsFromCache];

	[self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == eFriendRequest)
		return [self.friendRequests count];
	else if (section == eFriendSuggestion)
		return [self.friendSuggestions count];
	else
		return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//	return self.users.count;
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == eFriendInvitation)
		return nil;
	else if (section == eFriendRequest)
		return NSLocalizedString(@"Friend requests", nil);
	else
		return NSLocalizedString(@"People you may know", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"CellSuggestion";
    CellSuggestion * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil)
	{
		[[NSBundle mainBundle] loadNibNamed:@"CellSuggestion_iPhone" owner:self options:nil];
		cell = self.cellSuggestion;
		self.cellSuggestion = nil;
	}

	cell.imageAvatar.hidden = NO;
	cell.buttonAdd.hidden = NO;
	cell.labelName.text = NSLocalizedString(@"Invite friends", nil);
	cell.accessoryType = UITableViewCellAccessoryNone;

	if (indexPath.section == eFriendRequest)
	{
		if (self.friendRequests.count)
		{
			CFriendRequest * friendRequest = [self.friendRequests objectAtIndex:indexPath.row];
			cell.labelName.text = [NSString stringWithFormat:@"%@ %@", friendRequest.nameFirst, friendRequest.nameLast];
			NSURL * url = [NSURL URLWithString:friendRequest.photo];
			[cell.imageAvatar setImageWithURL:url placeholderImage:[UIImage imageNamed:@"Avatar_placeholder"]];

			if (!friendRequest.processed)
			{
				// TODO: Show OK mark instead of + button
			}
		}
	}
	else if (indexPath.section == eFriendSuggestion)
	{
		if (self.friendSuggestions.count)
		{
			CFriendSuggestion * friendSuggestion = [self.friendSuggestions objectAtIndex:indexPath.row];

			cell.labelName.text = [NSString stringWithFormat:@"%@ %@", friendSuggestion.nameFirst, friendSuggestion.nameLast];
			NSURL * url = [NSURL URLWithString:friendSuggestion.photo];
			[cell.imageAvatar setImageWithURL:url placeholderImage:[UIImage imageNamed:@"Avatar_placeholder"]];

			if (!friendSuggestion.processed)
			{
				// TODO: Show OK mark instead of + button
				
			}
		}
	}
	else
	{
		cell.imageAvatar.hidden = YES;
		cell.buttonAdd.hidden = YES;
		cell.labelName.text = NSLocalizedString(@"Invite friends", nil);
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == eFriendRequest)
        return UITableViewCellEditingStyleDelete;
	else
		return UITableViewCellEditingStyleNone;


//	if (indexPath.section == eFriendRequest)
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == eFriendInvitation)
	{
//		[self.tabBarController setSelectedIndex:2];
		AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
		[delegate.segmentControl setSelectedSegmentIndex:0]; // Open Contacts segment
		[delegate.controller indexDidChangeForSegmentedControl:delegate.segmentControl];
	}
}

@end
