//
//  XOChatClient.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/5.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImSDK/ImSDK.h>

#import "XOConversationManager.h"
#import "XOMessageManager.h"
#import "XOContactManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol XOChatClientProtocol;

@interface XOChatClient : NSObject

// 会话管理器
@property (nonatomic, strong, readonly) XOConversationManager   *conversationManager;
// 消息管理器
@property (nonatomic, strong, readonly) XOMessageManager        *messageManager;
// 联系人管理器
@property (nonatomic, strong, readonly) XOContactManager        *contactManager;


+ (instancetype)shareClient;

/** @brief 初始化腾讯云 （在Appdelegate中初始化腾讯云）
 *  @param AppID 在腾讯云注册的APPID
 *  @param 云通信的日志回调函数, 仅在DEBUG时会回调
 */
- (void)initSDKWithAppId:(int)AppID logFun:(TIMLogFunc _Nullable)logFunc;

/** @brief 登录腾讯云
 *  @param success 登录成功的回调
 *  @param fail 登录失败的回调
 */
- (void)loginWith:(TIMLoginParam * _Nonnull)param successBlock:(TIMLoginSucc _Nullable)success failBlock:(TIMFail _Nullable)fail;


/**
 *  @brief 添加|删除代理
 */
- (void)addDelegate:(id <XOChatClientProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOChatClientProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOChatClientProtocol>)delegate;

@end


/// 用户在线状态协议
@protocol XOChatClientProtocol <NSObject>


@required
// 收到新消息
- (void)xoOnNewMessage:(NSArray <TIMMessage *>*)msgs;

@optional
/**
 *  踢下线通知
 */
- (void)xoOnForceOffline;

/**
 *  断线重连失败
 */
- (void)xoOnReConnFailed:(int)code err:(NSString*)err;

/**
 *  用户登录的userSig过期（用户需要重新获取userSig后登录）
 */
- (void)xoOnUserSigExpired;


/**
 *  网络连接成功
 */
- (void)xoOnConnSucc;

/**
 *  网络连接失败
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)xoOnConnFailed:(int)code err:(NSString*)err;

/**
 *  网络连接断开（断线只是通知用户，不需要重新登陆，重连以后会自动上线）
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)xoOnDisconnect:(int)code err:(NSString*)err;

/**
 *  连接中
 */
- (void)xoOnConnecting;

@end

NS_ASSUME_NONNULL_END
