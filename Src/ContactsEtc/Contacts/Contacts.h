//
//  Contacts.h
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CellContact;

@interface Contacts : UITableViewController

@property (strong, nonatomic) NSMutableArray * contacts;
@property (strong, nonatomic) NSMutableArray * phoneNumbers;

@property (strong, nonatomic) IBOutlet CellContact * cellContact;


@end




@interface Contact : NSObject

@property (strong, nonatomic) NSString * nameFirst;
@property (strong, nonatomic) NSString * nameLast;
@property (strong, nonatomic) NSString * phone;
@property (strong, nonatomic) NSString * iphone;
@property (nonatomic) BOOL hasAccount;

@end
