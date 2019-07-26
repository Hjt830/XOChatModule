//
//  XOConversationListViewModel.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//typedef BOOL(^ConversationListFilterBlock)(TUIConversationCellData *data);


@interface XOConversationListViewModel : NSObject

/**
 * 会话数据
 */
//@property (strong) NSArray<TUIConversationCellData *> *dataList;
///**
// * 过滤器
// */
//@property (copy) ConversationListFilterBlock listFilter;

/**
 * 加载会话数据
 */
- (void)loadConversation;
//
///**
// * 删除会话数据
// */
//- (void)removeData:(TUIConversationCellData *)data;

@end

NS_ASSUME_NONNULL_END
