//
//  ContactDetailsViewController.m
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContactDetails.h"
#import "QuartzCore/QuartzCore.h"
#import "Contacts.h" // For Contact
#import "MessageUI/MessageUI.h" // Send invitation SMS


@interface ContactDetails ()
@end

@implementation ContactDetails
@synthesize cellPhone;
@synthesize cellIPhone;
@synthesize labelPhone;
@synthesize labelIPhone;
@synthesize labelContactName;
@synthesize imageAvatar;
@synthesize buttonAddOrInvite;
@synthesize buttonAddToFavorites;
@synthesize contact=_contact;


- (IBAction)touchAddToFavorite:(id)sender
{
	//NSLog(@"Add to favorite NOW!");
}

- (id)initWithContact:(Contact *)contact
{
	self = [super initWithNibName:@"ContactDetails_iPhone" bundle:nil];
    if (self)
	{
		self.hidesBottomBarWhenPushed = YES;
		self.contact = contact;
    }

    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
		self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Custom back button
	UIImage * image = [[UIImage imageNamed:@"Header_Back"] stretchableImageWithLeftCapWidth:15.0f topCapHeight:15.0f];
	UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Back") // Back is in official description
															  style:UIBarButtonItemStylePlain
															 target:self
															 action:@selector(touchBack:)];
	[item setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	self.navigationItem.leftBarButtonItem = item;

	self.imageAvatar.image = [UIImage imageNamed:@"Avatar_placeholder"];
	self.imageAvatar.layer.masksToBounds = YES;
	self.imageAvatar.layer.cornerRadius = 8.0f;

//	UIImageView * avatarFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Profile_Avatar"]];
//	[self.imageAvatar addSubview:avatarFrame];


//	NSLog(@"Open contact %@, phone %@, iphone %@", _contact.nameLast, _contact.phone, _contact.iphone);

	if ([_contact.nameLast isEqualToString:_contact.nameFirst])
	{
		self.labelContactName.text = self.contact.nameLast;
		[self.navigationItem setTitle:self.contact.nameLast];
	}
	else
	{
		self.labelContactName.text = [NSString stringWithFormat:@"%@ %@", _contact.nameFirst, _contact.nameLast];
		[self.navigationItem setTitle:[NSString stringWithFormat:@"%@ %@", _contact.nameFirst, _contact.nameLast]];
	}

	self.labelPhone.text = _contact.phone;
	self.labelIPhone.text = _contact.iphone;

	if (_contact.hasAccount)
		[self.buttonAddOrInvite setTitle:NSLocalizedString(@"Send message", @"Send message") forState:UIControlStateNormal];
	else
		[self.buttonAddOrInvite setTitle:NSLocalizedString(@"Send invitation", @"Send invitation") forState:UIControlStateNormal];

	[self.buttonAddToFavorites setTitle:NSLocalizedString(@"Add to favorites", nil) forState:UIControlStateNormal];
		
}

- (void)viewDidUnload
{
	[self setCellPhone:nil];
	[self setCellIPhone:nil];
	[self setLabelPhone:nil];
	[self setLabelIPhone:nil];
	[self setLabelContactName:nil];
	[self setImageAvatar:nil];
	[self setButtonAddOrInvite:nil];
    [self setButtonAddToFavorites:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark -
#pragma mark - Table data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath row] == 0) return self.cellPhone;
	if ([indexPath row] == 1) return self.cellIPhone;

	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

- (void)touchBack:(id)sender // Left navigation item
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Action handlers

- (IBAction)touchAddOrInvite:(id)sender
{
	if (self.contact.hasAccount)
	{
		// TODO: Open chat history for current contact
//		User * friend = [self.friends objectAtIndexPath:indexPath];
//		ChatHistory * chat = [[ChatHistory alloc] initWithUser:friend];

		// Set friend's avatar for chat
//		CellFriend * cell = (CellFriend *)[self.tableView cellForRowAtIndexPath:indexPath];
//		[chat setHeaderAvatar:cell.imageAvatar.image];

//		[self.navigationController pushViewController:chat animated:YES]; // Show the chat
	}
	else
	{
		MFMessageComposeViewController * vc = [[MFMessageComposeViewController alloc] init];
		if ([MFMessageComposeViewController canSendText])
		{
			vc.body = NSLocalizedString(@"Invite you to install", nil);
			vc.recipients = [NSArray arrayWithObjects:self.contact.phone, self.contact.iphone, nil];
			vc.messageComposeDelegate = self;
			[self presentModalViewController:vc animated:YES];
		}
	}
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	if (result == MessageComposeResultCancelled)
	{}
	else if (result == MessageComposeResultFailed)
	{}
	else if (result == MessageComposeResultSent)
	{}

	[self dismissModalViewControllerAnimated:YES];
}

@end
