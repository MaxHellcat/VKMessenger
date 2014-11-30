//
//  ViewController.h
//  VKM
//
//  Created by Max on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


//@interface Login : UIViewController <UITableViewDataSource, UITableViewDelegate, VKReqDelegate> // <JSONKitDeserializing>
@interface Login : UIViewController <UITableViewDataSource, UITableViewDelegate> // <JSONKitDeserializing>

@property (strong, nonatomic) IBOutlet UITableViewCell *cellUser;
@property (strong, nonatomic) IBOutlet UITextField *textUser;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPassword;
@property (strong, nonatomic) IBOutlet UITextField *textPassword;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *actIndicator;



- (IBAction)touchLogin:(id)sender;
- (IBAction)touchRegister:(id)sender;
- (IBAction)touchBackground:(id)sender; // The VC view class changed to UIControl, to react to touches

@end
