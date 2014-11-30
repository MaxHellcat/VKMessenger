//
//  Favorites.m
//  VKM
//
//  Created by Max on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Favorites.h"
#import "Cache.h"
#import "CellFavorites.h"
#import "AppDelegate.h"
#import "Controller.h"

@implementation Favorites

@synthesize tableView;
@synthesize favorites;
@synthesize cellFavorite;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
		self.title = NSLocalizedString(@"Favorites", @"Favorites");
		self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Favorites", @"Favorites")
														image:[UIImage imageNamed:@"DockFaves"] tag:0];
    }
    return self;
}

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

	self.favorites = [[Cache instance] fetch:@"CFavorites"
								   predicate:nil
							  sortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"nameLast" ascending:YES]];

	[self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Edit button on nav bar's left
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
																						  target:self action:@selector(touchEdit:)];
	[self.navigationItem.leftBarButtonItem setBackgroundImage:[UIImage imageNamed:@"Header_Button"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

	// Add button on nav bar's right
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						   target:self action:@selector(touchAdd:)];
	[self.navigationItem.rightBarButtonItem setBackgroundImage:[UIImage imageNamed:@"Header_Button"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

- (void)viewDidUnload
{
	[self setTableView:nil];
	[self setCellFavorite:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table View

/*
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return self.keys;
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [self.keys objectAtIndex:section];
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.favorites.count)
		return self.favorites.count;
	else
		return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"CellFavorites";

    CellFavorites * cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
//		cell = [[CellFavorites alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		[[NSBundle mainBundle] loadNibNamed:@"CellFavorites_iPhone" owner:self options:nil];
		cell = self.cellFavorite;
		self.cellFavorite = nil;
    }

	if (self.favorites.count)
	{
		cell.labelName.text = [self.favorites objectAtIndex:indexPath.row];
	}
	else
	{
//		if (indexPath.row == 0)
		cell.buttonDisclosure.hidden = YES;
		cell.labelName.font = [UIFont systemFontOfSize:14.0];
		cell.labelName.textColor = [UIColor lightGrayColor];

		CGPoint center = cell.labelName.center;
		center.x = 320.0f/2.0f;
		cell.labelName.center = center;

		cell.labelName.textAlignment = UITextAlignmentCenter;
		cell.labelName.text = NSLocalizedString(@"Favorites list empty", nil);
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
	{
//	[_objects removeObjectAtIndex:indexPath.row];
//	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
	else if (editingStyle == UITableViewCellEditingStyleInsert)
	{
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
/*
    if (!self.detailViewController)
	{
        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    }
    NSDate *object = [_objects objectAtIndex:indexPath.row];
    self.detailViewController.detailItem = object;
    [self.navigationController pushViewController:self.detailViewController animated:YES];
*/
}



#pragma mark - Touch handlers

- (void)touchEdit:(id)sender
{
//	NSLog(@"Edit favorites list NOW");
}

- (void)touchAdd:(id)sender
{
	[self.tabBarController setSelectedIndex:2]; // Head to Contacts
	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
	[delegate.segmentControl setSelectedSegmentIndex:0]; // Open first segment
	[delegate.controller indexDidChangeForSegmentedControl:delegate.segmentControl];
}

@end
