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

NS_ASSUME_NONNULL_BEGIN

/// 用户在线状态协议
@protocol XOChatClientProtocol <NSObject>

@optional
// 踢下线通知
- (void)onForceOffline;
// 断线重连失败
- (void)onReConnFailed:(int)code err:(NSString*)err;
// 用户登录的userSig过期（用户需要重新获取userSig后登录）
- (void)onUserSigExpired;

@end



@interface XOChatClient : NSObject

@property (nonatomic, strong, readonly) XOConversationManager   *conversationManager;
@property (nonatomic, strong, readonly) XOMessageManager        *messageManager;


+ (instancetype)shareClient;

/** @brief 初始化腾讯云 （在Appdelegate中初始化腾讯云）
 *  @param AppID 在腾讯云注册的APPID
 *  @param 云通信的日志回调函数, 仅在DEBUG时会回调
 *  @param 云通讯的长连接网络状态状态
 */
- (void)initSDKWithAppId:(int)AppID
                  logFun:(TIMLogFunc _Nullable)logFunc
            connListener:(id <TIMConnListener> _Nullable)connListener;

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

NS_ASSUME_NONNULL_END
