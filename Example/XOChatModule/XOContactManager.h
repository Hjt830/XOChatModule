//
//  XOContactManager.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XOContactDelegate;

@interface XOContactManager : NSObject

+ (instancetype)defaultManager;

/**
 *  @brief 添加|删除代理
 */
- (void)addDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOContactDelegate>)delegate;

@end

@protocol XOContactDelegate <NSObject>



@end

NS_ASSUME_NONNULL_END
