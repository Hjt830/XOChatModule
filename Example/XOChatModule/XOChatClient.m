//
//  XOChatClient.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/5.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOChatClient.h"
#import <GCDMulticastDelegate/GCDMulticastDelegate.h>

@interface XOChatClient () <TIMUserStatusListener, TIMUploadProgressListener, TIMGroupEventListener, TIMFriendshipListener>
{
    GCDMulticastDelegate    <XOChatClientProtocol> *_multiDelegate;
}
@end

static XOChatClient *__chatClient = nil;

@implementation XOChatClient

+ (instancetype)shareClient
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __chatClient = [[XOChatClient alloc] init];
    });
    return __chatClient;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _conversationManager = [XOConversationManager defaultManager];
        _messageManager = [XOMessageManager defaultManager];
        
        _multiDelegate = (GCDMulticastDelegate <XOChatClientProtocol> *)[[GCDMulticastDelegate alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if (_multiDelegate) {
        [_multiDelegate removeAllDelegates];
    }
}

#pragma mark ========================= SDK init & login =========================

/** @brief 初始化SDK
 *  @param AppID 在腾讯云注册的APPID
 *  @param 云通信的日志回调函数, 仅在DEBUG时会回调
 *  @param 云通讯的长连接网络状态状态
 */
- (void)initSDKWithAppId:(int)AppID logFun:(TIMLogFunc _Nullable)logFunc connListener:(id <TIMConnListener> _Nullable)connListener
{
    TIMSdkConfig *config = [[TIMSdkConfig alloc] init];
    config.sdkAppId = AppID;
    config.connListener = connListener;
#if DEBUG
    config.disableLogPrint = NO;
    config.logLevel = TIM_LOG_WARN;
    config.logFunc = logFunc;
#else
    config.disableLogPrint = YES;
    config.logLevel = TIM_LOG_NONE;
#endif
    [[TIMManager sharedInstance] initSdk:config];
    
    TIMUserConfig *userConfig = [[TIMUserConfig alloc] init];
    userConfig.enableReadReceipt  = YES;
    userConfig.disableAutoReport = NO;
    userConfig.groupInfoOpt = [[TIMGroupInfoOption alloc] init];
    userConfig.groupMemberInfoOpt = [[TIMGroupMemberInfoOption alloc] init];
    userConfig.friendProfileOpt = [[TIMFriendProfileOption alloc] init];
    
    userConfig.userStatusListener = self;
    userConfig.refreshListener = _conversationManager;
    userConfig.messageReceiptListener = _messageManager;
    userConfig.messageUpdateListener = _messageManager;
    userConfig.messageRevokeListener = _messageManager;
    userConfig.uploadProgressListener = self;
    userConfig.groupEventListener = self;
    userConfig.friendshipListener = self;
    
    [[TIMManager sharedInstance] setUserConfig:userConfig];
}

/** @brief 登录腾讯云IM
 *  @param success 登录成功的回调
 *  @param fail 登录失败的回调
 */
- (void)loginWith:(TIMLoginParam * _Nonnull)param successBlock:(TIMLoginSucc _Nullable)success failBlock:(TIMFail _Nullable)fail
{
    [[TIMManager sharedInstance] login:param succ:^{
        
        NSLog(@"=================================");
        NSLog(@"========== 腾讯云登录成功 =========");
        NSLog(@"=================================\n");
        
        if (success) {success();}
        
        // 获取好友列表
        NSArray <TIMFriend *>* friendList = [[TIMManager sharedInstance].friendshipManager queryFriendList];
        NSLog(@"好友列表: %@", friendList);
        // 获取群列表
        [[TIMManager sharedInstance].groupManager getGroupList:^(NSArray<TIMGroupInfo *> *arr) {
            NSLog(@"查询群列表: %@", arr);
        } fail:^(int code, NSString *msg) {
            NSLog(@"查询群列表失败: code:%d  msg:%@", code, msg);
        }];
        
    } fail:^(int code, NSString *msg) {
        
        NSLog(@"=================================");
        NSLog(@"====== 腾讯云登录失败 code: %d  msg: %@ ======", code, msg);
        NSLog(@"=================================\n");
        
        if (fail) {fail(code, msg);}
    }];
}

#pragma mark ========================= TIMUserStatusListener =========================
/**
 *  踢下线通知
 */
- (void)onForceOffline
{
    NSLog(@"被踢下线");
    if ([_multiDelegate hasDelegateThatRespondsToSelector:@selector(onForceOffline)]) {
        [_multiDelegate onForceOffline];
    }
}
/**
 *  断线重连失败
 */
- (void)onReConnFailed:(int)code err:(NSString*)err
{
    NSLog(@"断线重连失败");
    if ([_multiDelegate hasDelegateThatRespondsToSelector:@selector(onReConnFailed:err:)]) {
        [_multiDelegate onReConnFailed:code err:err];
    }
}
/**
 *  用户登录的userSig过期（用户需要重新获取userSig后登录）
 */
- (void)onUserSigExpired
{
    NSLog(@"登录过期");
    if ([_multiDelegate hasDelegateThatRespondsToSelector:@selector(onUserSigExpired)]) {
        [_multiDelegate onUserSigExpired];
    }
}

#pragma mark ========================= 代理 =========================

- (void)addDelegate:(id <XOChatClientProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    // 判断是否已经添加同一个类的对象作为代理
    if (_multiDelegate && [_multiDelegate countOfClass:[delegate class]] == 0) {
        [_multiDelegate addDelegate:delegate delegateQueue:delegateQueue];
    }
}
- (void)removeDelegate:(id <XOChatClientProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (_multiDelegate && [_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegateQueue delegateQueue:delegateQueue];
    }
}
- (void)removeDelegate:(id <XOChatClientProtocol>)delegate
{
    if (_multiDelegate && [_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegate delegateQueue:NULL];
    }
}

#pragma mark ========================= TIMUploadProgressListener =========================
/**
 *  上传进度回调
 *
 *  @param msg      正在上传的消息
 *  @param elemidx  正在上传的elem的索引
 *  @param taskid   任务id
 *  @param progress 上传进度
 */
- (void)onUploadProgressCallback:(TIMMessage*)msg elemidx:(uint32_t)elemidx taskid:(uint32_t)taskid progress:(uint32_t)progress
{
    NSLog(@"上传进度回调: msg:%@   elemidx:%d   taskid:%d   progress:%d", msg, elemidx, taskid, progress);
}

#pragma mark ========================= TIMGroupEventListener =========================
/**
 *  群tips回调
 *
 *  @param elem  群tips消息
 */
- (void)onGroupTipsEvent:(TIMGroupTipsElem*)elem
{
    NSLog(@"群操作Tips回调: %@", elem);
}

#pragma mark ========================= TIMFriendshipListener =========================
/**
 *  添加好友通知
 *
 *  @param users 好友列表（NSString*）
 */
- (void)onAddFriends:(NSArray*)users
{
    NSLog(@"添加好友通知: %@", users);
}

/**
 *  删除好友通知
 *
 *  @param identifiers 用户id列表（NSString*）
 */
- (void)onDelFriends:(NSArray*)identifiers
{
    NSLog(@"添加好友通知: %@", identifiers);
}

/**
 *  好友资料更新通知
 *
 *  @param profiles 资料列表（TIMSNSChangeInfo *）
 */
- (void)onFriendProfileUpdate:(NSArray<TIMSNSChangeInfo *> *)profiles
{
    NSLog(@"添加好友通知: %@", profiles);
}

/**
 *  好友申请通知
 *
 *  @param reqs 好友申请者id列表（TIMFriendPendencyInfo *）
 */
- (void)onAddFriendReqs:(NSArray<TIMFriendPendencyInfo *> *)reqs
{
    NSLog(@"添加好友通知: %@", reqs);
}

@end
