//
//  XOChatClient.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/5.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOChatClient.h"
#import <GCDMulticastDelegate/GCDMulticastDelegate.h>
#import <JTBaseLib/JTBaseLib.h>
#import "XOContactManager.h"

@interface XOChatClient () <TIMConnListener, TIMMessageListener, TIMUserStatusListener, TIMUploadProgressListener, TIMGroupEventListener, TIMFriendshipListener>
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
    [[TIMManager sharedInstance] removeMessageListener:self];
}

#pragma mark ========================= SDK init & login =========================

/** @brief 初始化SDK
 *  @param AppID 在腾讯云注册的APPID
 *  @param 云通信的日志回调函数, 仅在DEBUG时会回调
 *  @param 云通讯的长连接网络状态状态
 */
- (void)initSDKWithAppId:(int)AppID logFun:(TIMLogFunc _Nullable)logFunc
{
    TIMSdkConfig *config = [[TIMSdkConfig alloc] init];
    config.sdkAppId = AppID;
    config.connListener = self;
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
    userConfig.groupEventListener = _messageManager;
    userConfig.friendshipListener = _contactManager;
    
    [[TIMManager sharedInstance] setUserConfig:userConfig];
    
    [[TIMManager sharedInstance] addMessageListener:self];
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
        [[XOContactManager defaultManager] asyncFriendList];
        
        // 获取群列表
        [[XOContactManager defaultManager] asyncGroupList];
        
    } fail:^(int code, NSString *msg) {
        
        NSLog(@"=================================");
        NSLog(@"====== 腾讯云登录失败 code: %d  msg: %@ ======", code, msg);
        NSLog(@"=================================\n");
        
        if (fail) {fail(code, msg);}
        
        
        // 初始化存储 仅查看历史消息时使用
        [[TIMManager sharedInstance] initStorage:param succ:^{
            
            NSLog(@"初始化存储, 可查看历史消息");
            
        } fail:^(int code, NSString *msg) {
            
            NSLog(@"初始化存储失败, 不可查看历史消息");
        }];
    }];
}

#pragma mark ========================= TIMMessageListener =========================
/**
 *  新消息回调通知
 *
 *  @param msgs 新消息列表，TIMMessage 类型数组
 */
- (void)onNewMessage:(NSArray *)msgs
{
    JTLog(@"=================================\n=================================\n收到新消息条数: %lu \n收到新消息: %@\n=================================\n=================================", msgs.count, msgs);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnForceOffline)]) {
        [_multiDelegate xoOnForceOffline];
    }
}

#pragma mark ========================= TIMUserStatusListener =========================
/**
 *  踢下线通知
 */
- (void)onForceOffline
{
    JTLog(@"被踢下线");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnForceOffline)]) {
        [_multiDelegate xoOnForceOffline];
    }
}
/**
 *  断线重连失败
 */
- (void)onReConnFailed:(int)code err:(NSString*)err
{
    JTLog(@"断线重连失败");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnReConnFailed:err:)]) {
        [_multiDelegate xoOnReConnFailed:code err:err];
    }
}
/**
 *  用户登录的userSig过期（用户需要重新获取userSig后登录）
 */
- (void)onUserSigExpired
{
    JTLog(@"登录过期");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnUserSigExpired)]) {
        [_multiDelegate xoOnUserSigExpired];
    }
}

#pragma mark ========================= TIMConnListener =========================
/**
 *  网络连接成功
 */
- (void)onConnSucc
{
    JTLog(@"\n=======************======= TIM 网络连接成功");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnConnSucc)]) {
        [_multiDelegate xoOnConnSucc];
    }
}

/**
 *  网络连接失败
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)onConnFailed:(int)code err:(NSString*)err
{
    JTLog(@"\n=======************======= TIM 网络连接失败 code: %d err:%@", code, err);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnConnFailed:err:)]) {
        [_multiDelegate xoOnConnFailed:code err:err];
    }
}

/**
 *  网络连接断开（断线只是通知用户，不需要重新登陆，重连以后会自动上线）
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)onDisconnect:(int)code err:(NSString*)err
{
    JTLog(@"\n=======************======= TIM 网络连接断开 code: %d err:%@", code, err);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnDisconnect:err:)]) {
        [_multiDelegate xoOnDisconnect:code err:err];
    }
}

/**
 *  连接中
 */
- (void)onConnecting
{
    JTLog(@"\n=======************======= TIM 正在连接...");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnConnecting)]) {
        [_multiDelegate xoOnConnecting];
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

#pragma mark ========================= 代理 =========================

- (void)addDelegate:(id <XOChatClientProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (delegate != nil) {
        // 判断是否已经添加同一个类的对象作为代理
        if (delegateQueue == nil || delegateQueue == NULL) {
            if ([_multiDelegate countOfClass:[delegate class]] > 0) {
                [_multiDelegate removeDelegate:delegate];
            }
            [_multiDelegate addDelegate:delegate delegateQueue:dispatch_get_main_queue()];
        } else{
            if ([_multiDelegate countOfClass:[delegate class]] > 0) {
                [_multiDelegate removeDelegate:delegate];
            }
            [_multiDelegate addDelegate:delegate delegateQueue:delegateQueue];
        }
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

@end
