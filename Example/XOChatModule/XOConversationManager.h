//
//  XOConversationManager.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XOConversationDelegate;

@interface XOConversationManager : NSObject <TIMRefreshListener>

+ (instancetype)defaultManager;

/**
 *  @brief 添加|删除代理
 */
- (void)addDelegate:(id <XOConversationDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOConversationDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOConversationDelegate>)delegate;

@end



@protocol XOConversationDelegate <NSObject>

/**
 *  刷新会话
 */
- (void)onRefresh;

/**
 *  刷新部分会话（包括多终端已读上报同步）
 *
 *  @param conversations 会话（TIMConversation*）列表
 */
- (void)onRefreshConversations:(NSArray*)conversations;

@end

NS_ASSUME_NONNULL_END
