//
//  XOConversationListController.m
//  XOChatModule
//
//  Created by 乐派 on 2019/7/26.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "XOConversationListController.h"
//#import "XOContactListViewController.h"
#import "XOChatViewController.h"

#import "XOConversationListCell.h"

#import <XOBaseLib/XOBaseLib.h>
#import "XOChatModule.h"
#import "XOChatClient.h"

#define Margin 10.0f
#define TableHeaderStateHeight   44.0f
#define TableHeaderViewMinHeight 160.0f
#define TableHeaderViewMaxHeight 200.0f

static NSString * const ConversationListCellID = @"ConversationListCellID";

@interface XOConversationListController () <UITableViewDataSource, UITableViewDelegate, XOChatClientProtocol, XOMessageDelegate, XOConversationDelegate>
{
    dispatch_queue_t        _chatDelegate_queue;
    UIEdgeInsets            _safeInset;
}

@property (nonatomic, weak) UITabBarItem            *chatTabbarItem;
@property (nonatomic, strong) UIView                *headerView;        // 头部视图
@property (nonatomic, strong) UIView                *networkStateView;  // 断网视图
@property (nonatomic, strong) UILabel               *networkStateLabel; // 断网文字
@property (nonatomic, strong) UIView                *systemView;        // 系统消息视图
@property (nonatomic, strong) UIView                *groupChatView;     // 发起群聊视图
@property (nonatomic, strong) UILabel               *sysNameLabel;      // 系统消息
@property (nonatomic, strong) UILabel               *groupNameLabel;    // 群聊消息
@property (nonatomic, assign) BOOL                  isDisConnect;       // 连接是否断开

@property (nonatomic, strong) UITableView           *tableView;         // 会话列表

@property (nonatomic, strong) NSArray    <TIMConversation *>* dataSource;   // 会话数据源

@end

@implementation XOConversationListController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isDisConnect = NO; // 默认是连接状态
        _chatDelegate_queue = dispatch_queue_create("XOConversationList", DISPATCH_QUEUE_CONCURRENT);
        [[XOChatClient shareClient] addDelegate:self delegateQueue:_chatDelegate_queue];
        [[XOChatClient shareClient].conversationManager addDelegate:self delegateQueue:_chatDelegate_queue];
        [[XOChatClient shareClient].messageManager addDelegate:self delegateQueue:_chatDelegate_queue];
    }
    return self;
}

- (void)dealloc
{
    [[XOChatClient shareClient] removeDelegate:self];
    [[XOChatClient shareClient].conversationManager removeDelegate:self];
    [[XOChatClient shareClient].messageManager removeDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadUnreadCount];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Inbox";
    self.view.backgroundColor = BG_TableColor;
    
    [self setupSubViews];
    
    [self loadUnreadCount];
}

- (void)setupSubViews
{
    [self.headerView addSubview:self.networkStateView];
    [self.headerView addSubview:self.systemView];
    [self.headerView addSubview:self.groupChatView];
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.tableView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 64, 44);
    [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    [button setTitle:XOChatLocalizedString(@"contact.addressbook") forState:UIControlStateNormal];
    [button addTarget:self action:@selector(contactList) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = bbi;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self reloadHeaderView];
    self.networkStateView.frame = CGRectMake(0, 0, self.view.width, TableHeaderStateHeight);
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    _safeInset = self.view.safeAreaInsets;
}

/**
 *  切换显示 断网状态栏和web登录状态栏
 */
- (void)reloadHeaderView
{
    // 断网状态
    if (self.isDisConnect) {
        self.headerView.height = TableHeaderViewMaxHeight;
        self.networkStateView.hidden = NO;
        self.systemView.frame = CGRectMake(_safeInset.left, self.networkStateView.bottom + Margin, self.view.width - (_safeInset.left + _safeInset.right), 70);
        self.groupChatView.frame = CGRectMake(_safeInset.left, self.systemView.bottom + Margin, self.view.width - (_safeInset.left + _safeInset.right), 70);
    }
    // 连接状态
    else {
        self.headerView.height = TableHeaderViewMinHeight;
        self.networkStateView.hidden = YES;
        self.systemView.frame = CGRectMake(_safeInset.left, 10, self.view.width - (_safeInset.left + _safeInset.right), 70);
        self.groupChatView.frame = CGRectMake(_safeInset.left, self.systemView.bottom + Margin, self.view.width - (_safeInset.left + _safeInset.right), 70);
    }
    self.tableView.frame = CGRectMake(_safeInset.left + 10, self.headerView.height + Margin, self.view.width - 20 - (_safeInset.left + _safeInset.right), self.view.height - (self.headerView.height + Margin));
}

