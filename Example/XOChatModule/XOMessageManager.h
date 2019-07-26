//
//  XOMessageManager.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XOMessageDelegate;

@interface XOMessageManager : NSObject <TIMMessageReceiptListener, TIMMessageUpdateListener, TIMMessageRevokeListener>

+ (instancetype)defaultManager;

/**
 *  @brief 添加|删除代理
 */
- (void)addDelegate:(id <XOMessageDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOMessageDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOMessageDelegate>)delegate;

@end



@protocol XOMessageDelegate <NSObject>

/**
 *  收到了已读回执
 *
 *  @param receipts 已读回执（TIMMessageReceipt*）列表
 */
- (void) onRecvMessageReceipts:(NSArray*)receipts;

/**
 *  消息修改通知
 *
 *  @param msgs 修改的消息列表，TIMMessage 类型数组
 */
- (void)onMessageUpdate:(NSArray*)msgs;

/**
 *  消息撤回通知
 *
 *  @param locator 被撤回消息的标识
 */
- (void)onRevokeMessage:(TIMMessageLocator*)locator;

@end

NS_ASSUME_NONNULL_END
