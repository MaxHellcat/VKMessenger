//
//  ConfirmCode.h
//  VKM
//
//  Created by Max on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ConfirmCode : UIViewController <UITableViewDataSource, UITableViewDelegate> // <JSONKitDeserializing>
{
@private
	IBOutlet UITableViewCell * _cellCode;
	__unsafe_unretained IBOutlet UITextField * _textCode;
	IBOutlet UITableViewCell *_cellPassword;
	__unsafe_unretained IBOutlet UITextField *_textPassword;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil phoneNumber:(NSString *)phoneNumber;
- (IBAction)touchConfirm:(id)sender;

@property (strong, nonatomic) NSString * phoneNumber;

@end