#pragma mark ========================= touch event =========================

- (void)contactList
{
//    XOContactListViewController *contactListVC = [[XOContactListViewController alloc] init];
//    [self.navigationController pushViewController:contactListVC animated:YES];
}

#pragma mark ====================== load data =======================

- (void)loadConversation
{
    @synchronized (self) {
        self.dataSource = [[TIMManager sharedInstance] getConversationList];
    };
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)loadUnreadCount
{
    if (!self.chatTabbarItem) {
        if (self.tabBarController) {
            [[self.tabBarController viewControllers] enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isEqual:self]) {
                    self.chatTabbarItem = self.tabBarController.tabBar.items[idx];
                    *stop = YES;
                }
            }];
        }
    }
    if (!self.chatTabbarItem) {
        if (self.navigationController.tabBarController) {
            [[self.navigationController.tabBarController viewControllers] enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isEqual:self.navigationController]) {
                    self.chatTabbarItem = self.tabBarController.tabBar.items[idx];
                    *stop = YES;
                }
            }];
        }
    }
    
    __block NSUInteger unredCount = 0;
    [[[TIMManager sharedInstance] getConversationList] enumerateObjectsUsingBlock:^(TIMConversation * _Nonnull conversation, NSUInteger idx, BOOL * _Nonnull stop) {
        unredCount += [conversation getUnReadMessageNum];
    }];
    
    if (0 == unredCount) {
        [self.chatTabbarItem setBadgeValue:nil];
    } else {
        [self.chatTabbarItem setBadgeValue:[NSString stringWithFormat:@"%u", (unsigned int)unredCount]];
    }
}

#pragma mark ====================== lazy load =======================

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.rowHeight = 70.0f;
        _tableView.separatorColor = RGBA(230, 230, 230, 1.0);
        _tableView.separatorInset = UIEdgeInsetsMake(0, _tableView.rowHeight + 10, 0, 0);
        _tableView.sectionHeaderHeight = 0.0f;
        _tableView.sectionFooterHeight = 0.0f;
        _tableView.multipleTouchEnabled = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        
        [_tableView registerClass:[XOConversationListCell class] forCellReuseIdentifier:ConversationListCellID];
    }
    return _tableView;
}

- (UIView *)headerView
{
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = BG_TableSeparatorColor;
    }
    return _headerView;
}

- (UIView *)networkStateView
{
    if (_networkStateView == nil) {
        _networkStateView = [[UIView alloc]initWithFrame:CGRectMake(0, TableHeaderViewMinHeight, SCREEN_WIDTH, TableHeaderStateHeight)];
        _networkStateView.backgroundColor = RGBA(255, 125, 141, 0.7);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(25, (_networkStateView.height - 20)/2, 20, 20)];
        imageView.image = [UIImage xo_imageNamedFromChatBundle:@"messageSendFail"];
        [_networkStateView addSubview:imageView];
        [_networkStateView addSubview:self.networkStateLabel];
    }
    return _networkStateView;
}

- (UILabel *)networkStateLabel
{
    if (_networkStateLabel == nil) {
        _networkStateLabel = [[UILabel alloc]initWithFrame:CGRectMake(70, 0, SCREEN_WIDTH - 80, TableHeaderStateHeight)];
        _networkStateLabel.textAlignment = NSTextAlignmentLeft;
        _networkStateLabel.textColor = [UIColor darkTextColor];
        _networkStateLabel.font = [UIFont systemFontOfSize:14];
        _networkStateLabel.text = XOChatLocalizedString(@"network.disconnected");
    }
    return _networkStateLabel;
}

