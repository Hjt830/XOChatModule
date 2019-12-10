//
//  XOConversationListController.h
//  XOChatModule
//
//  Created by 乐派 on 2019/7/26.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import <XOBaseLib/XOBaseLib.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface XOConversationListController : XOBaseViewController

@property (nonatomic, assign) BOOL               showAddressBook;   // 是否显示通讯录 默认显示
@property (nonatomic, assign) BOOL               showCreateGroup;   // 是否显示创建群 默认显示

@end

NS_ASSUME_NONNULL_END
