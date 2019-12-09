//
//  XOConversationListController.h
//  XOChatModule
//
//  Created by 乐派 on 2019/7/26.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import <XOBaseLib/XOBaseLib.h>
#import <ImSDK/ImSDK.h>

@class XOConversationListController;
@protocol XOConversationListControllerDelegate <NSObject>

@optional
- (BOOL)conversationListControllerShouldShowAddressBook:(XOConversationListController *_Nonnull)controller; // 是否显示通讯录按钮, 默认显示
- (BOOL)conversationListControllerShouldShowCreateGroup:(XOConversationListController *_Nonnull)controller; // 是否显示创建群按钮, 默认显示

@end

NS_ASSUME_NONNULL_BEGIN

@interface XOConversationListController : XOBaseViewController

@property (nonatomic, weak) id <XOConversationListControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
