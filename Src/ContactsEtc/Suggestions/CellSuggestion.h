//
//  CellSuggestion.h
//  VKM
//
//  Created by Max on 17.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CellSuggestion : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageAvatar;
@property (strong, nonatomic) IBOutlet UILabel *labelName;
@property (strong, nonatomic) IBOutlet UIButton *buttonAdd;


@end
