//
//  XOConversationListController.m
//  XOChatModule
//
//  Created by 乐派 on 2019/7/26.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "XOConversationListController.h"
#import "XOConversationListCell.h"

#import "XOChatModule.h"
#import "XOChatClient.h"

#define TableHeaderStateHeight   44.0f
#define TableHeaderViewMinHeight self.searchController.searchBar.height
#define TableHeaderViewMaxHeight (TableHeaderViewMinHeight + TableHeaderStateHeight)

static NSString * const ConversationListCellID = @"ConversationListCellID";
static NSString * const ConversationHeadCellID = @"ConversationHeadCellID";

@interface XOConversationListController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, XOChatClientProtocol, XOMessageDelegate, XOConversationDelegate>
{
    float historyY;
}

@property (nonatomic, weak) UITabBarItem            *chatTabbarItem;
@property (nonatomic, strong) UITableView           *tableView;         // 会话列表

@property (nonatomic, strong) UIView                *tableHeaderView;   // 头部视图
@property (nonatomic, strong) UIView                *systemView;        // 系统消息视图
@property (nonatomic, strong) UIView                *groupChatView;     // 发起群聊视图
@property (nonatomic, strong) UIView                *networkStateView;  // 断网视图

@property (nonatomic, strong) UILabel               *networkStateLabel;
@property (nonatomic, strong) UIView                *webPcOnlineView;   // web或者pc在线视图
@property (nonatomic, strong) UILabel               *webPcOnlineLabel;
@property (nonatomic, assign) BOOL                  isDisConnect;       // 连接是否断开

@property (nonatomic, strong) NSArray    <TIMConversation *>* dataSource;   // 会话数据源

@end

@implementation XOConversationListController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isDisConnect = NO; // 默认是连接状态
        [[XOChatClient shareClient] addDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
        [[XOChatClient shareClient].conversationManager addDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
        [[XOChatClient shareClient].messageManager addDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
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
    
    [self switchWebStateAndDisConnectState];
    
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
    
    [self setupSubViews];
    
    [self loadUnreadCount];
}

- (void)setupSubViews
{
    [self.tableHeaderView addSubview:self.networkStateView];
    [self.tableHeaderView addSubview:self.systemView];
    [self.tableHeaderView addSubview:self.groupChatView];
    [self.view addSubview:self.menuView];
    
    [self.tableHeaderView addSubview:self.networkStateView];
    self.tableView.tableHeaderView = self.tableHeaderView;
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.tableView.frame = self.view.frame;
    // 连接断开 或 者登录了其他客户端
    if (self.isDisConnect) {
        self.tableHeaderView.frame = CGRectMake(0, 0, KWIDTH, TableHeaderViewMaxHeight);
    } else {
        self.tableHeaderView.frame = CGRectMake(0, 0, KWIDTH, TableHeaderViewMinHeight);
    }
}

/**
 *  切换显示 断网状态栏和web登录状态栏
 */
- (void)reloadTableHeaderView
{
    // 断网状态
    if (self.isDisConnect) {
        self.networkStateView.hidden = NO;
        self.tableHeaderView.height = TableHeaderViewMaxHeight;
    }
    // 连接状态
    else {
        self.networkStateView.hidden = YES;
    }
    self.tableView.tableHeaderView = self.tableHeaderView;
}

#pragma mark ====================== load data =======================

- (void)loadConversation
{
    self.dataSource = [[TIMManager sharedInstance] getConversationList];
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
                    self.chatTabbarItem = self.tabBarController.tabBar.items;
                    *stop = YES;
                }
            }];
        }
    }
    if (!self.chatTabbarItem) {
        if (self.navigationController.tabBarController) {
            [[self.navigationController.tabBarController viewControllers] enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isEqual:self.navigationController]) {
                    self.chatTabbarItem = self.tabBarController.tabBar.items;
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
        [self.chatTabbarItem setBadgeValue:[NSString stringWithFormat:@"%lu", unredCount]];
    }
}

#pragma mark ====================== lazy load =======================

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.rowHeight = 70.0f;
        _tableView.separatorColor = RGBACOLOR(220, 220, 220, 1);
        _tableView.separatorInset = UIEdgeInsetsMake(0, _tableView.rowHeight + 10, 0, 0);
        _tableView.sectionHeaderHeight = 0.0f;
        _tableView.sectionFooterHeight = 0.0f;
        _tableView.multipleTouchEnabled = NO;
        
        [_tableView registerClass:[XOConversationListCell class] forCellReuseIdentifier:ConversationListCellID];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ConversationHeadCellID];
    }
    return _tableView;
}

- (UIView *)tableHeaderView
{
    if (!_tableHeaderView) {
        _tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, KWIDTH, TableHeaderViewMinHeight)];
        _tableHeaderView.backgroundColor = [UIColor whiteColor];
        _tableHeaderView.clipsToBounds = YES;
    }
    return _tableHeaderView;
}

