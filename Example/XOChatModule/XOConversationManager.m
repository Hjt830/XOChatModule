//
//  XOConversationManager.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOConversationManager.h"
#import <GCDMulticastDelegate/GCDMulticastDelegate.h>

@interface XOConversationManager ()
{
    GCDMulticastDelegate    <XOConversationDelegate> *_multiDelegate;
}
@end

static XOConversationManager *__conversationManager = nil;

@implementation XOConversationManager

+ (instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __conversationManager = [[XOConversationManager alloc] init];
    });
    return __conversationManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _multiDelegate = (GCDMulticastDelegate <XOConversationDelegate> *)[[GCDMulticastDelegate alloc] init];
    }
    return self;
}

#pragma mark ========================= TIMRefreshListener =========================
/**
 *  刷新会话
 */
- (void)onRefresh
{
    NSLog(@"刷新会话");
    if ([_multiDelegate hasDelegateThatRespondsToSelector:@selector(onRefresh)]) {
        [_multiDelegate onRefresh];
    }
}
/**
 *  刷新部分会话（包括多终端已读上报同步）
 *
 *  @param conversations 会话（TIMConversation*）列表
 */
- (void)onRefreshConversations:(NSArray*)conversations
{
    NSLog(@"刷新部分会话（包括多终端已读上报同步）: %@", conversations);
    if ([_multiDelegate hasDelegateThatRespondsToSelector:@selector(onRefreshConversations:)]) {
        [_multiDelegate onRefreshConversations:conversations];
    }
}

#pragma mark ========================= 添加|删除代理 =========================

- (void)addDelegate:(id <XOConversationDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    // 判断是否已经添加同一个类的对象作为代理
    if ([_multiDelegate countOfClass:[delegate class]] == 0) {
        [_multiDelegate addDelegate:delegate delegateQueue:delegateQueue];
    }
}
- (void)removeDelegate:(id <XOConversationDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if ([_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegateQueue delegateQueue:delegateQueue];
    }
}
- (void)removeDelegate:(id <XOConversationDelegate>)delegate
{
    if ([_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegate delegateQueue:NULL];
    }
}


@end
