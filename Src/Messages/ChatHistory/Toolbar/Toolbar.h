//
//  ToolbarAttachment.h
//  VKM
//
//  Created by Max on 06.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ChatHistory, Tray;

@protocol ToolbarDelegate;

@interface Toolbar : UIView <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
	float _currentTextFieldHeight;

	NSMutableArray * _pickedImages;
}

@property (strong, nonatomic) Tray * tray;  // Attachments tray

@property (strong, nonatomic) IBOutlet UITextView * textField;
@property (strong, nonatomic) IBOutlet UIButton * buttonUp;

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *buttonRecommend;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *buttonAddToChat;


@property(nonatomic, strong) ChatHistory<ToolbarDelegate> * delegate;

@property (readonly, nonatomic) BOOL slided;

- (void)slideUp;
- (void)slideDown;
- (IBAction)touchUp:(id)sender;
- (IBAction)touchGalery:(id)sender;

@end

@protocol ToolbarDelegate
@optional
- (void)didResize:(Toolbar *)toolbar;
@end
