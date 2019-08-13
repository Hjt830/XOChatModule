//
//  XOChatViewController.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOChatViewController.h"

@interface XOChatViewController () <XOChatBoxViewControllerDelegate, XOChatMessageControllerDelegate>

@property (nonatomic, copy) NSString    * receiver;

@end

@implementation XOChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 聊天对象的userId或者groupId
    self.receiver = [self.conversation getReceiver];
    
    [self initialization];
    
    [self setupSubViews];
}

- (void)initialization
{
    if (TIM_GROUP == self.chatType) {
        self.title = self.conversation.getGroupName;
    } else if (TIM_C2C == self.chatType) {
        TIMFriend *friend = [[TIMManager sharedInstance].friendshipManager queryFriend:self.receiver];
        if (XOIsEmptyString(friend.remark)) {
            if (XOIsEmptyString(friend.profile.nickname)) {
                self.title = self.receiver;
            } else {
                self.title = friend.profile.nickname;
            }
        } else {
            self.title = friend.remark;
        }
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (_chatBoxVC.view.top == 0) {
        [_chatBoxVC.view setFrame:CGRectMake(0, self.view.height - HEIGHT_TABBAR, KWIDTH, KHEIGHT)];
    } else {
        [_chatBoxVC.view setFrame:CGRectMake(0, _chatBoxVC.view.top, KWIDTH, KHEIGHT)];
    }
    _chatMsgVC.view.y = 0;
    _chatMsgVC.view.height = _chatBoxVC.view.y;
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    
    _chatBoxVC.view.top = self.view.height - HEIGHT_TABBAR - self.safeInset.bottom;
}

- (void)setupSubViews
{
    self.navigationController.navigationBar.translucent = NO;
    [self.view setBackgroundColor:BG_TableColor];
    
    _chatMsgVC = [[XOChatMessageController alloc] init];
    _chatMsgVC.delegate = self;
    [self addChildViewController:_chatMsgVC];
    [self.view addSubview:_chatMsgVC.view];
    
    _chatBoxVC = [[XOChatBoxViewController alloc] init];
    _chatBoxVC.delegate = self;
    [self addChildViewController:_chatBoxVC];
    [self.view addSubview:_chatBoxVC.view];
}


@end
