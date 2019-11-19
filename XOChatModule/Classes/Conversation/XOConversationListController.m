//
//  XOConversationListController.m
//  XOChatModule
//
//  Created by 乐派 on 2019/7/26.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "XOConversationListController.h"
#import "XOContactListViewController.h"
#import "XOChatViewController.h"
#import "XOGroupSelectedController.h"
#import "GroupSettingInfoController.h"

#import "XOConversationListCell.h"
#import "XOLocalPushManager.h"
#import <XOBaseLib/XOBaseLib.h>
#import "XOChatModule.h"
#import "XOChatClient.h"
#import "XOContactManager.h"

#define Margin 10.0f
#define TableHeaderStateHeight   44.0f
#define TableHeaderViewMinHeight 160.0f
#define TableHeaderViewMaxHeight 200.0f

static NSString * const ConversationListCellID = @"ConversationListCellID";
static NSString * const ConversationHeadFootID = @"ConversationHeadFootID";

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
@property (nonatomic, strong) UIView                *onlineChatView;     // 在线客服视图
@property (nonatomic, strong) UILabel               *sysNameLabel;      // 系统消息
@property (nonatomic, strong) UILabel               *groupNameLabel;    // 群聊消息
@property (nonatomic, strong) UILabel               *unreadLabel;    // 群聊消息
@property (nonatomic, assign) BOOL                  isDisConnect;       // 连接是否断开

@property (nonatomic, strong) UITableView           *tableView;         // 会话列表

@property (nonatomic, strong) NSMutableArray    <TIMConversation *>* dataSource;   // 会话数据源
@property (nonatomic, strong) NSMutableArray    <TIMConversation *>* toppingArr;   // 会话数据源
@property (nonatomic, assign) int                   unreadServerCount;

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
        self.unreadServerCount = 0;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toppingDidChange:) name:XOGroupToppingDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[XOChatClient shareClient] removeDelegate:self];
    [[XOChatClient shareClient].conversationManager removeDelegate:self];
    [[XOChatClient shareClient].messageManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XOGroupToppingDidChangeNotification object:nil];
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
    [self.headerView addSubview:self.onlineChatView];
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.tableView];
    
    for (int i = 0; i < 2; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 56, 44);
        [button setTitleColor:[UIColor XOTextColor] forState:UIControlStateNormal];
        if (0 == i) {
            [button setTitle:XOChatLocalizedString(@"contact.addressbook") forState:UIControlStateNormal];
            [button addTarget:self action:@selector(contactList) forControlEvents:UIControlEventTouchUpInside];
            UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithCustomView:button];
            self.navigationItem.leftBarButtonItem = bbi;
        } else {
            [button setImage:[UIImage xo_imageNamedFromChatBundle:@"conversation_createGroup"] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(groupChat) forControlEvents:UIControlEventTouchUpInside];
            UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithCustomView:button];
            self.navigationItem.rightBarButtonItem = bbi;
        }
    }
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
        self.headerView.frame = CGRectMake(0, 0, self.view.width, TableHeaderViewMaxHeight);
        self.networkStateView.hidden = NO;
        self.systemView.frame = CGRectMake(_safeInset.left, self.networkStateView.bottom + Margin, self.view.width - (_safeInset.left + _safeInset.right), 70);
        self.onlineChatView.frame = CGRectMake(_safeInset.left, self.systemView.bottom + Margin, self.view.width - (_safeInset.left + _safeInset.right), 70);
    }
    // 连接状态
    else {
        self.headerView.frame = CGRectMake(0, 0, self.view.width, TableHeaderViewMinHeight);
        self.networkStateView.hidden = YES;
        self.systemView.frame = CGRectMake(_safeInset.left, 10, self.view.width - (_safeInset.left + _safeInset.right), 70);
        self.onlineChatView.frame = CGRectMake(_safeInset.left, self.systemView.bottom + Margin, self.view.width - (_safeInset.left + _safeInset.right), 70);
    }
    self.tableView.frame = CGRectMake(_safeInset.left, self.headerView.height + Margin, self.view.width - (_safeInset.left + _safeInset.right), self.view.height - (self.headerView.height + Margin));
}

#pragma mark ========================= touch event =========================

- (void)contactList
{
    XOContactListViewController *contactListVC = [[XOContactListViewController alloc] init];
    [self.navigationController pushViewController:contactListVC animated:YES];
}