- (UIView *)systemView
{
    if (!_systemView) {
        _systemView = [[UIView alloc] init];
        _systemView.backgroundColor = [UIColor whiteColor];
        CALayer *imageLayer = [CALayer layer];
        imageLayer.contents = (__bridge id)[UIImage xo_imageNamedFromChatBundle:@"message_systemmessage"].CGImage;
        imageLayer.frame = CGRectMake(Margin, 7, 50.0, 50.0);
        imageLayer.masksToBounds = YES;
        imageLayer.cornerRadius = 25.0f;
        [_systemView.layer addSublayer:imageLayer];
        self.sysNameLabel = [[UILabel alloc] init];
        self.sysNameLabel.textColor = [UIColor blackColor];
        self.sysNameLabel.frame = CGRectMake(CGRectGetMaxX(imageLayer.frame) + Margin, 25, 240, 20);
        self.sysNameLabel.text = XOChatLocalizedString(@"conversation.systemMessage");
        self.sysNameLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        [_systemView addSubview:self.sysNameLabel];
    }
    return _systemView;
}

- (UIView *)groupChatView
{
    if (!_groupChatView) {
        _groupChatView = [[UIView alloc] init];
        _groupChatView.backgroundColor = [UIColor whiteColor];
        
        CALayer *imageLayer = [CALayer layer];
        imageLayer.contents = (__bridge id)[UIImage xo_imageNamedFromChatBundle:@"message_groupmessage"].CGImage;
        imageLayer.frame = CGRectMake(Margin, 7, 50.0, 50.0);
        imageLayer.masksToBounds = YES;
        imageLayer.cornerRadius = 25.0f;
        [_groupChatView.layer addSublayer:imageLayer];
        self.groupNameLabel = [[UILabel alloc] init];
        self.groupNameLabel.textColor = [UIColor blackColor];
        self.groupNameLabel.frame = CGRectMake(CGRectGetMaxX(imageLayer.frame) + Margin, 25, 240, 20);
        self.groupNameLabel.text = XOChatLocalizedString(@"conversation.groupChat");
        self.groupNameLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        [_groupChatView addSubview:self.groupNameLabel];
    }
    return _groupChatView;
}

#pragma mark ====================== XOChatClientProtocol =======================

// 收到新消息
- (void)xoOnNewMessage:(NSArray <TIMMessage *>*)msgs
{
    
}

// 踢下线通知
- (void)xoOnForceOffline
{
    [SVProgressHUD showErrorWithStatus:@"login conflict"];
    [SVProgressHUD dismissWithDelay:1.5f];
}
// 断线重连失败
- (void)xoOnReConnFailed:(int)code err:(NSString*)err
{
    [SVProgressHUD showErrorWithStatus:@"reconnect fail"];
    [SVProgressHUD dismissWithDelay:1.5f];
}
// 用户登录的userSig过期（用户需要重新获取userSig后登录）
- (void)xoOnUserSigExpired
{
    [SVProgressHUD showErrorWithStatus:@"login expired"];
    [SVProgressHUD dismissWithDelay:1.5f];
}
// 网络连接成功
- (void)xoOnConnSucc
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.isDisConnect = NO;
        self.title = @"Inbox";
        [self reloadHeaderView];
        [self loadConversation];
    }];
}
// 网络连接失败
- (void)xoOnConnFailed:(int)code err:(NSString*)err
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.isDisConnect = YES;
        self.title = @"Inbox (unConnect)";
        [self reloadHeaderView];
    }];
}
// 网络连接断开（断线只是通知用户，不需要重新登录，重连以后会自动上线）
- (void)xoOnDisconnect:(int)code err:(NSString*)err
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.isDisConnect = YES;
        self.title = @"Inbox (unConnect)";
        [self reloadHeaderView];
    }];
}
// 连接中
- (void)xoOnConnecting
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.isDisConnect = YES;
        self.title = @"Inbox (connecting)";
        [self reloadHeaderView];
    }];
}

