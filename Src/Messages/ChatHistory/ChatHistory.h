//
//  Dialogue.h
//  VKM
//
//  Created by Max on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMessage.h"
#import "PullToRefresh.h"
#import "Toolbar.h"


@interface ChatHistory : UIViewController
<
UITableViewDataSource,
UITableViewDelegate,
PullToRefreshDelegate,
UIScrollViewDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
NSFetchedResultsControllerDelegate,
UITextFieldDelegate,
ToolbarDelegate
>
{
	PullToRefreshView * _refreshView;
}

- (id)initWithMessage:(CMessage *)message; // Called by LatestDialogues, when certain latest dialogue touched
- (id)initWithUser:(CUser *)user; // Called by Friends, to show single chat history

@property (strong, nonatomic) NSFetchedResultsController * messages;
@property (unsafe_unretained, nonatomic) IBOutlet UITableView * tableView;
@property (strong, nonatomic) IBOutlet Toolbar * toolbar;

@property (strong, nonatomic) CMessage * message;
@property (strong, nonatomic) CUser * user;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *waitIndicator;

@property (nonatomic) BOOL isChat;
@property (strong, nonatomic) UIImage * headerAvatar;

- (IBAction)touchCamera:(id)sender;
- (IBAction)touchGeo:(id)sender;

@end


@class VKReq;

// Category implementing ChatHistory network interaction
@interface ChatHistory (Network)
- (void)readChatHistory;
- (void)didGetChatHistory:(VKReq *)req;
- (void)didGetChatHistoryFail:(VKReq *)req;
- (void)didGetMessageSendResponse:(VKReq *)req;
- (IBAction)touchSend:(id)sender;
@end
