//
//  ContactDetailsViewController.h
//  VKM
//
//  Created by Max on 16.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageUI/MessageUI.h" // Send invitation SMS

@class Contact;

@interface ContactDetails : UIViewController <MFMessageComposeViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableViewCell * cellPhone;
@property (strong, nonatomic) IBOutlet UITableViewCell * cellIPhone;
@property (strong, nonatomic) IBOutlet UILabel * labelPhone;
@property (strong, nonatomic) IBOutlet UILabel * labelIPhone;

@property (strong, nonatomic) IBOutlet UILabel * labelContactName;
@property (strong, nonatomic) IBOutlet UIImageView * imageAvatar;

@property (strong, nonatomic) IBOutlet UIButton * buttonAddOrInvite;
@property (strong, nonatomic) IBOutlet UIButton * buttonAddToFavorites;


- (IBAction)touchAddOrInvite:(id)sender;
- (IBAction)touchAddToFavorite:(id)sender;

@property (strong, nonatomic) Contact * contact;

- (id)initWithContact:(Contact *)contact;

@end
