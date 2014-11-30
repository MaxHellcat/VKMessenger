//
//  Friends.m
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Friends.h"
#import "Cache.h"
#import "CellFriend.h"

#import "CUser.h"
#import "ChatHistory.h"
#import "VKReq.h"
#import "JSONKit.h"

@interface Friends ()
@end

@implementation Friends

@synthesize friends=_friends;
@synthesize collatedFriends=_collatedFriends;
@synthesize cellFriend = _cellFriend;
@synthesize waitIndicator = _waitIndicator;

/*
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
	{
        // Custom initialization
    }
    return self;
}
*/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
		self.title = NSLocalizedString(@"Friends", @"Friends");
		self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Contacts", @"Contacts")
														image:[UIImage imageNamed:@"DockContacts"] tag:0];
		
		self.friends = [[NSArray alloc] init];
		self.collatedFriends = [[NSArray alloc] init];
    }
    return self;
}

- (void)readFriendsFromCache
{
	self.friends = [[Cache instance] fetch:@"CUser"
										   predicate:[NSPredicate predicateWithFormat:@"(friend == YES)"]
							sortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"nameLast" ascending:YES]];

	self.collatedFriends = [self partitionObjects:self.friends collationStringSelector:@selector(nameLast)];
}

- (void)getFriendRequests
{
	[self.waitIndicator startAnimating];

	[VKReq method:@"friends.get"
		 paramOne:@"fields" valueOne:@"uid,first_name,last_name,photo_medium_rec"
		 paramTwo:@"count" valueTwo:@"500"
		   target:self action:@selector(didGetFriends:) fail:@selector(didGetFriendsFail:)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)viewDidUnload
{
	[self setCellFriend:nil];
	[self setWaitIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.waitIndicator.center = CGPointMake(320.0f*0.5f, 480.0f*0.5-44.0f*2.0f);
	[self.view addSubview:self.waitIndicator];
	[self.view bringSubviewToFront:self.waitIndicator];

	[self readFriendsFromCache];

	[self getFriendRequests];
}

- (void)didGetFriendsFail:(VKReq *)req
{
	[self.waitIndicator stopAnimating];
}

- (void)didGetFriends:(VKReq *)req
{
	NSDictionary * data = [req.responseData mutableObjectFromJSONData];
	if ([data objectForKey:@"error"])
	{
//		UIAlertView * av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Auth error", nil)
//													  message:NSLocalizedString(@"Auth error description", nil)
//													 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		return ;
	}

	NSArray * remoteUsers = [data objectForKey:@"response"];

	// Add/update friends
	for (NSDictionary * remoteUser in remoteUsers)
	{
		NSArray * fetchedArray = [[Cache instance] fetch:@"CUser"
											   predicate:[NSPredicate predicateWithFormat:@"(uid == %i)", [[remoteUser objectForKey:@"uid"] integerValue]]];
		CUser * user = nil;
		if (fetchedArray.count)
		{
//			NSLog(@"UPDATE friend %@ (%i), first letter %@", [remoteUser objectForKey:@"last_name"], [[remoteUser objectForKey:@"uid"] intValue], user.nameFirstLetter);
			user = [fetchedArray objectAtIndex:0];
		}
		else // New user, add to cache
		{
//			NSLog(@"ADD friend %@ (%i), first letter %@", [remoteUser objectForKey:@"last_name"], [[remoteUser objectForKey:@"uid"] intValue], user.nameFirstLetter);
			user = [[Cache instance] createObjectInEntity:@"CUser"];
			[[Cache instance] save];

			user.uid = [remoteUser objectForKey:@"uid"];
			user.nameFirst = [[remoteUser objectForKey:@"first_name"] stringByReplacingOccurrencesOfString:@" " withString:@""];
			user.nameLast = [[remoteUser objectForKey:@"last_name"] stringByReplacingOccurrencesOfString:@" " withString:@""];
			user.online = [remoteUser objectForKey:@"online"];
			user.photo = [remoteUser objectForKey:@"photo_medium_rec"]; // photo_rec for non-retina
		}
		user.friend = [NSNumber numberWithBool:YES];
	}
	[[Cache instance] save];

	[self readFriendsFromCache];

	[self.waitIndicator stopAnimating];

	[self.tableView reloadData];
}

-(NSMutableArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector
{
	UILocalizedIndexedCollation * collation = [UILocalizedIndexedCollation currentCollation];
	
    NSInteger sectionCount = [[collation sectionTitles] count]; //section count is take from sectionTitles and not sectionIndexTitles
	
    NSMutableArray * unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
	
    //create an array to hold the data for each section
    for(int i = 0; i < sectionCount; i++)
    {
        [unsortedSections addObject:[NSMutableArray array]];
    }
	
    //put each object into a section
    for (id object in array)
    {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:index] addObject:object];
    }

    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];

    //sort each section
    for (NSMutableArray *section in unsortedSections)
    {
        [sections addObject:[collation sortedArrayFromArray:section collationStringSelector:selector]];
    }

    return sections;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self.collatedFriends objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	BOOL showSection = [[self.collatedFriends objectAtIndex:section] count] != 0;
    return (showSection) ? [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section] : nil;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"CellFriend";
    CellFriend * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    // Configure the cell...
	if (cell == nil)
	{
		[[NSBundle mainBundle] loadNibNamed:@"CellFriend_iPhone" owner:self options:nil];
		
		cell = self.cellFriend;
		self.cellFriend = nil;
	}

	CUser * friend = [[self.collatedFriends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];

	[cell makeUpWithUser:friend];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Init chat history for chosen friend
	CUser * friend = [[self.collatedFriends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	ChatHistory * chat = [[ChatHistory alloc] initWithUser:friend];

	// Set friend's avatar
//	CellFriend * cell = (CellFriend *)[self.tableView cellForRowAtIndexPath:indexPath];
//	[chat setHeaderAvatar:cell.imageAvatar.image];

	[self.navigationController pushViewController:chat animated:YES]; // Show the chat
}

@end
