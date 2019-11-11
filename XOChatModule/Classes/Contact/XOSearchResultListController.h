//
//  XOSearchResultListController.h
//  XOChatModule
//
//  Created by kenter on 2019/10/11.
//

#import <XOBaseLib/XOBaseLib.h>

NS_ASSUME_NONNULL_BEGIN

@class XOSearchResultListController;
@protocol XOSearchResultDelegate <NSObject>

@optional
- (void)XOSearchList:(XOSearchResultListController *)search didSelectContact:(id)object;
- (void)XOSearchListDidScrollTable:(XOSearchResultListController *)search;

@end


typedef NS_ENUM(NSUInteger, XOSearchType) {
    XOSearchTypeContact     = 101,      // 联系人页面搜索
    XOSearchTypeGroup       = 102,      // 群组页面搜索
    XOSearchTypeAddFriend   = 103,      // 添加联系人页面搜索
    XOSearchTypeConversation= 104,      // 会话页面搜索
    XOSearchTypeCarte       = 105,      // 个人名片页面搜索
};

@interface XOSearchResultListController : XOBaseViewController <UISearchResultsUpdating, UISearchControllerDelegate>

@property (nonatomic, assign) XOSearchType      searchType;

@property (nonatomic, weak) id <XOSearchResultDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
