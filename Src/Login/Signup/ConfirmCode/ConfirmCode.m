//
//  ConfirmCode.m
//  VKM
//
//  Created by Max on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ConfirmCode.h"
#import "Constants.h"
#import "JSONKit.h"
#import "VKReq.h"

#import "Login.h" // TODO: This is ugly


@implementation ConfirmCode

@synthesize phoneNumber=_phoneNumber;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil phoneNumber:(NSString *)phoneNumber
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
		self.phoneNumber = phoneNumber;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    _cellCode = nil;
    _textCode = nil;
	_cellPassword = nil;
	_textPassword = nil;

    [super viewDidUnload];

	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)touchConfirm:(id)sender
{
	if (_textCode.text.length==0 || _textPassword.text.length==0 /*|| _textPassword.text.length<6*/)
	{
		// TODO: Implement fields shaking here
		return ;
	}

	// Note: This req seemed to succeed without sending access_token (which is obvious)
	NSString * uri = [NSString stringWithFormat:@"https://api.vk.com/method/auth.confirm?phone=%@&code=%@&password=%@&client_id=%@&client_secret=%@",
					  [_phoneNumber urlEncodeUsingEncoding:NSUTF8StringEncoding], // Must encode phone number (actually only leading +)
					  _textCode.text,
					  [_textPassword.text urlEncodeUsingEncoding:NSUTF8StringEncoding], // Password's length >=6
					  kClientId,
					  kClientSecret];

	VKReq * req = [[VKReq alloc] initWithTarget:self action:@selector(didGetResponse:) fail:nil];
	[req get:uri];
}

- (void)didGetResponse:(VKReq *)req
{
	NSDictionary * dict = [req.responseData objectFromJSONData]; // Parse auth.signup output json

	// TODO: Value names - to external depot
	if ([dict objectForKey:@"error"])
	{
		NSDictionary * errorDict = [dict objectForKey:@"error"];

		NSInteger code = [[errorDict objectForKey:@"error_code"] integerValue];
		NSString * msg = [errorDict objectForKey:@"error_msg"];

		NSLog(@"Failed to sign up, error_code: %i, error_msg: %@ ", code, msg);

		// TODO: Take this to wise incapsulation somewhere
		if (code==100) // One of the parameters specified was missing or invalid
		{
			UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error" message:msg
														 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[av show];
		}
		else if (code==1003) // User already invited: message already sended, you can resend message in 300 seconds
		{
			// TODO PROBLEM3: Related to PROBLEM2, sort please
			UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error" message:msg
														 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[av show];
		}
		else if (code==1004) // This phone used by another user
		{
			UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error" message:msg
														 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[av show];
		}
		else if (code==1110) // Incorrect code
		{
			UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error" message:msg
														 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[av show];
		}
		else if (code==14)  // Captcha needed
		{
			UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error" message:msg
														 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[av show];
		}

		return ; // TODO: Decide how to UI-behave on gotten failure here
	}
	
//	UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Congratulations" message:@"You can now login to VK"
//												 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//	[av show];


	// Response successful
//	if ([[dict objectForKey:@"response"] objectForKey:@"success"]==1) // TODO: To be 100% sure we are good
//	NSInteger uid = [[[dict objectForKey:@"response"] objectForKey:@"uid"] integerValue];

//	NSLog(@"Signup 2nd step successful, uid: %i", uid);

	// TODO: We don't go to Messages here, cos we don't have access_token for the new user
	// To achieve it we must go to Login page and undergo usual login procedure
	[self.navigationController popToRootViewControllerAnimated:YES]; // Back to Login
}


#pragma mark - Table callbacks

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath row] == 0) return _cellCode;
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

@end
