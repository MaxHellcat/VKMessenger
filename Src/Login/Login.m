//
//  ViewController.m
//  VKM
//
//  Created by Max on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Login.h"
#import "Register.h"

#import "Constants.h"

#import "JSONKit.h"

#import "VKReq.h"

#import "AppDelegate.h"


@implementation Login
@synthesize cellUser = _cellUser;
@synthesize textUser = _textUser;
@synthesize cellPassword = _cellPassword;
@synthesize textPassword = _textPassword;
@synthesize actIndicator = _actIndicator;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	[self.navigationItem setTitle:NSLocalizedString(@"Welcome", @"Welcome")];
	
	self.actIndicator.hidden = YES;
	

//	_actIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
}

- (void)viewDidUnload
{
	[self setCellUser:nil];
	[self setTextUser:nil];
	[self setCellPassword:nil];
	[self setTextPassword:nil];
	[self setActIndicator:nil];
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	}
	else
	{
	    return YES;
	}
}


#pragma mark - Table (owns user/password fields) methods 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath row] == 0) return _cellUser;
	if ([indexPath row] == 1) return _cellPassword;

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

// TODO: Where do we throw existing Login&NavController, upon entering 4x place?
- (IBAction)touchLogin:(id)sender
{
	// TODO: Filter user/password data first
	// TODO: Check email for correctness, has @ .
	if (_textUser.text.length==0 || _textPassword.text.length==0)
	{
		// TODO: Implement fields shaking here
		return ;
	}

	// TODO: Find better place for activity indicator
	[_actIndicator setHidden:NO];
	[_actIndicator startAnimating];

	[VKReq authWithLogin:_textUser.text password:_textPassword.text target:self action:@selector(authReqResponse:)];
}


#pragma mark VKReq response

- (void)authReqResponse:(VKReq *)req
{
	NSDictionary * data = [req.responseData objectFromJSONData];

	[_actIndicator setHidden:YES];
	[_actIndicator stopAnimating];

	// Success json example:
	// {"access_token":"9d77c727986d7668986d7668049870402D1986d986d76684bbc9b1bf8488de9", "expires_in":0,"user_id":85635407}
	// Error examples:
	// {"error":"invalid_client","error_description":"client_secret is undefined"}
	// {"error":"invalid_client","error_description":"Username or password is incorrect"}

	// TODO: Value names (error, error_description) - to constants
	// TODO: What if we get here captcha error, which is of form:
	// {"error":"need_captcha","captcha_sid":"804593216477","captcha_img":"http:\/\/api.vk.com\/captcha.php?sid=804593216477&s=1"}
	// Кроме этого тут были вопросы по поводу тестирования каптчи, для этого можно использовать метод captcha.force.
	if ([data valueForKey:@"error"]) // Check for error response 
	{
		// NSLog(@"Failed to authorize/login, error: %@, description: %@ ", [data valueForKey:@"error"], [data valueForKey:@"error_description"]);

		if ([[data valueForKey:@"error"] isEqualToString:@"need_captcha"]) // Handle captcha response
		{
			UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error" message:[data valueForKey:@"error"]
														 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[av show];
			return ;
		}

		UIAlertView * av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Auth error", nil)
													  message:NSLocalizedString(@"Auth error description", nil)
													 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[av show];
		return ;
	}

	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];

	// TODO: These three must be readonly, so move this callback to appdelegate (with all the conclusions)
	delegate.udAccessToken = [data objectForKey:@"access_token"]; // The access token is not tied to current user ip, so no further auth required
	delegate.udSecret = [data objectForKey:@"secret"]; // Only sent if asked for nohttps auth (we do)
	delegate.udUserId = [data objectForKey:@"user_id"]; // Only sent if asked for nohttps auth (we do)

	[delegate store]; // Trigger data persisting  now

	[delegate loadMessagesEtAl]; // Once authorized, load Messages, etc
}


// TODO: Perhaps animate
- (IBAction)touchRegister:(id)sender
{
	// NSLog(@"Register user NOW");

	Register * registerVC = [[Register alloc] initWithNibName:@"Register_iPhone" bundle:nil];

//	AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//	[[appDelegate naviController] pushViewController:registerVC animated:YES];

	[self.navigationController pushViewController:registerVC animated:NO];

//	[self.navigationController presentModalViewController:registerVC animated:YES]; // Slides from bottom to top

//	[self.navigationController presentViewController:registerVC animated:NO completion:nil];
	
//	[[[self view] window] setRootViewController:registerVC];
	

//	self.window.rootViewController = self.viewController;
}

- (IBAction)touchBackground:(id)sender
{
	// NSLog(@"Touched background");

	[self.view endEditing:TRUE];
//	[textLogin resignFirstResponder]; // Dismiss keyboard for specific textfield	
}

@end
