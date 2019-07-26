//
//  XOContactManager.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOContactManager.h"
#import <GCDMulticastDelegate/GCDMulticastDelegate.h>

static XOContactManager * __contactManager = nil;

@interface XOContactManager ()
{
    GCDMulticastDelegate    <XOContactDelegate> *_multiDelegate;
}
@end

@implementation XOContactManager

+ (instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __contactManager = [[XOContactManager alloc] init];
    });
    return __contactManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _multiDelegate = [(GCDMulticastDelegate <XOContactDelegate> *)[GCDMulticastDelegate alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_multiDelegate removeAllDelegates];
}

#pragma mark ========================= 通讯录列表同步 =========================

// 同步好友列表
- (void)asyncFriendList
{
    // 获取好友列表
    [[TIMManager sharedInstance].friendshipManager getFriendList:^(NSArray<TIMFriend *> *friends) {
        NSLog(@"好友列表: %@", friends);
        
    } fail:^(int code, NSString *msg) {
        NSLog(@"查询好友列表失败: code:%d  msg:%@", code, msg);
    }];
}

// 同步群列表
- (void)asyncGroupList
{
    // 获取群列表
    [[TIMManager sharedInstance].groupManager getGroupList:^(NSArray<TIMGroupInfo *> *arr) {
        NSLog(@"查询群列表: %@", arr);
        
    } fail:^(int code, NSString *msg) {
        NSLog(@"查询群列表失败: code:%d  msg:%@", code, msg);
    }];
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
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnAddFriends:)]) {
        [_multiDelegate xoOnAddFriends:users];
    }
}

/**
 *  删除好友通知
 *
 *  @param identifiers 用户id列表（NSString*）
 */
- (void)onDelFriends:(NSArray*)identifiers
{
    NSLog(@"删除好友通知: %@", identifiers);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnDelFriends:)]) {
        [_multiDelegate xoOnDelFriends:identifiers];
    }
}

/**
 *  好友资料更新通知
 *
 *  @param profiles 资料列表（TIMSNSChangeInfo *）
 */
- (void)onFriendProfileUpdate:(NSArray<TIMSNSChangeInfo *> *)profiles
{
    NSLog(@"好友资料更新通知: %@", profiles);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnFriendProfileUpdate:)]) {
        [_multiDelegate xoOnFriendProfileUpdate:profiles];
    }
}

/**
 *  好友申请通知
 *
 *  @param reqs 好友申请者id列表（TIMFriendPendencyInfo *）
 */
- (void)onAddFriendReqs:(NSArray<TIMFriendPendencyInfo *> *)reqs
{
    NSLog(@"好友申请通知: %@", reqs);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnAddFriendReqs:)]) {
        [_multiDelegate xoOnAddFriendReqs:reqs];
    }
}

#pragma mark ========================= 添加|删除代理 =========================

- (void)addDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
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
- (void)removeDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if ([_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegateQueue delegateQueue:delegateQueue];
    }
}
- (void)removeDelegate:(id <XOContactDelegate>)delegate
{
    if ([_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegate delegateQueue:NULL];
    }
}

@end