- (UIView *)networkStateView
{
    if (_networkStateView == nil) {
        _networkStateView = [[UIView alloc]initWithFrame:CGRectMake(0, TableHeaderViewMinHeight, KWIDTH, TableHeaderStateHeight)];
        _networkStateView.backgroundColor = RGBACOLOR(255, 125, 141, 0.7);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(25, (_networkStateView.height - 20)/2, 20, 20)];
        imageView.image = [UIImage imageNamed:@"messageSendFail"];
        [_networkStateView addSubview:imageView];
        [_networkStateView addSubview:self.networkStateLabel];
    }
    return _networkStateView;
}

- (UILabel *)networkStateLabel
{
    if (_networkStateLabel == nil) {
        _networkStateLabel = [[UILabel alloc]initWithFrame:CGRectMake(70, 0, KWIDTH - 80, TableHeaderStateHeight)];
        _networkStateLabel.textAlignment = NSTextAlignmentLeft;
        _networkStateLabel.textColor = [UIColor darkTextColor];
        _networkStateLabel.font = [UIFont systemFontOfSize:14];
    }
    return _networkStateLabel;
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
    self.isDisConnect = NO;
    self.title = @"Inbox";
}
// 网络连接失败
- (void)xoOnConnFailed:(int)code err:(NSString*)err
{
    self.isDisConnect = YES;
    self.title = @"Inbox (unConnect)";
}
// 网络连接断开（断线只是通知用户，不需要重新登陆，重连以后会自动上线）
- (void)xoOnDisconnect:(int)code err:(NSString*)err
{
    self.isDisConnect = YES;
    self.title = @"Inbox (unConnect)";
}
// 连接中
- (void)xoOnConnecting
{
    self.title = @"Inbox (Connecting)";
}

#pragma mark ========================= XOMessageDelegate =========================

#pragma mark ========================= XOConversationDelegate =========================

#pragma mark ====================== UITableViewDataSource =======================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSUInteger count = self.dataSource.count > 0 ? 1 : 0;
    return 2 + count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (2 == section) {
        return self.dataSource.count;
    }
    return 1;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (2 == indexPath.section) {
        XOConversationListCell *cell = [tableView dequeueReusableCellWithIdentifier:ConversationListCellID forIndexPath:indexPath];
        cell.conversation = [self.fetchedResultController objectAtIndexPath:indexPath];
        [cell refreshGenralSetting];
        return cell;
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#(nonnull NSString *)#> forIndexPath:<#(nonnull NSIndexPath *)#>]
    }
}

#pragma mark ====================== UITableViewDelegate =======================

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HTConversation *conversation = [self.fetchedResultController objectAtIndexPath:indexPath];
    if (conversation) {
        // 跳转聊天页面
        WXChatViewController *chatVC = [[WXChatViewController alloc] init];
        chatVC.chatType = (conversation.msgType == HTMessageTypeNormal) ? conversation.message.chatType : conversation.cmdMessage.chatType;
        chatVC.chatterId = [conversation.chatterId copy];
        [self.navigationController pushViewController:chatVC animated:YES];
        // 会话未读数设置为0
        conversation.unReadCount = 0;
        [[WXMsgCoreDataManager shareManager].mainMOC MR_saveToPersistentStoreAndWait];
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
    editingStyle = UITableViewCellEditingStyleDelete;
}

//自定义左滑效果
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    __block HTConversation *conversation = [self.fetchedResultController objectAtIndexPath:indexPath];
    @WXWeakify(self);
    UITableViewRowAction *deleteRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"conversation.delete.title", @"Delete") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        @WXStrongify(self);
        NSString *message = NSLocalizedString(@"conversation.delete.alertMsg", nil);
        [self showSheetWithTitle:nil message:message actions:@[NSLocalizedString(@"sure", nil)] complection:^(int index, NSString *title) {
            [conversation MR_deleteEntity];
            [[WXMsgCoreDataManager shareManager].mainMOC MR_saveToPersistentStoreAndWait];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"from == %@ OR to == %@", conversation.chatterId, conversation.chatterId];
            [[HTMessage MR_findAllWithPredicate:predicate] enumerateObjectsUsingBlock:^(__kindof NSManagedObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj MR_deleteEntity];
            }];
            [[WXMsgCoreDataManager shareManager].mainMOC MR_saveToPersistentStoreAndWait];
        } cancelComplection:^{
            NSLog(@"取消删除好友");
        }];
    }];
    NSString *top = conversation.isTop ? NSLocalizedString(@"conversation.unTop.title", @"unTop") : NSLocalizedString(@"conversation.top.title", @"Top");
    UITableViewRowAction *topRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:top handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        conversation.isTop = !conversation.isTop;
        [[WXMsgCoreDataManager shareManager].mainMOC MR_saveToPersistentStoreAndWait];
        [self loadConversations];
    }];
    return @[deleteRowAction, topRowAction];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    historyY = scrollView.contentOffset.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    float offsetY = scrollView.contentOffset.y - historyY;
    NSValue *tableInset = [NSValue valueWithUIEdgeInsets:self.tableView.contentInset];
    NSValue *zeroInset  = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsZero];
    if (zeroInset != tableInset && offsetY <= -TableHeaderStateHeight) {
        self.tableView.contentInset = UIEdgeInsetsZero;
    }
}

