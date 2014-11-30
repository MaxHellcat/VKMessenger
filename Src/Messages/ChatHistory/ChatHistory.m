//
//  Dialogue.m
//  VKM
//
//  Created by Max on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatHistory.h"
#import "CellChatHistory.h"
#import "VKReq.h"
#import "JSONKit.h"
#import "AppDelegate.h"

#import "CUser.h"
#import "CMessage.h"
#import "CChat.h"

#import "Cache.h"
#import <CoreLocation/CoreLocation.h>

#import "UIImageView+WebCache.h"


@interface ChatHistory ()
//@property (strong, nonatomic) User * user;
@end


@implementation ChatHistory
@synthesize tableView = _tableView;
@synthesize toolbar = _toolbar;
@synthesize messages = _messages;
@synthesize message=_message;
@synthesize user=_user;
@synthesize waitIndicator = _waitIndicator;
@synthesize isChat=_isChat;
@synthesize headerAvatar=_headerAvatar;

//static float kKeyboardOriginY = 264.0f-44.0f-20.0f;
//static float kAnimationDuration = 0.25f; // Like keyboard
//static int kAnimationCurve = UIViewAnimationCurveEaseInOut; // Like keyboard

// Generally called from Friends
- (id)initWithUser:(CUser *)user
{
	self = [super initWithNibName:@"ChatHistory_iPhone" bundle:nil];
	if (self)
	{
		self.hidesBottomBarWhenPushed = YES;

		// Get user's latest message and ref to the maintained one, always single chat
		NSSet * latestForUser = [user.messages objectsPassingTest:^(CMessage * message, BOOL * stop)
			   {
				   return (BOOL)(message.latest.boolValue==YES && message.chat==NULL);
			   }];

		// We may well pass friend, which we don't have cached messages for
		if (latestForUser.count)
			self.message = [latestForUser anyObject];
		self.user = user;

		self.isChat = NO;
	}

	return self;
}

