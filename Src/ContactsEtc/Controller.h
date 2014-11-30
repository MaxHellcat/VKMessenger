//
//  Object.h
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Controller : NSObject

@property (nonatomic, strong) NSArray * viewControllers;
@property (nonatomic, strong) UINavigationController * navigationController;

- (id)initWithNavigationController:(UINavigationController *)aNavigationController
                   viewControllers:(NSArray *)viewControllers;

- (void)indexDidChangeForSegmentedControl:(UISegmentedControl *)aSegmentedControl;

@end
