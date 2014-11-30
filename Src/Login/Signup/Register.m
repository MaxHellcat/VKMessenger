//
//  Register.m
//  VKM
//
//  Created by Max on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Register.h"
#import "ConfirmCode.h"
#import "VKReq.h"
#import "Constants.h"
#import "JSONKit.h"

#import "VKReq.h"


@implementation Register

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

	self.navigationItem.hidesBackButton = YES; // Hide left back button (like new window)

	// Custom back button
	UIImage * image = [[UIImage imageNamed:@"Header_Button"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:15.0f];

	UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
															  style:UIBarButtonItemStylePlain
															 target:self
															 action:@selector(touchCancel:)];
	[item setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	self.navigationItem.rightBarButtonItem = item;

	[self.navigationItem setTitle:NSLocalizedString(@"New account", nil)];

	[_textPhoneNumber becomeFirstResponder]; // Auto focus field&show keyboard (so the screen bottom half doesn't look lonely)
}

- (void)viewDidUnload
{
	_cellPhoneNumber = nil;
	_cellUserNameFirst = nil;
	_cellUserNameLast = nil;

	_textPhoneNumber = nil;
	_textUserNameFirst = nil;
	_textUserNameLast = nil;

    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Table (login/password) methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath row] == 0) return _cellPhoneNumber;
	if ([indexPath row] == 1) return _cellUserNameFirst;
	if ([indexPath row] == 2) return _cellUserNameLast;

	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 3;
}

- (void)touchCancel:(id)sender
{
	[self.navigationController popViewControllerAnimated:NO]; // Back to Login screen
}

- (IBAction)touchSignup:(id)sender
{
	// TODO: Check phone number beforehand for correctness - auth.signup
	if (_textPhoneNumber.text.length==0 || _textUserNameFirst.text.length==0 || _textUserNameLast.text.length==0)
	{
		// TODO: Implement fields shaking here
		return ;
	}

	NSLog(@"Sign up user NOW, phonenumber: %@, name: %@", _textPhoneNumber.text, _textUserNameFirst.text);

//	Для удобства тестирования регистрации был добавлен параметр test_mode, таким образом Вы можете протестировать методы используя любой привязанный телефон.

	NSString * uri = [NSString stringWithFormat:@"https://api.vk.com/method/auth.signup?phone=%@&first_name=%@&last_name=%@&client_id=%@&client_secret=%@",
					  [_textPhoneNumber.text urlEncodeUsingEncoding:NSUTF8StringEncoding], // Must encode phone number (actually only leading +)
					  [_textUserNameFirst.text urlEncodeUsingEncoding:NSUTF8StringEncoding], // Must encode user name
					  [_textUserNameLast.text urlEncodeUsingEncoding:NSUTF8StringEncoding],
					  kClientId,
					  kClientSecret];

	// TODO: IMPORTANT, Often NSURLSession fails this https query, cos of self-signed cert (accept/deny), we DO NEED to handle that!
	VKReq * req = [[VKReq alloc] initWithTarget:self action:@selector(didGetResponse:) fail:nil];
	[req get:uri];

//	[VKReq requestWithString:uri delegate:self action:@selector(didGetResponse:)];
}

// Кроме этого тут были вопросы по поводу тестирования каптчи, для этого можно использовать метод captcha.force.
- (void)didGetResponse:(VKReq *)req
{
	// TODO: Handle all error codes for auth.signup, http://vk.com/pages?oid=-1&p=auth.signup

	// Success response example: {"response":{"sid":"5ee069b77a97aa1f898f8cf7981db0e7"}}
	// Error response example:
	// {"error":{"error_code":1004,"error_msg":"This phone used by another user" 
	// {"error":{"error_code":14,"error_msg":"Captcha needed"
	//	http://api.vk.com/captcha.php?sid=674275800939
	// {"error":{"error_code":100,"error_msg":"One of the parameters specified was missing or invalid: first_name param is undefined"

	NSDictionary * dict = [req.responseData objectFromJSONData]; // Parse auth.signup output json

	// TODO: Value names - to constants
	if ([dict objectForKey:@"error"]) // Check for error response
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
		// 2) этой ошибки нет, в документации была ошибка.
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
		else if (code==1112) // Processing.. Try later
		{
			// This code means the entered phone number is still being analyzed and
			// we must repeat auth.signup with the same params in 5 seconds.
			// TODO PROBLEM1: Start timer here and resend the auth.signup req, till then show alert
			UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error" message:msg
														 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[av show];
		}
		else if (code==14) // Captcha needed
		{
			UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error" message:msg
														 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[av show];
		}

		return ; // TODO: Decide how to UI-behave on gotten failure here
	}

	// Response successful, obtain sid and open sms code entering screen
//	if ([dict objectForKey:@"response"]) // TODO: To be 100% sure we are good
	NSLog(@"Signup 1st step successful, wait for sms now");

	// TODO PROBLEM2: Resend the auth.signup req (how soon and how should we resend the req? button "Resend"/"Back" on navbar on Confirm screen?)
	// This sid is used to re-send this auth.signup req, in case SMS failed to deliver
//	[self performSelector:@selector(setHidden:) withObject:self afterDelay:10.0]; - CHECK THIS
	NSString * sid = [[dict objectForKey:@"response"] valueForKey:@"sid"];

	ConfirmCode * confirmVC = [[ConfirmCode alloc] initWithNibName:@"ConfirmCode_iPhone" bundle:nil phoneNumber:_textPhoneNumber.text];

	[self.navigationController pushViewController:confirmVC animated:YES];
}


@end
