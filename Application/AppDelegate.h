//
//  AppDelegate.h
//  VKM
//
//  Created by Max on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Event, Controller;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow * window;

@property (strong, nonatomic) NSString * udAccessToken;
@property (strong, nonatomic) NSString * udSecret;
@property (strong, nonatomic) NSNumber * udUserId;
@property (strong, nonatomic) NSData * udPushToken;
@property (strong, nonatomic) NSNumber * udUnreadCount;

@property (strong, nonatomic) Controller * controller;
@property (strong, nonatomic) UISegmentedControl * segmentControl;
@property (strong, nonatomic) UITabBarController * tbController;
@property (strong, nonatomic) UINavigationController * navControllerMessages;


- (UITabBarController *)loadMessagesEtAl;

// User Defaults
- (void)store; 

- (void)setUnreadCount:(NSInteger)value;

@end
