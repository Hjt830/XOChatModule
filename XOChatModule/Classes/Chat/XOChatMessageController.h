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

@end




@protocol XOChatMessageControllerDelegate <NSObject>





@end


NS_ASSUME_NONNULL_END