- (void)groupChat
{
    XOGroupSelectedController *groupVC = [[XOGroupSelectedController alloc] init];
    groupVC.memberType = GroupMemberType_Create;
    [self.navigationController pushViewController:groupVC animated:YES];
}

- (void)chatWithOnlineService:(UITapGestureRecognizer *)tap
{
    TIMConversation *conv = [[TIMManager sharedInstance] getConversation:TIM_C2C receiver:OnlineServerIdentifier];
    if (conv) {
        [conv setReadMessage:nil succ:^{
            
            self.unreadServerCount = 0;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (self.unreadServerCount == 0) {
                    self.unreadLabel.text = @"";
                    self.unreadLabel.hidden = YES;
                } else {
                    self.unreadLabel.text = [NSString stringWithFormat:@"%d", self.unreadServerCount];
                    self.unreadLabel.hidden = NO;
                }
            }];
            
        } fail:^(int code, NSString *msg) {
            
        }];
        
        XOChatViewController *chatVC = [[XOChatViewController alloc] init];
        chatVC.conversation = conv;
        chatVC.chatType = TIM_C2C;
        [self.navigationController pushViewController:chatVC animated:YES];
    }
}

#pragma mark ====================== load data =======================

- (void)loadConversation
{
    @synchronized (self) {
        [self.dataSource removeAllObjects];
        [self.toppingArr removeAllObjects];
        NSArray <TIMConversation *>* conversationList = [[TIMManager sharedInstance] getConversationList];
        [conversationList enumerateObjectsUsingBlock:^(TIMConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // 过滤系统消息 和 客服消息
            if (obj.getType == TIM_C2C) {
                // 客服消息
                if ([OnlineServerIdentifier isEqualToString:obj.getReceiver]) {
                    self.unreadServerCount += obj.getUnReadMessageNum;
                }
                else {
                    [self.dataSource addObject:obj];
                }
            }
            else if (obj.getType == TIM_GROUP) {
                [self.dataSource addObject:obj];
            }
        }];
    };
    
    // 将置顶的会话放在前面
    __block NSArray *toppingArr = [XOContactManager defaultManager].toppingArray;
    if (toppingArr.count > 0) {
        [self.dataSource enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TIMConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([toppingArr containsObject:[obj getReceiver]]) {
                [self.toppingArr addObject:obj];
                [self.dataSource removeObject:obj];
            }
        }];
        // 按时间排序
        [self.dataSource sortUsingComparator:^NSComparisonResult(TIMConversation * _Nonnull obj1, TIMConversation * _Nonnull obj2) {
            return [[[obj2 getLastMsg] timestamp] compare:[[obj1 getLastMsg] timestamp]];
        }];
        [self.toppingArr sortUsingComparator:^NSComparisonResult(TIMConversation * _Nonnull obj1, TIMConversation * _Nonnull obj2) {
            return [[[obj2 getLastMsg] timestamp] compare:[[obj1 getLastMsg] timestamp]];
        }];
        // 插入会话集合前面
        NSMutableIndexSet *insexSet = [NSMutableIndexSet indexSet];
        [self.toppingArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [insexSet addIndex:idx];
        }];
        [self.dataSource insertObjects:self.toppingArr atIndexes:insexSet];
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
        
        if (self.unreadServerCount == 0) {
            self.unreadLabel.text = @"";
            self.unreadLabel.hidden = YES;
        } else {
            self.unreadLabel.text = [NSString stringWithFormat:@"%d", self.unreadServerCount];
            self.unreadLabel.hidden = NO;
        }
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