#pragma mark ====================== NSFetchedResultsControllerDelegate =======================

// Cell数据源发生改变会回调此方法，例如添加新的托管对象等
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate: {
            [self loadConversations];
        }
            break;
    }
}

// Section数据源发生改变回调此方法，例如修改section title等
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate: {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sectionIndex inSection:0];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
            break;
        default:
            break;
    }
}

// 本地数据源发生改变，将要开始回调FRC代理方法。
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

// 本地数据源发生改变，FRC代理方法回调完成。
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark ====================== HTClientDelegate =======================

- (void)willAutoLogin {}

- (void)didAutoLoginResult:(BOOL)result error:(NSError * _Nullable)error
{
    if (!result) {
        self.isDisConnect = YES;
        [self switchWebStateAndDisConnectState];
    }
}

- (void)didBanedAccountByServer {}

- (void)conflictWithOtherDevice {}

- (void)didLoginHasExpired {}

// xmpp的连接状态
- (void)connectionStateDidChange:(HTConnectionState)state
{
    switch (state) {
        case HTConnectionStateConnecting:
            self.isDisConnect = NO;
            break;
        case HTConnectionStateConnected:
            self.isDisConnect = NO;
            [self loadConversations];
            break;
        case HTConnectionStateDisconnected:
            self.isDisConnect = YES;
            self.webOrPCLogin = NO;
            break;
        default:
            break;
    }
    [self switchWebStateAndDisConnectState];
}

// web/pc端微迅上下线状态变化  status 在线的状态  clientType 客户端类型
- (void)webOrPcAvailableChange:(HTAvailableStatus)status clientType:(HTClientType)clientType
{
    if (HTAvailableStatusAvailable == status) { // 上线
        self.webOrPCLogin = YES;
        switch (clientType) {
            case HTClientTypeWeb:
                self.webPcOnlineLabel.text = NSLocalizedString(@"author.loginRequest.web", nil);
                break;
            case HTClientTypePC:
                self.webPcOnlineLabel.text = NSLocalizedString(@"author.loginRequest.pc", nil);
                break;
            case HTClientTypeWindows:
                self.webPcOnlineLabel.text = NSLocalizedString(@"author.loginStatus.windows", nil);
                break;
            case HTClientTypeMac:
                self.webPcOnlineLabel.text = NSLocalizedString(@"author.loginStatus.mac", nil);
                break;
            default:
                self.webOrPCLogin = NO; // App的话，就是自己登录，不需要显示
                break;
        }
    }
    else { // 下线
        self.webOrPCLogin = NO;
    }
    [self switchWebStateAndDisConnectState];
}

#pragma mark ====================== UISearchBarDelegate =======================

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.tabBarController.tabBar setHidden:YES];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.tabBarController.tabBar setHidden:NO];
}

#pragma mark ====================== help =======================

/**
 *  切换显示 断网状态栏和web登录状态栏
 */
- (void)switchWebStateAndDisConnectState
{
    // 断网状态
    if (self.isDisConnect) {
        self.networkStateView.hidden = NO;
        self.tableHeaderView.height = TableHeaderViewMaxHeight;
        
        // 会话在最前面, 改变导航栏标题
        if (self.navigationController.topViewController == self.tabBarController && 0 == self.tabBarController.selectedIndex) {
            self.tabBarController.navigationItem.title = [NSString stringWithFormat:@"%@(%@)", NSLocalizedString(@"title.chats", nil), NSLocalizedString(@"title.unConnected", nil)];
            self.networkStateLabel.text = NSLocalizedString(@"network.disconnected", @"Network disconnected, please check network");
        }
    }
    // 连接状态
    else {
        self.networkStateView.hidden = YES;
        // 其他客户端登录
        if (self.webOrPCLogin) {
            self.webPcOnlineView.hidden = NO;
            self.tableHeaderView.height = TableHeaderViewMinHeight;
        }
        // 其他客户端未登录
        else {
            self.webPcOnlineView.hidden = YES;
            self.tableHeaderView.height = TableHeaderViewMinHeight;
        }
        
        // 会话在最前面, 改变导航栏标题
        if (self.navigationController.topViewController == self.tabBarController && 0 == self.tabBarController.selectedIndex) {
            self.tabBarController.navigationItem.title = NSLocalizedString(@"title.chats", @"微迅");
        }
    }
    self.tableView.tableHeaderView = self.tableHeaderView;
}


@end
