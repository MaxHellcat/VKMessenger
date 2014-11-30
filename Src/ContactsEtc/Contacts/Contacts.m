//
//  Contacts.m
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Contacts.h"
#import "CellContact.h"
#import <AddressBook/AddressBook.h>
#import "ContactDetails.h"
#import "VKReq.h"
#import "JSONKit.h"

@interface Contacts ()
@end

@implementation Contacts

@synthesize contacts;
@synthesize cellContact;
@synthesize phoneNumbers;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
		self.title = NSLocalizedString(@"Contacts", @"Contacts");
		self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Contacts", @"Contacts")
														image:[UIImage imageNamed:@"DockContacts"] tag:0];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

//	self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Contacts", @"Contacts")
//													image:[UIImage imageNamed:@"DockContacts"] tag:0];

//	self.navigationController = [[UINavigationController alloc] initWithRootViewController:self];
	
	[self readAddressBook]; // Read address book first

//	[self importContacts]; // Once refreshed, import contact phone numbers to VK for updates
}

- (void)viewDidUnload
{
	[self setCellContact:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// TODO: Should we limit the query string if user has lots of contacts
// This executes only once upon each application start
- (void)importContacts
{
//	NSLog(@"See string of all now: %@", self.phoneNumbers);

	NSString * phones = [self.phoneNumbers componentsJoinedByString:@","];
	
	// Send all user contact phones to the VK to obtain registered users/sugestions, etc
	[VKReq method:@"account.importContacts"
		 paramOne:@"contacts" valueOne:phones
		   target:self action:@selector(didImportContacts:) fail:@selector(didImportContactsFail:)];
}

- (void)didImportContactsFail:(VKReq *)req
{
	//	{"response":1}
}

//	{"error":{"error_code":9,"error_msg":"Flood control enabled for this action",
- (void)didImportContacts:(VKReq *)req
{
	NSMutableDictionary * data = [req.responseData mutableObjectFromJSONData];
	if ([data objectForKey:@"error"]) // Check for error response
	{
		NSDictionary * errorDict = [data objectForKey:@"error"];
		NSInteger errorCode = [[errorDict objectForKey:@"error_code"] integerValue];
		if (errorCode == 9) // Flood control
			[self performSelector:@selector(importContacts) withObject:nil afterDelay:60.0*5.0]; // Retry after 5 min
		return ;
	}

//	[self performSelector:@selector(getSuggestions) withObject:nil afterDelay:10.0f];
//	[self getSuggestions];
}

- (void)getSuggestions
{
	// Get list of user's contacts who have accounts in VK
	[VKReq method:@"friends.getSuggestions"
//		 paramOne:@"filter" valueOne:@"mutual,contacts,mutual_contacts"
		 paramOne:@"filter" valueOne:@"contacts"
		   target:self action:@selector(didGetSuggestions:) fail:@selector(didGetSuggestionsFail:)];
}

- (void)didGetSuggestionsFail:(VKReq *)req
{
}

- (void)didGetSuggestions:(VKReq *)req
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

}


// TODO: Execute in background
- (void)readAddressBook
{
	ABAddressBookRef myAddressBook = ABAddressBookCreate();
	
	NSArray * allPeople = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(myAddressBook);

	self.contacts = [[NSMutableArray alloc] initWithCapacity:allPeople.count];

	NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:allPeople.count];

	self.phoneNumbers = [[NSMutableArray alloc] initWithCapacity:allPeople.count];

	for (id record in allPeople)
	{
		NSString * firstName = nil;
		NSString * lastName = nil;

		// Retrieve contact details from address book
		CFTypeRef ref = 0;
		ref = ABRecordCopyValue((__bridge ABRecordRef)record, kABPersonFirstNameProperty);
		if (ref)
			firstName = (__bridge NSString *)ref;

		ref = ABRecordCopyValue((__bridge ABRecordRef)record, kABPersonLastNameProperty);
		if (ref)
			lastName = (__bridge NSString *)ref;

		if (!lastName)
			lastName = firstName;

		if (!lastName)
			continue;

		Contact * person = [[Contact alloc] init];
		person.nameFirst = firstName;
		person.nameLast = lastName;

		ABMultiValueRef phone = ABRecordCopyValue((__bridge ABRecordRef)record, kABPersonPhoneProperty);
		NSString * label;
		for(CFIndex i=0; i<ABMultiValueGetCount(phone); ++i)
		{
			label = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(phone, i);
			if ([label isEqualToString:(__bridge NSString *)kABPersonPhoneMobileLabel])
			{
				person.phone = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phone, i);
				[self.phoneNumbers addObject:person.phone];
			}
			else if ([label isEqualToString:(__bridge NSString *)kABPersonPhoneIPhoneLabel])
			{
				person.iphone = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phone, i);
				[self.phoneNumbers addObject:person.iphone];
			}
		}
		CFRelease(phone);

		[array addObject:person];
	}

	self.contacts = [self partitionObjects:array collationStringSelector:@selector(nameLast)]; // Split by sections
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
//	return [[UILocalizedIndexedCollation currentCollation] numberOfRowsInSection:section];
	
	return [[self.contacts objectAtIndex:section] count];
	
	//	return self.contacts.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//	return [[UILocalizedIndexedCollation currentCollation] numberOfSections];
	
	//we use sectionTitles and not sections
    return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	BOOL showSection = [[self.contacts objectAtIndex:section] count] != 0;
    //only show the section title if there are rows in the section
    return (showSection) ? [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section] : nil;
//    return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
//    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];

	//sectionForSectionIndexTitleAtIndex: is a bit buggy, but is still useable
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"CellContact";
    CellContact * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil)
	{
		[[NSBundle mainBundle] loadNibNamed:@"CellContact_iPhone" owner:self options:nil];
		cell = self.cellContact;
		self.cellContact = nil;
	}

	Contact * person = [[self.contacts objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([person.nameLast isEqualToString:person.nameFirst]) // We've made big efforts to make sure nameLast is not empty
		cell.labelContactPhoneName.text = [NSString stringWithFormat:@"%@", person.nameLast];
	else
		cell.labelContactPhoneName.text = [NSString stringWithFormat:@"%@ %@", person.nameFirst, person.nameLast];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Contact * contact = [[self.contacts objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	ContactDetails * details = [[ContactDetails alloc] initWithContact:contact];
	[self.navigationController pushViewController:details animated:YES];
}

@end

@interface Contact ()
@end

@implementation Contact
@synthesize nameFirst;
@synthesize nameLast;
@synthesize phone;
@synthesize iphone;
@synthesize hasAccount;
@end
