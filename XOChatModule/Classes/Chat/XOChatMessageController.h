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

@property (nonatomic, assign) TIMConversation               *conversation;
@property (nonatomic, assign) TIMConversationType           chatType;   // 会话类型

- (NSIndexPath *)addMessage:(TIMMessage *)message;

- (void)deleteMessage:(TIMMessage *)message;

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