// 置顶或者取消置顶
- (void)operaTopping:(BOOL)topping WithReceiverId:(NSString *)receiverId
{
    if (!XOIsEmptyString(receiverId)) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (topping) {  // 置顶
                __block NSUInteger row = 0;
                __block TIMConversation *toppingConv = nil;
                [self.dataSource enumerateObjectsUsingBlock:^(TIMConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([[obj getReceiver] isEqualToString:receiverId]) {
                        row = idx;
                        toppingConv = obj;
                        @synchronized (self) {
                            [self.toppingArr addObject:obj];
                        }
                        *stop = YES;
                    }
                }];
                // 按照时间排序
                [self.toppingArr sortUsingComparator:^NSComparisonResult(TIMConversation * _Nonnull obj1, TIMConversation * _Nonnull obj2) {
                    return [[[obj2 getLastMsg] timestamp] compare:[[obj1 getLastMsg] timestamp]];
                }];
                NSUInteger newRow = [self.toppingArr indexOfObject:toppingConv];
                @synchronized (self) {
                    [self.dataSource removeObject:toppingConv];
                    [self.dataSource insertObject:toppingConv atIndex:newRow];
                }
                NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newRow inSection:0];
                [self.tableView moveRowAtIndexPath:oldIndexPath toIndexPath:newIndexPath];
            }
            else { // 取消置顶
                __block NSUInteger row = 0;
                __block TIMConversation *toppingConv = nil;
                [self.dataSource enumerateObjectsUsingBlock:^(TIMConversation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([[obj getReceiver] isEqualToString:receiverId]) {
                        row = idx;
                        toppingConv = obj;
                        @synchronized (self) {
                            [self.toppingArr removeObject:obj];
                        }
                        *stop = YES;
                    }
                }];
                if (self.dataSource.count > self.toppingArr.count) {
                    NSUInteger newRow = self.toppingArr.count;
                    @synchronized (self) {
                        [self.dataSource removeObject:toppingConv];
                        [self.dataSource insertObject:toppingConv atIndex:newRow];
                    }
                    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
                    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newRow inSection:0];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.tableView moveRowAtIndexPath:oldIndexPath toIndexPath:newIndexPath];
                    }];
                } else {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }];
                }
            }
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

#pragma mark ====================== lazy load =======================

- (NSMutableArray<TIMConversation *> *)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (NSMutableArray <TIMConversation *> *)toppingArr
{
    if (!_toppingArr) {
        _toppingArr = [NSMutableArray array];
    }
    return _toppingArr;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.rowHeight = 70.0f;
        if (@available(iOS 13.0, *)) _tableView.separatorColor = [UIColor systemGray6Color];
        else _tableView.separatorColor = [UIColor lightGrayColor];
        _tableView.separatorInset = UIEdgeInsetsMake(0, _tableView.rowHeight + 10, 0, 0);
        _tableView.sectionHeaderHeight = 0.0f;
        _tableView.sectionFooterHeight = 0.0f;
        _tableView.multipleTouchEnabled = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        
        [_tableView registerClass:[XOConversationListCell class] forCellReuseIdentifier:ConversationListCellID];
        [_tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:ConversationHeadFootID];
    }
    return _tableView;
}

- (UIView *)headerView
{
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = BG_TableColor;
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
        _systemView.backgroundColor = [UIColor XOWhiteColor];
        CALayer *imageLayer = [CALayer layer];
        imageLayer.contents = (__bridge id)[UIImage xo_imageNamedFromChatBundle:@"message_systemmessage"].CGImage;
        imageLayer.frame = CGRectMake(Margin, 7, 50.0, 50.0);
        imageLayer.masksToBounds = YES;
        imageLayer.cornerRadius = 25.0f;
        [_systemView.layer addSublayer:imageLayer];
        self.sysNameLabel = [[UILabel alloc] init];
        self.sysNameLabel.textColor = [UIColor XOTextColor];
        self.sysNameLabel.frame = CGRectMake(CGRectGetMaxX(imageLayer.frame) + Margin, 25, 240, 20);
        self.sysNameLabel.text = XOChatLocalizedString(@"conversation.systemMessage");
        self.sysNameLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        [_systemView addSubview:self.sysNameLabel];
    }
    return _systemView;
}

- (UIView *)onlineChatView
{
    if (!_onlineChatView) {
        _onlineChatView = [[UIView alloc] init];
        _onlineChatView.backgroundColor = [UIColor XOWhiteColor];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatWithOnlineService:)];
        [_onlineChatView addGestureRecognizer:tap];
        
        CALayer *imageLayer = [CALayer layer];
        imageLayer.contents = (__bridge id)[UIImage xo_imageNamedFromChatBundle:@"message_groupmessage"].CGImage;
        imageLayer.frame = CGRectMake(Margin, 7, 50.0, 50.0);
        imageLayer.masksToBounds = YES;
        imageLayer.cornerRadius = 25.0f;
        [_onlineChatView.layer addSublayer:imageLayer];
        
        _unreadLabel = [UILabel new];
        _unreadLabel.backgroundColor = [UIColor redColor];
        _unreadLabel.font = [UIFont systemFontOfSize:12];
        _unreadLabel.textColor = [UIColor whiteColor];
        _unreadLabel.textAlignment = NSTextAlignmentCenter;
        _unreadLabel.layer.cornerRadius = 9.0;
        _unreadLabel.clipsToBounds = YES;
        _unreadLabel.userInteractionEnabled = YES;
        _unreadLabel.hidden = YES;
        CGFloat unredLeft = CGRectGetMaxX(imageLayer.frame) - 9.0;
        CGFloat unredTop  = CGRectGetMinY(imageLayer.frame) - 5.0;
        self.unreadLabel.frame = CGRectMake(unredLeft, unredTop, 18.0, 18.0);
        [_onlineChatView addSubview:_unreadLabel];
        
        self.groupNameLabel = [[UILabel alloc] init];
        self.groupNameLabel.textColor = [UIColor XOTextColor];
        self.groupNameLabel.frame = CGRectMake(CGRectGetMaxX(imageLayer.frame) + Margin, 25, 240, 20);
        self.groupNameLabel.text = XOChatLocalizedString(@"conversation.onlineService");
        self.groupNameLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        self.groupNameLabel.userInteractionEnabled = YES;
        [_onlineChatView addSubview:self.groupNameLabel];
    }
    return _onlineChatView;
}

