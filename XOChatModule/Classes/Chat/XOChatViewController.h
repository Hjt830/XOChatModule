//
//  XOChatViewController.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <XOBaseLib/XOBaseLib.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface XOChatViewController : XOBaseViewController

@property (nonatomic, assign) TIMConversationType       chatType;
@property (nonatomic, assign) TIMConversation         * conversation;


@end

NS_ASSUME_NONNULL_END
