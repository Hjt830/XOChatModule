//
//  XOMessageManager.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOMessageManager.h"
#import <GCDMulticastDelegate/GCDMulticastDelegate.h>

@interface XOMessageManager ()
{
    GCDMulticastDelegate    <XOMessageDelegate> *_multiDelegate;
}
@end

static XOMessageManager *__msgManager = nil;

@implementation XOMessageManager

+ (instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __msgManager = [[XOMessageManager alloc] init];
    });
    return __msgManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _multiDelegate = [(GCDMulticastDelegate <XOMessageDelegate> *)[GCDMulticastDelegate alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_multiDelegate removeAllDelegates];
}

#pragma mark ========================= TIMMessageReceiptListener =========================
/**
 *  收到了已读回执
 *
 *  @param receipts 已读回执（TIMMessageReceipt*）列表
 */
- (void)onRecvMessageReceipts:(NSArray*)receipts
{
    NSLog(@"收到了已读回执: %@", receipts);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnRecvMessageReceipts:)]) {
        [_multiDelegate xoOnRecvMessageReceipts:receipts];
    }
}

#pragma mark ========================= TIMMessageUpdateListener =========================
/**
 *  消息修改通知
 *
 *  @param msgs 修改的消息列表，TIMMessage 类型数组
 */
- (void)onMessageUpdate:(NSArray*) msgs
{
    NSLog(@"消息修改通知: %@", msgs);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnMessageUpdate:)]) {
        [_multiDelegate xoOnMessageUpdate:msgs];
    }
}

#pragma mark ========================= TIMMessageRevokeListener =========================
/**
 *  消息撤回通知
 *
 *  @param locator 被撤回消息的标识
 */
- (void)onRevokeMessage:(TIMMessageLocator*)locator
{
    NSLog(@"消息撤回通知: %@", locator);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnRevokeMessage:)]) {
        [_multiDelegate xoOnRevokeMessage:locator];
    }
}

#pragma mark ========================= TIMGroupEventListener =========================
/**
 *  群tips回调
 *
 *  @param elem  群tips消息
 */
- (void)onGroupTipsEvent:(TIMGroupTipsElem*)elem
{
    NSLog(@"群tips回调: %@", elem);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnGroupTipsEvent:)]) {
        [_multiDelegate xoOnGroupTipsEvent:elem];
    }
}

#pragma mark ========================= 添加|删除代理 =========================

- (void)addDelegate:(id <XOMessageDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
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
- (void)removeDelegate:(id <XOMessageDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if ([_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegateQueue delegateQueue:delegateQueue];
    }
}
- (void)removeDelegate:(id <XOMessageDelegate>)delegate
{
    if ([_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegate delegateQueue:NULL];
    }
}

@end
