//
//  AppDelegate.m
//  VKM
//
//  Created by Max on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "Cache.h"
#import "Event.h"

#import "Login.h"
#import "Favorites.h"
#import "LatestDialogues.h"

#import "Contacts.h"
#import "Friends.h"
#import "Suggestions.h"

#import "Settings.h"

#import "Controller.h"


@interface AppDelegate ()
- (void)restore;
@property (strong, nonatomic) Event * eventController;
@end


@implementation AppDelegate

@synthesize window = _window;
@synthesize udAccessToken = _udAccessToken;
@synthesize udSecret = _udSecret;
@synthesize udUserId = _udUserId;
@synthesize udPushToken = _udPushToken;
@synthesize udUnreadCount = _udUnreadCount;
@synthesize tbController = _tbController;
@synthesize navControllerMessages = _navControllerMessages;


@synthesize eventController=_eventController;

@synthesize controller;
@synthesize segmentControl;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[application setStatusBarStyle:UIStatusBarStyleBlackOpaque];

    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// Localization
//	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
//	NSArray * languages = [ud objectForKey:@"AppleLanguages"];
//	NSString * currentLanguage = [languages objectAtIndex:0];
//	// NSLog(@"Current Locale: %@", [[NSLocale currentLocale] localeIdentifier]);
//	// NSLog(@"Current language: %@", currentLanguage);


	// If the app was opened from Push notification
	/*
	 if (launchOptions != nil)
	 {
	 NSDictionary* dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	 if (dictionary != nil)
	 {
	 // NSLog(@"Launched from push notification: %@", dictionary);
	 //			[self addMessageFromRemoteNotification:dictionary updateUI:NO];
	 }
	 }
	 */

	// Restore app data
	[self restore];

	if (_udAccessToken) // The user/app already authorized, head to Messages
	{
		// NSLog(@"User already authorized, loading Messages");

		[self loadMessagesEtAl];
	}
	else // User/app not authorized (access_token missing), step to Login
	{
		// NSLog(@"User NOT authorized, loading Login page");

		// Open Login
		//	TODO: Sort out what is UINib
		Login * loginVC = [[Login alloc] initWithNibName:@"Login_iPhone" bundle:nil];
		UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:loginVC];

		// TODO: Find a way to set bg image for navi bar in iOS<5.0f
		if ([navController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) // Available since iOS 5.0
		{
			[navController.navigationBar setBackgroundImage:[UIImage imageNamed:@"Header_black.png"] forBarMetrics:UIBarMetricsDefault];
		}
		else
		{
//			UIImageView * iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Header_black.png"]]; // TODO: Test this on iOS 4.0!!!
//			[_naviController.navigationBar insertSubview:iv atIndex:0];
		}

		_window.rootViewController = navController;
	}

	self.window.backgroundColor = [UIColor whiteColor];
	[_window makeKeyAndVisible];

// TODO: Do we ask for pushes after Login, or just when the app start (no matter logged or not - if we not logged, no access to VK Api, what will pushes send?)?
// Register for push notifications on app level
//	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
//	 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
//	 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
	
//	[[UIApplication sharedApplication] unregisterForRemoteNotifications];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	[self store]; // Store user data
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

	[self store]; // Store user data
	[[Cache instance] saveContext]; // Flush cache
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	[self restore]; // Restore user data
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Saves changes in the application's managed object context before the application terminates.
//	[self saveContext];
}