// Generally called from latest dialogues
- (id)initWithMessage:(CMessage *)message
{
	self = [super initWithNibName:@"ChatHistory_iPhone" bundle:nil];
	if (self)
	{
		self.hidesBottomBarWhenPushed = YES;
		self.message = message;
		self.user = message.user;
		self.isChat = (BOOL)(message.chat!=NULL);
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

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	_messages.delegate = self;

	// For group chats no photo is shown, but button with chat members count (including myself)
	if (self.isChat)
	{
		UIButton * barButton = [UIButton buttonWithType:UIButtonTypeCustom];

		UIImage * image = [[UIImage imageNamed:@"Header_Button"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:15.0f];
		[barButton setBackgroundImage:image forState:UIControlStateNormal];

		[barButton setImage:[UIImage imageNamed:@"Header_MultiChat"] forState:UIControlStateNormal];
		[barButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 17.0f, 0.0f, 0.0f)];

		barButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
//		barButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
		barButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, -54.0f, 0.0f, 0.0f);

		[barButton setTitle:[NSString stringWithFormat:@"%i", _message.chat.members.count+1] forState:UIControlStateNormal];

		[barButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[barButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
		[barButton setTitleShadowColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];

		barButton.frame = CGRectMake(0, 0, 50.0f, 30);

		UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:barButton];
		self.navigationItem.rightBarButtonItem = item;

		[self.navigationItem setTitle:_message.chat.title]; // Update navigation bar with vis-a-vis name
	}
	else
	{
		// Obtain foto from chosen cell's lazy loaded image view, no delays
		UIImageView * avatarFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Header_Avatar"]];

		NSURL * url = [NSURL URLWithString:self.user.photo];
		UIImageView * avatarImage = [[UIImageView alloc] init]; // Quickly picked-up from cache, cos we did load it
		[avatarImage setImageWithURL:url];

		[avatarImage setFrame:CGRectMake(0.0f, 0.0f, 27.0f, 28.0f)];
		avatarImage.layer.masksToBounds = YES; // Slow for table cells, but ok here
		avatarImage.layer.cornerRadius = 4.0f;
		avatarImage.center = avatarFrame.center;

		[avatarFrame addSubview:avatarImage];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:avatarFrame];

		[self.navigationItem setTitle:_message.user.nameFirst]; // Update navigation bar with vis-a-vis name
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	_messages.delegate = nil;
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

	// Table view
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	[self.tableView.backgroundView setContentMode:UIViewContentModeCenter];
	self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background"]];

	// Toolbar
	_toolbar.frame = CGRectMake(0.0f, // Position toolbar properly
								self.view.frame.size.height-50.0f,
								_toolbar.frame.size.width,
								_toolbar.frame.size.height);
	_toolbar.delegate = self;
	[self.view addSubview:_toolbar];

	// PullToRefresh view underneath the table view
/*
	_refreshView = [[PullToRefreshView alloc]
					initWithFrame:CGRectMake(0.0f,
											 self.tableView.bounds.size.height,
											 self.view.frame.size.width,
											 self.tableView.bounds.size.height) header:NO];
 
//	_refreshView.delegate = self;
//	[self.tableView addSubview:_refreshView];
*/

	[self readCache]; // First read cached data

	[self readChatHistory]; // Once restored, ask VK for the updates
}

// So, what do we do here man
// User already has user.messages set which we can access nicely
// The problem is that any changes to those of them not-recent won't be caught by the core data
// Solution 1: Anyway init fetch controller on Message with user.uid==uid, but user.messages are just wasted
// Solution 2: 
- (void)readCache
{
//	[NSFetchedResultsController deleteCacheWithName:@"ChatHistory"];
//	[NSFetchedResultsController deleteCacheWithName:@"LatestMessages"];

	if (_isChat)
	{
		_messages = [[Cache instance]
					 fetchController:@"CMessage"
					 predicate:[NSPredicate predicateWithFormat:@"(chat.cid==%i)", _message.chat.cid.intValue]
					 sortDescriptor:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] // Oldest first/on top
				 sectionNameKeyPath:nil
					 delegate:self]; // We're keen to handle changes
	}
	else
	{
		_messages = [[Cache instance]
				 fetchController:@"CMessage"
//				 predicate:[NSPredicate predicateWithFormat:@"(user.uid==%i AND chat==NULL)", _message.user.uid.intValue]
					 predicate:[NSPredicate predicateWithFormat:@"(user.uid==%i AND chat==NULL)", self.user.uid.intValue]
				 sortDescriptor:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] // Oldest first/on top
			 sectionNameKeyPath:nil
				 delegate:self]; // We're keen to handle changes
	}
}

