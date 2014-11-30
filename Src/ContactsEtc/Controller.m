//
//  Object.m
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"

@implementation Controller

@synthesize viewControllers;
@synthesize navigationController;

- (id)initWithNavigationController:(UINavigationController *)aNavigationController
                   viewControllers:(NSArray *)theViewControllers
{
    if (self = [super init])
	{
        self.navigationController = aNavigationController;
        self.viewControllers = theViewControllers;
    }
    return self;
}

- (void)indexDidChangeForSegmentedControl:(UISegmentedControl *)aSegmentedControl
{
    NSUInteger index = aSegmentedControl.selectedSegmentIndex;
    UIViewController * incomingViewController = [self.viewControllers objectAtIndex:index];

    NSArray * theViewControllers = [NSArray arrayWithObject:incomingViewController];
    [self.navigationController setViewControllers:theViewControllers animated:NO];

    incomingViewController.navigationItem.titleView = aSegmentedControl;
}

@end
