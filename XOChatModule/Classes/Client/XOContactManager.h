//
//  XOContactManager.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XOContactDelegate;

@interface XOContactManager : NSObject <TIMFriendshipListener>

+ (instancetype)defaultManager;

// 同步好友列表
- (void)asyncFriendList;
// 同步群列表
- (void)asyncGroupList;

/**
 *  @brief 添加|删除代理
 */
- (void)addDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOContactDelegate>)delegate;

@end

@protocol XOContactDelegate <NSObject>

@optional
/**
 *  添加好友通知
 *
 *  @param users 好友列表（NSString*）
 */
- (void)xoOnAddFriends:(NSArray*)users;

/**
 *  删除好友通知
 *
 *  @param identifiers 用户id列表（NSString*）
 */
- (void)xoOnDelFriends:(NSArray*)identifiers;

/**
 *  好友资料更新通知
 *
 *  @param profiles 资料列表（TIMSNSChangeInfo *）
 */
- (void)xoOnFriendProfileUpdate:(NSArray<TIMSNSChangeInfo *> *)profiles;

/**
 *  好友申请通知
 *
 *  @param reqs 好友申请者id列表（TIMFriendPendencyInfo *）
 */
- (void)xoOnAddFriendReqs:(NSArray<TIMFriendPendencyInfo *> *)reqs;

@end

NS_ASSUME_NONNULL_END