// TODO: All properties to nil please
- (void)viewDidUnload
{
//	[self setUser:nil]; // Beware here, this is core data managed object
	[self setTableView:nil];
	[self setToolbar:nil];
	

	[self setWaitIndicator:nil];
    [super viewDidUnload];

	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Table data source

// Beware of reused cells of different height
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// TODO: I believe it's not the smartest solution to shift pulltorefresh view on each cell visible
	_refreshView.frame = CGRectMake(0.0f,
									MAX(self.tableView.contentSize.height, self.tableView.frame.size.height),
									self.view.frame.size.width,
									self.tableView.bounds.size.height);

	static NSString * cellId = @"CellChatHistory";
    CellChatHistory * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	if (cell == nil)
		cell = [[CellChatHistory alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
	
	[cell setMessage:[_messages objectAtIndexPath:indexPath]];

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [CellChatHistory cellHeightWithMessage:[_messages objectAtIndexPath:indexPath]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//	return 1;
	return [[_messages sections] count]; // Only one anyway
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[_messages sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
//	return @"This is footer!";
	return nil;
}

// Light blue color for unread message
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	CMessage * message = [self.messages objectAtIndexPath:indexPath];
	if (!message.read.boolValue)
		cell.backgroundColor = [UIColor colorWithRed:0.7412f green:0.7961f blue:0.8627f alpha:0.5f];

/*
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
*/
}


//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//	return [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 20.0f)];
//}

// TODO: See if we need to set header
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[_toolbar.textField resignFirstResponder]; // Dismiss keyboard, if any

	[_toolbar slideDown];

	[self shiftTableUp:NO];
	
//	CMessage * message = [_messages objectAtIndexPath:indexPath];

/*
	NSLog(@"Message %i, attType %i, attCount %i, user %@, photo %@ - %@",
		  message.mid.intValue,
		  message.attachmentType.intValue,
		  message.attachments.count,
		  message.user.nameLast,
		   message.user.photo,
		  message.text);
 */
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate related

// Providing an empty implementation of controllerDidChangeContent: is sufficient.
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{
	CellChatHistory * cell = (CellChatHistory *)[_tableView cellForRowAtIndexPath:indexPath];

	if (type==NSFetchedResultsChangeInsert)
	{
		[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
		// NSLog(@"CH INSERT into row at %i, new %i", indexPath.row, newIndexPath.row);
	}
	else if (type==NSFetchedResultsChangeDelete)
	{
		[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
		// NSLog(@"CH DELETE");
	}
	else if (type==NSFetchedResultsChangeUpdate)
	{
//		[self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
		[cell setMessage:[_messages objectAtIndexPath:indexPath]];
		// NSLog(@"CH UPDATE"); // Don't do frequent updates here in favour of faster reloadData
	}
	else if (type==NSFetchedResultsChangeMove)
	{
//		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//		[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
		// NSLog(@"CH MOVE");
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView endUpdates];
	
	// Scroll to the bottom, to show the newest messages
//	if (self.tableView.contentSize.height > self.tableView.frame.size.height) 
  //  {
//        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
//        [self.tableView setContentOffset:offset animated:YES];
//    }
	
	 NSInteger n = [[[self.messages sections] objectAtIndex:0] numberOfObjects];
//	 // NSLog(@"DidSendMessage, rows %i", n);
	 NSIndexPath * indexPath = [NSIndexPath indexPathForRow:(n-1) inSection:0];
	 [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition: UITableViewScrollPositionTop animated: YES];

}

#pragma mark - Keyboard notifications

/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}
*/

- (void)keyboardWillShow:(NSNotification *)notification
{
	NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

	[_toolbar slideUp];

	// TODO: The performSelector waits till table view stops scrolling (if it is), then actually calls method
//	[self performSelector:@selector(shiftTable) withObject:nil afterDelay:0.1f];
	[self shiftTableUp:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
}

- (void)didResize:(Toolbar *)toolbar
{
//	[self performSelector:@selector(shiftTable) withObject:nil afterDelay:0.1f];
	[self shiftTableUp:YES];
}

- (void)shiftTableUp:(BOOL)up
{
	[UIView animateWithDuration:0.25f delay:up?0.2f:0.0f options:UIViewAnimationOptionAllowUserInteraction
					 animations:^
	 {
		 CGRect frame = _tableView.frame;
		 frame.origin.y = _toolbar.frame.origin.y-frame.size.height;
		 _tableView.frame = frame;
	 }
					 completion:nil];
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

- (void)pullToRefreshDidTriggerRefresh:(PullToRefreshView *)view
{
	[self readChatHistory];
}

#pragma mark -
#pragma mark Action handlers

- (void)touchBack:(id)sender // Left navigation item
{
	[self.navigationController popViewControllerAnimated:YES];
}

// TODO: Don't send empty message
/*
- (void)touchSend:(id)sender
{
	NSString * text = [_toolbar.textField.text urlEncodeUsingEncoding:NSUTF8StringEncoding]; // TODO: Encode before sending
	[VKReq messageSend:text toUid:_uid target:self action:@selector(didGetMessageSendResponse:)];
}
*/

//- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;        // return NO to disallow editing.
/*
- (void)textFieldDidBeginEditing:(UITextField *)textField;           // became first responder
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField;          // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
- (void)textFieldDidEndEditing:(UITextField *)textField;             // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called



- (BOOL)textFieldShouldClear:(UITextField *)textField;               // called when clear button pressed. return NO to ignore (no notifications)
- (BOOL)textFieldShouldReturn:(UITextField *)textField;   
*/


/*
- (IBAction)touchCamera:(id)sender
{
	UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	imagePicker.delegate = self;
//	imagePicker.allowsImageEditing = NO;
	[self presentModalViewController:imagePicker animated:YES];
}

- (IBAction)touchGeo:(id)sender
{
	CLLocationManager * lm = [[CLLocationManager alloc] init];
//	lm.delegate = self;
	
//	[lm s]
}
*/


- (IBAction)touchCamera:(id)sender
{
}


- (IBAction)touchGeo:(id)sender {
}

@end
