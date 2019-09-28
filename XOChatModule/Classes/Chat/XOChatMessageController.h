//
//  XOChatMessageController.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <XOBaseLib/XOBaseLib.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XOChatMessageControllerDelegate;

@interface XOChatMessageController : XOBaseViewController

@property (nonatomic, weak) id  <XOChatMessageControllerDelegate> delegate;
@property (nonatomic, strong) TIMConversation               *conversation;
@property (nonatomic, assign) TIMConversationType           chatType;   // 会话类型

- (void)safeAreaDidChange:(UIEdgeInsets)safeAreaInset;

// 添加发送中的消息
- (void)sendingMessage:(TIMMessage *)message;

// 修改发送中的消息为成功
- (void)sendSuccessMessage:(TIMMessage *)message;

// 修改发送中的消息为失败
- (void)sendFailMessage:(TIMMessage *)message;

// 删除消息
- (void)deleteMessage:(TIMMessage *)message;

// 更新消息
- (void)updateMessage:(TIMMessage *)message;

@end




@protocol XOChatMessageControllerDelegate <NSObject>

// 点击了聊天列表页面
- (void) didTapChatMessageView:(XOChatMessageController *)chatMsgViewController;
// @某人
- (void) didAtSomeOne:(NSString *)nick userId:(NSString *)userId;
// 拆红包
- (void) didReadRedPacketMessage:(TIMMessage *)message indexpath:(NSIndexPath *)indexPath ChatMessageView:(XOChatMessageController *)chatMsgViewController;
// 收转账
- (void) didReadTransferMessage:(TIMMessage *)message indexpath:(NSIndexPath *)indexPath ChatMessageView:(XOChatMessageController *)chatMsgViewController;

@end


NS_ASSUME_NONNULL_END
