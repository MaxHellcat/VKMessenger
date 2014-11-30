//
//  Register.h
//  VKM
//
//  Created by Max on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


//@interface Register : UIViewController <UITableViewDataSource, UITableViewDelegate, VKReqDelegate> // <JSONKitDeserializing>
@interface Register : UIViewController <UITableViewDataSource, UITableViewDelegate> // <JSONKitDeserializing>
{
@private
	IBOutlet UITableViewCell * _cellPhoneNumber;
	IBOutlet UITableViewCell * _cellUserNameFirst;
	IBOutlet UITableViewCell * _cellUserNameLast;

	__unsafe_unretained IBOutlet UITextField *_textPhoneNumber;
	__unsafe_unretained IBOutlet UITextField *_textUserNameFirst;
	__unsafe_unretained IBOutlet UITextField *_textUserNameLast;
}

- (void)touchCancel:(id)sender; // Set programmatically
- (IBAction)touchSignup:(id)sender;

@end
