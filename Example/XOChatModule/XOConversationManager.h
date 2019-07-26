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

// 获取所有会话列表个数
- (NSUInteger)ConversationCount;
// 获取所有会话列表
- (NSArray <TIMConversation *>*)getAllConversations;

/**
 *  @brief 添加|删除代理
 */
- (void)addDelegate:(id <XOConversationDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOConversationDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOConversationDelegate>)delegate;

@end



@protocol XOConversationDelegate <NSObject>

@optional
/**
 *  刷新会话
 */
- (void)xoOnRefresh;

/**
 *  刷新部分会话（包括多终端已读上报同步）
 *
 *  @param conversations 会话（TIMConversation*）列表
 */
- (void)xoOnRefreshConversations:(NSArray <TIMConversation*>* )conversations;

@end

NS_ASSUME_NONNULL_END
