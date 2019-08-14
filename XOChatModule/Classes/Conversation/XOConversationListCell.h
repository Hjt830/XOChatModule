//
//  XOConversationListCell.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/5.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface XOConversationListCell : UITableViewCell

@property (nonatomic, assign) BOOL                  shouldTopShow;  // 是否需要显示置顶效果, 默认不需要
@property (nonatomic, strong) TIMConversation       *conversation;

@end

NS_ASSUME_NONNULL_END