- (UITabBarController *)loadMessagesEtAl
{
	Favorites * favorites = [[Favorites alloc] initWithNibName:@"Favorites_iPhone" bundle:nil];
	LatestDialogues * messages = [[LatestDialogues alloc] initWithNibName:@"LatestDialogues_iPhone" bundle:nil];
	Settings * settings = [[Settings alloc] initWithNibName:@"Settings_iPhone" bundle:nil];

	UINavigationController * navControllerFavorites = [[UINavigationController alloc] initWithRootViewController:favorites];
	self.navControllerMessages = [[UINavigationController alloc] initWithRootViewController:messages];
	UINavigationController * navControllerSettings = [[UINavigationController alloc] initWithRootViewController:settings];	

	// Set of Contacts/Friends/Requests view controllers tied to single navigation bar with segmented control
	UIViewController * contacts = [[Contacts alloc] initWithNibName:@"Contacts_iPhone" bundle:nil];
    UIViewController * friends = [[Friends alloc] initWithNibName:@"Friends_iPhone" bundle:nil];
	UIViewController * requests = [[Suggestions alloc] initWithNibName:@"Suggestions_iPhone" bundle:nil];
	NSArray * viewControllers = [NSArray arrayWithObjects:contacts, friends, requests, nil];

	UINavigationController * navControllerContacts = [[UINavigationController alloc] init];
	self.controller = [[Controller alloc] initWithNavigationController:navControllerContacts viewControllers:viewControllers];

	// Configure segmented control for contacts navigation bar
	self.segmentControl = [[UISegmentedControl alloc] initWithItems:
						   [NSArray arrayWithObjects:
							NSLocalizedString(@"Contacts", nil),
							NSLocalizedString(@"Friends", nil),
							NSLocalizedString(@"Requests", nil), nil]];
	self.segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
//	self.segmentControl.tintColor = [UIColor colorWithRed:0.1961f green:0.2745f blue:0.3804f alpha:1.0f];
//	self.segmentControl.tintColor = [UIColor colorWithRed:0.2784f green:0.3804f blue:0.5137f alpha:1.0f];

	self.segmentControl.tintColor = [UIColor colorWithRed:0.3569f green:0.4667f blue:0.6196f alpha:1.0f];

	
	[self.segmentControl addTarget:controller action:@selector(indexDidChangeForSegmentedControl:) forControlEvents:UIControlEventValueChanged];

	UIImage * image = [[UIImage imageNamed:@"Header_Button"] stretchableImageWithLeftCapWidth:5.0f topCapHeight:15.0f];
	[self.segmentControl setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

	self.segmentControl.selectedSegmentIndex = 0; // Initially Contacts are shown
    [self.controller indexDidChangeForSegmentedControl:self.segmentControl];


	// TODO: Find a way to set bg image for navi bar in iOS<5.0f!
	if ([navControllerFavorites.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) // Available since iOS 5.0
	{
		[navControllerFavorites.navigationBar setBackgroundImage:[UIImage imageNamed:@"Header_black"] forBarMetrics:UIBarMetricsDefault];
		[self.navControllerMessages.navigationBar setBackgroundImage:[UIImage imageNamed:@"Header_black"] forBarMetrics:UIBarMetricsDefault];
		[navControllerContacts.navigationBar setBackgroundImage:[UIImage imageNamed:@"Header_black"] forBarMetrics:UIBarMetricsDefault];
		[navControllerSettings.navigationBar setBackgroundImage:[UIImage imageNamed:@"Header_black"] forBarMetrics:UIBarMetricsDefault];
	}
	else
	{ // TODO: Test this on iOS 4.0!!!
		//		UIImageView * iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Header_black.png"]];
		//		[_naviController.navigationBar insertSubview:iv atIndex:0];
	}

	// Unlike other view controllers, a tab bar interface should never be installed as a child of another view controller.
	self.tbController = [[UITabBarController alloc] init];

	self.tbController.viewControllers = [NSArray arrayWithObjects:
										navControllerFavorites,
										self.navControllerMessages,
										controller.navigationController,
										navControllerSettings, nil];

	[self.tbController setSelectedViewController:self.navControllerMessages]; // Open Messages tab

	self.window.rootViewController = self.tbController;

	_eventController = [[Event alloc] init]; // Start LongPoll events listener, all interested VCs are in the loop

	return self.tbController;
}

#pragma mark Remote push 

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	// NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken, deviceToken: %@", deviceToken);
	self.udPushToken = deviceToken;
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	// NSLog(@"didFailToRegisterForRemoteNotificationsWithError, error: %@", error);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	// NSLog(@"PUSH RECEIVED while app running: %@", userInfo);
}


- (void)setUnreadCount:(NSInteger)value
{
	// NSLog(@"Changing unread count to %i, now %i", value, self.udUnreadCount.intValue);
	
	if (value < 0)
		return;

	self.udUnreadCount = [NSNumber numberWithInt:value];

	if (self.udUnreadCount.intValue > 0)
	{
		[UIApplication sharedApplication].applicationIconBadgeNumber = self.udUnreadCount.intValue;
		
//		[UIView animateWithDuration:0.5f animations:^
//		 {
			 [self.navControllerMessages.tabBarItem setBadgeValue:self.udUnreadCount.stringValue];
//		 }];
	}
}

#pragma mark Store/restore user data

- (void)store
{
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

	// TODO: All constants to external depot
	[ud setObject:_udAccessToken forKey:@"access_token"];
	[ud setObject:_udSecret forKey:@"secret"];
	[ud setObject:_udUserId forKey:@"user_id"];
	[ud setObject:_udPushToken forKey:@"push_token"];
	[ud setObject:_udUnreadCount forKey:@"unread_count"];
}

- (void)restore
{
	NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];

	_udAccessToken = [ud objectForKey:@"access_token"];
	_udSecret = [ud objectForKey:@"secret"];
	_udUserId = [ud objectForKey:@"user_id"];
	_udPushToken = [ud objectForKey:@"push_token"];
	_udUnreadCount = [ud objectForKey:@"unread_count"];
}

- (void)dealloc
{
	self.window = nil;
	self.udAccessToken = nil;
	self.udSecret = nil;
	self.udUserId = nil;
	self.udPushToken = nil;
}

@end
