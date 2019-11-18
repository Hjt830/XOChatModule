//
//  XOMessageManager.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOMessageManager.h"
#import "XOContactManager.h"
#import <XOBaseLib/XOBaseLib.h>
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

#pragma mark ========================= 处理群tip和群系统消息 =========================

- (void)handlerGroupSystemMessage:(NSArray <TIMMessage *> *)msgs
{
    [msgs enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (message.elemCount > 0)
        {
            TIMElem *elem = [message getElem:0];
            NSString *groupId = [[message getConversation] getReceiver];
            
            if (!XOIsEmptyString(groupId) && [elem isKindOfClass:[TIMGroupSystemElem class]]) // 群系统消息
            {
                TIMGroupSystemElem *systemElem = (TIMGroupSystemElem *)self;
                switch (systemElem.type) {
                    case TIM_GROUP_SYSTEM_KICK_OFF_FROM_GROUP_TYPE:  // 被管理员踢出群（只有被踢的人能够收到）
                    case TIM_GROUP_SYSTEM_DELETE_GROUP_TYPE:         // 群被解散（全员能够收到）
                    case TIM_GROUP_SYSTEM_QUIT_GROUP_TYPE:           // 主动退群（主动退群者能够收到）
                    case TIM_GROUP_SYSTEM_REVOKE_GROUP_TYPE:         // 群已被回收(全员接收)
                    {
                        // 删除通讯录中该群
                        [[XOContactManager defaultManager] deleteGroup:groupId handler:^(BOOL result) {
                            if (result) NSLog(@"======= 删除本地通讯录中群成功");
                            else NSLog(@"======= 删除本地通讯录中群失败");
                        }];
                        // 删除回话列表中该会话
                        [[TIMManager sharedInstance] deleteConversation:TIM_GROUP receiver:groupId];
                    }
                        break;
                    case TIM_GROUP_SYSTEM_CREATE_GROUP_TYPE:  // 创建群消息（创建者能够收到）
                    {
                        // 创建群时已经添加过群到通讯录, 无需重复添加
                    }
                        break;
                    case TIM_GROUP_SYSTEM_INVITED_TO_GROUP_TYPE:  // 邀请入群通知(被邀请者能够收到)
                    {
                        [[TIMGroupManager sharedInstance] getGroupInfo:@[groupId] succ:^(NSArray<TIMGroupInfo *> *arr) {
                            if (arr && arr.count > 0) {
                                // 删除通讯录中该群
                                [[XOContactManager defaultManager] insertGroup:arr[0] handler:^(BOOL result) {
                                    if (result) NSLog(@"======= 添加群到本地通讯录中成功");
                                    else NSLog(@"======= 添加群到本地通讯录中失败");
                                }];
                            }
                            else {
                                NSLog(@"=======  邀请入群通知 -- 查询群资料失败");
                            }
                        } fail:^(int code, NSString *msg) {
                            NSLog(@"=======  邀请入群通知 -- 查询群资料失败 code: %d  msg: %@", code, msg);
                        }];
                    }
                        break;
                    case TIM_GROUP_SYSTEM_GRANT_ADMIN_TYPE:  // 设置管理员(被设置者接收)
                    
                        break;
                    case TIM_GROUP_SYSTEM_CANCEL_ADMIN_TYPE:  // 取消管理员(被取消者接收)
                    
                        break;
                    case TIM_GROUP_SYSTEM_INVITE_TO_GROUP_REQUEST_TYPE:  // 邀请入群请求(被邀请者接收)
                    
                        break;
                    case TIM_GROUP_SYSTEM_INVITE_TO_GROUP_ACCEPT_TYPE:  // 邀请加群被同意(只有发出邀请者会接收到)
                    
                        break;
                    case TIM_GROUP_SYSTEM_INVITE_TO_GROUP_REFUSE_TYPE:  // 邀请加群被拒绝(只有发出邀请者会接收到)
                    
                        break;
                    case TIM_GROUP_SYSTEM_CUSTOM_INFO:  // 邀请加群被拒绝(只有发出邀请者会接收到)
                    
                        break;
                        
                    default:
                        break;
                }
            }
        }
    }];
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
