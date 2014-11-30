//
//  Favorites.h
//  VKM
//
//  Created by Max on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CellFavorites;

@interface Favorites : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView * tableView;
@property (strong, nonatomic) NSArray * favorites;
@property (strong, nonatomic) IBOutlet CellFavorites *cellFavorite;


@end
