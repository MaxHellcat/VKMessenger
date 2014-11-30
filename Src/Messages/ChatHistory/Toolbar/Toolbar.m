//
//  ToolbarAttachment.m
//  VKM
//
//  Created by Max on 06.04.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Toolbar.h"
#import "ChatHistory.h" // To find table view

#import "Tray.h" // Attachments scrolling tray


@implementation Toolbar

@synthesize buttonUp = _buttonUp;
@synthesize buttonRecommend = _buttonRecommend;
@synthesize buttonAddToChat = _buttonAddToChat;
@synthesize delegate;
@synthesize tray = _tray;

@synthesize textField=_textField;
//@synthesize imageTextField = _imageTextField;
@synthesize slided=_slided;

//static float kKeyboardOriginY = 264.0f-44.0f-20.0f;
static float kAnimationDuration = 0.25f; // Like keyboard
//static int kAnimationCurve = UIViewAnimationCurveEaseInOut; // Like keyboard


- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self)
	{
//		[self setImage:[UIImage imageNamed:@"Background_Dark.png"]]; // TODO: Don't have non-retina size for this image!
//		_up = NO;
		
		_currentTextFieldHeight = 35.0f;

		_slided = NO;

//		UIImage * image = [[UIImage imageNamed:@"InputField.png"] stretchableImageWithLeftCapWidth:15.0f topCapHeight:15.0f];
//		[_imageTextField setImage:image];
		/*
		 CGRect frame = _imageTextField.frame;
		 frame.size.width += 30.0f;
		 _imageTextField.frame = frame;
		 
		 _imageTextField.frame = _textField.frame;
		 */		
	}

	return self;
}

-(void)awakeFromNib
{
	UIImage * image = [[UIImage imageNamed:@"InputField"] stretchableImageWithLeftCapWidth:15.0f topCapHeight:15.0f];
	UIImageView * imageTextField = [[UIImageView alloc] initWithImage:image];

	imageTextField.bounds = CGRectMake(0.0f,
									   0.0f,
									   _textField.frame.size.width+13.0f, // A bit wider then text view
									   _buttonUp.bounds.size.height); // The same height as buttons

	imageTextField.center = CGPointMake(_textField.center.x, _buttonUp.center.y);;
	imageTextField.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	[self insertSubview:imageTextField belowSubview:_textField];

	// Image for buttons
	UIImage * imageNormal = [[UIImage imageNamed:@"DarkButton"] stretchableImageWithLeftCapWidth:15.0f topCapHeight:15.0f];
	UIImage * imageTouched = [[UIImage imageNamed:@"DarkButton_Pressed"] stretchableImageWithLeftCapWidth:15.0f topCapHeight:15.0f];

	[_buttonRecommend setBackgroundImage:imageNormal forState:UIControlStateNormal];
	[_buttonRecommend setBackgroundImage:imageTouched forState:UIControlStateHighlighted];

	[_buttonAddToChat setBackgroundImage:imageNormal forState:UIControlStateNormal];
	[_buttonAddToChat setBackgroundImage:imageTouched forState:UIControlStateHighlighted];
	
	// Attachment's tray
	// TODO: Change to correct size in release
	CGRect frame = CGRectMake(0.0f+10.0f, 160.0, 300.0f, [Tray trayHeight]);
	_tray = [[Tray alloc] initWithFrame:frame];
	[_tray setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
}

- (void)textViewDidChange:(UITextView *)textView
{
	if (_textField.contentSize.height!=_currentTextFieldHeight)
	{
		float offset = _textField.contentSize.height-_currentTextFieldHeight;

		CGRect frame = self.frame;
		frame.origin.y -= offset;
		frame.size.height += offset;
		self.frame = frame;

		[self.delegate didResize:self];

		_currentTextFieldHeight = _textField.contentSize.height;
	}
}

- (void)slideUp
{
	if (_slided)
		return;

	[UIView animateWithDuration:kAnimationDuration animations:^
	{
		CGRect frame = self.frame;
		frame.origin.y -= 216.0f; // Ugly
		self.frame = frame;
	}];

	_slided = YES;
}

- (void)slideDown
{
	if (!_slided)
		return;

	[UIView animateWithDuration:kAnimationDuration animations:^
	{
		 CGRect frame = self.frame;
		 frame.origin.y += 216.0f;
		 self.frame = frame;
	}];

	_slided = NO;
}

- (IBAction)touchUp:(id)sender
{
	[self slideUp];
	[self.delegate didResize:self]; // Tell ChatHistory to adjust table view
	[_textField resignFirstResponder]; // Dismiss keyboard, if any


	// Show attachments tray
//	[_tray addItem:[UIImage imageNamed:@"photo.png"]]; // Should pass full-sized image
//	[self addSubview:_tray];
}

- (IBAction)touchGalery:(id)sender
{
	UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.delegate = self;
//	imagePicker.allowsImageEditing = NO;

	[self.delegate presentModalViewController:imagePicker animated:YES];


}

#pragma mark - 
#pragma mark UIImagePickerControllerDelegate related

- (void)imagePickerController:(UIImagePickerController *)picker
		didFinishPickingImage:(UIImage *)image
				  editingInfo:(NSDictionary *)editingInfo
{
//	NSLog(@"didFinishPickingImage, image w: %f, h: %f", image.size.width, image.size.height);

	if (!_pickedImages)
		_pickedImages = [[NSMutableArray alloc] init];

	[picker dismissViewControllerAnimated:YES
							   completion:^
	{
		// TODO: Animate
		[UIView animateWithDuration:0.5f delay:0.1f options:UIViewAnimationOptionAllowUserInteraction animations:^
		 {
			 _buttonRecommend.hidden = YES;
			 _buttonAddToChat.hidden = YES;
		 }
						 completion:nil];
	
		[_tray addItem:image];
		[self addSubview:_tray];
	}];
}

/*
 - (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
}
 */
//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;


- (void)dealloc
{
	self.textField = nil;
	self.buttonUp = nil;
	self.delegate = nil;
}

@end
