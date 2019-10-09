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

// 获取消息唯一的Key
FOUNDATION_STATIC_INLINE NSString * getMessageKey(TIMMessage *message) {
    
    if (message) {
        NSString *msgKey = [NSString stringWithFormat:@"%ld_%@", (long)[message.timestamp timeIntervalSince1970], message.msgId];
        return msgKey;
    }
    return nil;
}


@protocol XOChatClientProtocol;

@interface XOChatClient : NSObject

// 资源包
@property (nonatomic, strong, readonly) NSBundle                *chatBundle;
// 资源包
@property (nonatomic, strong, readonly) NSBundle                *chatResourceBundle;
// 资源包
@property (nonatomic, strong, readonly) NSBundle                *languageBundle;
// 会话管理器
@property (nonatomic, strong, readonly) XOConversationManager   *conversationManager;
// 消息管理器
@property (nonatomic, strong, readonly) XOMessageManager        *messageManager;
// 联系人管理器
@property (nonatomic, strong, readonly) XOContactManager        *contactManager;


+ (instancetype)shareClient;

/** @brief 初始化腾讯云 （在Appdelegate中初始化腾讯云）
 *  @param AppID 在腾讯云注册的APPID
 *  @param logFunc 云通信的日志回调函数, 仅在DEBUG时会回调
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


/**
 *  @brief 调度下载任务(常驻子线程中下载)
 *  方法中会自动判断消息是否需要下载, 是否正在下载中, 无需额外判断
 */
- (void)scheduleDownloadTask:(TIMMessage *)message;

// 获取图片的格式
- (NSString *)getImageFormat:(TIM_IMAGE_FORMAT)imageFormat;

// 是否正在下载中
- (BOOL)isOnDownloading:(TIMMessage *)message;

// 是否正在排队下载队列中
- (BOOL)isWaitingDownload:(TIMMessage *)message;


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


////////////// 下载文件

// 消息文件下载进度回调
- (void)message:(TIMMessage *)message downloadProgress:(float)progress;

// 消息文件下载成功回调
- (void)messageFileDownloadSuccess:(TIMMessage * _Nonnull)message fileURL:(NSURL * _Nullable)fileURL thumbImageURL:(NSURL * _Nullable)thumbImageURL;

// 消息文件下载失败回调
- (void)messageFileDownloadFail:(TIMMessage *)message failError:(NSError *)error;

// 缩略图下载成功
- (void)messageThumbImageDownloadSuccess:(TIMMessage * _Nonnull)message thumbImagePath:(NSString * _Nullable)thumbImagePath;

// 缩略图下载成功
- (void)messageThumbImageDownloadFail:(TIMMessage * _Nonnull)message;


// 消息文件上传进度回调
- (void)messageFileUpload:(TIMMessage *)message progress:(float)progress;



@end

NS_ASSUME_NONNULL_END