#pragma mark ========================= XOMessageDelegate =========================

/**
 *  收到了已读回执
 *
 *  @param receipts 已读回执（TIMMessageReceipt*）列表
 */
- (void)xoOnRecvMessageReceipts:(NSArray*)receipts
{
    
}

/**
 *  消息修改通知
 *
 *  @param msgs 修改的消息列表，TIMMessage 类型数组
 */
- (void)xoOnMessageUpdate:(NSArray*)msgs
{
    
}

/**
 *  消息撤回通知
 *
 *  @param locator 被撤回消息的标识
 */
- (void)xoOnRevokeMessage:(TIMMessageLocator*)locator
{
    
}

/**
 *  群tips回调
 *
 *  @param elem  群tips消息
 */
- (void)xoOnGroupTipsEvent:(TIMGroupTipsElem*)elem
{
    
}

#pragma mark ========================= XOConversationDelegate =========================

- (void)xoOnRefresh
{
    [self loadConversation];
}

/**
 *  刷新部分会话（包括多终端已读上报同步）
 *
 *  @param conversations 会话（TIMConversation*）列表
 */
- (void)xoOnRefreshConversations:(NSArray <TIMConversation*>* )conversations
{
    NSLog(@"conversations: %@", conversations);
}

#pragma mark ====================== UITableViewDataSource =======================

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    XOConversationListCell *cell = [tableView dequeueReusableCellWithIdentifier:ConversationListCellID forIndexPath:indexPath];
    cell.conversation = [self.dataSource objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark ====================== UITableViewDelegate =======================

// 进入聊天
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TIMConversation *conversation = [self.dataSource objectAtIndex:indexPath.row];
    [conversation setReadMessage:nil succ:^{
        NSLog(@"设置消息已读成功");
        [self loadUnreadCount];
    } fail:^(int code, NSString *msg) {
        NSLog(@"设置消息已读失败");
    }];
    
    if (conversation) {
        XOChatViewController *chatVC = [[XOChatViewController alloc] init];
        chatVC.conversation = conversation;
        chatVC.chatType = [conversation getType];
        if (self.splitViewController) {
            [self.splitViewController showDetailViewController:chatVC sender:self];
        } else {
            [self.navigationController pushViewController:chatVC animated:YES];
        }
    }
}

//实现cell的左滑效果
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    
}

//自定义左滑效果
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    __block TIMConversation *conversation = [self.dataSource objectAtIndex:indexPath.row];
    
    @XOWeakify(self);
    BOOL isTop = NO;
    NSString *topTitle = !isTop ? XOChatLocalizedString(@"conversation.unTop.title") : XOChatLocalizedString(@"conversation.top.title");
    UITableViewRowAction *topRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:topTitle handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
    }];
    UITableViewRowAction *deleteRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:XOChatLocalizedString(@"conversation.delete.title") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        NSString *message = XOChatLocalizedString(@"conversation.delete.alertMsg");
        [self showAlertWithTitle:nil message:message sureTitle:XOChatLocalizedString(@"sure") cancelTitle:XOChatLocalizedString(@"cancel") sureComplection:^{
            @XOStrongify(self);
            if ([[TIMManager sharedInstance] deleteConversation:[conversation getType] receiver:[conversation getReceiver]]) {
                [SVProgressHUD showErrorWithStatus:XOChatLocalizedString(@"tip.delete.success")];
                [SVProgressHUD dismissWithDelay:1.0f];
                [self loadConversation];
            }
            else {
                [SVProgressHUD showErrorWithStatus:XOChatLocalizedString(@"tip.delete.fail")];
                [SVProgressHUD dismissWithDelay:1.0f];
            }
            
        } cancelComplection:^{
            NSLog(@"取消删除好友");
        }];
    }];
    return @[topRowAction, deleteRowAction];
}

- (void)refreshByGenralSettingChange:(XOGenralChangeType)genralType userInfo:(NSDictionary *)userInfo
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (XOGenralChangeFontSize == genralType) {
            [self.tableView reloadData];
        }
    }];
}


@end
