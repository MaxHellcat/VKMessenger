//
//  Settings.m
//  VKM
//
//  Created by Max on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Settings.h"
#import "VKReq.h"
#import "JSONKit.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "Cache.h"
#import "CUser.h"
#import "UIImageView+WebCache.h"
#import "QuartzCore/QuartzCore.h"


@implementation Settings
@synthesize imageAvatar;
@synthesize labelName;
@synthesize touchChangePhoto;
@synthesize touchLogout;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
		// Custom initialization
		self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil)
														image:[UIImage imageNamed:@"DockSettings.png"] tag:0];
		self.title = NSLocalizedString(@"Settings", nil);
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
	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];

	CUser * user = [[Cache instance] userById:delegate.udUserId.intValue];

	NSURL * url = [NSURL URLWithString:user.photo];
	[self.imageAvatar setImageWithURL:url placeholderImage:[UIImage imageNamed:@"Avatar_placeholder"]];
	self.imageAvatar.layer.masksToBounds = YES;
	self.imageAvatar.layer.cornerRadius = 8.0f;

	self.labelName.text = [NSString stringWithFormat:@"%@ %@", user.nameFirst, user.nameLast];
}

- (void)viewDidUnload
{
    [self setTouchLogout:nil];
    [self setTouchChangePhoto:nil];
	[self setImageAvatar:nil];
	[self setLabelName:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



/*
- (IBAction)touchUnreg:(id)sender
{
	AppDelegate * delegate = [[UIApplication sharedApplication] delegate];

	NSString * deviceTokenStr = [[[[delegate.udPushToken description]
								   stringByReplacingOccurrencesOfString: @"<" withString: @""]
								  stringByReplacingOccurrencesOfString: @">" withString: @""]
								 stringByReplacingOccurrencesOfString: @" " withString: @""];

	[VKReq getMethod:@"account.unregisterDevice" withParams:[NSString stringWithFormat:@"token=%@", deviceTokenStr]
			  target:self action:@selector(didGetResponse:) fail:nil];

	
	[[UIApplication sharedApplication] unregisterForRemoteNotifications];

}
 AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
 
 NSString * deviceTokenStr = [[[[delegate.udPushToken description]
 stringByReplacingOccurrencesOfString: @"<" withString: @""]
 stringByReplacingOccurrencesOfString: @">" withString: @""]
 stringByReplacingOccurrencesOfString: @" " withString: @""];
 
 //	NSString* newToken = [deviceToken description];
 //	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
 //	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
 
 [VKReq getMethod:@"account.registerDevice" withParams:[NSString stringWithFormat:@"token=%@", deviceTokenStr]
 target:self action:@selector(didGetResponse:)];
 */

@end