#pragma mark ========================= noti =========================

- (void)toppingDidChange:(NSNotification *)noti
{
    if (noti.userInfo) {
        NSString *groupId = noti.userInfo[@"groupId"];
        BOOL topping = [noti.userInfo[@"on"] boolValue];
        [self operaTopping:topping WithReceiverId:groupId];
    }
}

#pragma mark ====================== XOChatClientProtocol =======================

// 收到新消息
- (void)xoOnNewMessage:(NSArray <TIMMessage *>*)msgs
{
    // 客服角标
    [msgs enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
        // 客服消息
        TIMConversation *conversation = [message getConversation];
        if ([OnlineServerIdentifier isEqualToString:message.sender]) {
            self.unreadServerCount += [conversation getUnReadMessageNum];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                if (self.unreadServerCount == 0) {
                    self.unreadLabel.text = @"";
                    self.unreadLabel.hidden = YES;
                } else {
                    self.unreadLabel.text = [NSString stringWithFormat:@"%d", self.unreadServerCount];
                    self.unreadLabel.hidden = NO;
                }
            }];
        }
    }];
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
        [self.navigationController pushViewController:chatVC animated:YES];
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

//自定义左滑效果
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    __block TIMConversation *conversation = [self.dataSource objectAtIndex:indexPath.row];
    
    @XOWeakify(self);
    BOOL isTop = [[XOContactManager defaultManager] isToppingReceiver:[conversation getReceiver]];
    NSString *topTitle = isTop ? XOChatLocalizedString(@"conversation.unTop.title") : XOChatLocalizedString(@"conversation.top.title");
    UITableViewRowAction *topRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:topTitle handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        if (isTop) { // 置顶 -> 取消置顶
            if ([[XOContactManager defaultManager] removeToppingListWithReceiverId:[conversation getReceiver]]) {
                [self operaTopping:NO WithReceiverId:[conversation getReceiver]];
            }
        }
        else {  // 未置顶 -> 置顶
            if ([[XOContactManager defaultManager] addToppingListWithReceiverId:[conversation getReceiver]]) {
                [self operaTopping:YES WithReceiverId:[conversation getReceiver]];
            }
        }
    }];
    UITableViewRowAction *deleteRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:XOChatLocalizedString(@"conversation.delete.title") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        NSString *message = XOChatLocalizedString(@"conversation.delete.alertMsg");
        [self showAlertWithTitle:nil message:message sureTitle:XOChatLocalizedString(@"sure") cancelTitle:XOChatLocalizedString(@"cancel") sureComplection:^{
            @XOStrongify(self);
            if ([[TIMManager sharedInstance] deleteConversation:[conversation getType] receiver:[conversation getReceiver]]) {
                [SVProgressHUD showErrorWithStatus:XOChatLocalizedString(@"tip.delete.success")];
                [SVProgressHUD dismissWithDelay:1.0f];
                @synchronized (self) {
                    [self.dataSource removeObject:conversation];
                }
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }
            else {
                [SVProgressHUD showErrorWithStatus:XOChatLocalizedString(@"tip.delete.fail")];
                [SVProgressHUD dismissWithDelay:1.0f];
            }
            
        } cancelComplection:^{
            NSLog(@"取消删除会话");
        }];
    }];
    return @[deleteRowAction, topRowAction];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:ConversationHeadFootID];
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:ConversationHeadFootID];
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
