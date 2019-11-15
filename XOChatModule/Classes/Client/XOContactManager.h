//
//  XOContactManager.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XOContactDelegate;

@interface XOContactManager : NSObject <TIMFriendshipListener>

@property (nonatomic, strong, readonly) NSArray               <NSString *>* muteArray;  // 免打扰群
@property (nonatomic, strong, readonly) NSArray               <NSString *>* toppingArray;  // 置顶群


+ (instancetype)defaultManager;

// 同步好友列表
- (void)asyncFriendList;
// 同步群列表
- (void)asyncGroupList;


// 是否免打扰群
- (BOOL)isMuteGroup:(NSString *)groupId;
// 增加免打扰群
- (BOOL)addMuteListWithGroupId:(NSString *)groupId;
// 删除免打扰群
- (BOOL)removeMuteListWithGroupId:(NSString *)groupId;

// 是否置顶了群
- (BOOL)isToppingGroup:(NSString *)groupId;
// 增加置顶群
- (BOOL)addToppingListWithGroupId:(NSString *)groupId;
// 删除置顶群
- (BOOL)removeToppingListWithGroupId:(NSString *)groupId;

/**
 *  @brief 添加|删除代理
 */
- (void)addDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id <XOContactDelegate>)delegate;

@end

@protocol XOContactDelegate <NSObject>

@optional
/**
 *  添加好友通知
 *
 *  @param users 好友列表（NSString*）
 */
- (void)xoOnAddFriends:(NSArray*)users;

/**
 *  删除好友通知
 *
 *  @param identifiers 用户id列表（NSString*）
 */
- (void)xoOnDelFriends:(NSArray*)identifiers;

/**
 *  好友资料更新通知
 *
 *  @param profiles 资料列表（TIMSNSChangeInfo *）
 */
- (void)xoOnFriendProfileUpdate:(NSArray<TIMSNSChangeInfo *> *)profiles;

/**
 *  好友申请通知
 *
 *  @param reqs 好友申请者id列表（TIMFriendPendencyInfo *）
 */
- (void)xoOnAddFriendReqs:(NSArray<TIMFriendPendencyInfo *> *)reqs;

@end











// 联系人数据库名
extern NSString * const ContactDBName;

// 定义语言类型
typedef NSString *XOTableName NS_EXTENSIBLE_STRING_ENUM;
// 联系人表名
extern XOTableName const ContactTableName;
// 联系人信息表名
extern XOTableName const ContactProfileTableName;
// 群列表名
extern XOTableName const GroupTableName;


@interface XOContactManager (Database)

/**
 *  @brief 创建数据库
 *  @return 创建结果  (-1: 表示创建失败  0: 表示创建成功  1: 表示已经存在，无需创建)
 */
- (int)initDataBase;

/**
 * @brief 创建表
 * @param name          表名
 * @param complection   回调  result:建表结果 (-1: 表示创建失败  0: 表示创建成功  1: 表示已经存在，无需创建)  error:建表失败原因
 */
- (void)initTableWith:(XOTableName)name handler:(void(^ _Nullable)(int result, NSError * _Nullable error))complection;

#pragma mark 查询
/**
 * @brief 查询联系人信息
 */
- (void)getContactProfile:(NSString *)identifier handler:(void(^ _Nullable)(TIMUserProfile * _Nullable profile))complection;

/**
 * @brief 查询所有的联系人
 */
- (void)getAllContactsList:(void(^ _Nullable)(NSArray <TIMFriend *> * _Nullable friendList))complection;

/**
 * @brief 查询群信息
 */
- (void)getGroupInfo:(NSString *)groupId handler:(void(^ _Nullable)(TIMGroupInfo * _Nullable groupInfo))complection;

/**
 * @brief 查询所有的群
 */
- (void)getAllGroupsList:(void(^ _Nullable)(NSArray <TIMGroupInfo *> * _Nullable groupList))complection;

#pragma mark 增加

// 插入联系人
- (void)insertContact:(TIMFriend * _Nonnull)friend handler:(void(^ _Nullable)(BOOL result))complection;

// 批量插入联系人
- (void)batchInsertContact:(NSArray <TIMFriend *>* _Nonnull)friendList handler:(void(^ _Nullable)(BOOL result))complection;

// 插入群
- (void)insertGroup:(TIMGroupInfo * _Nonnull)group handler:(void(^ _Nullable)(BOOL result))complection;

// 批量插入群
- (void)batchInsertGroup:(NSArray <TIMGroupInfo *> * _Nonnull)groupsList handler:(void(^ _Nullable)(BOOL result))complection;

#pragma mark 删除

// 清空联系人表和联系人信息表
- (void)clearContactsList:(void(^ _Nullable)(BOOL result))complection;

// 清空群表
- (void)clearGroupList:(void(^ _Nullable)(BOOL result))complection;

// 删除联系人
- (void)deleteContact:(TIMFriend * _Nonnull)friend handler:(void(^ _Nullable)(BOOL result))complection;

// 删除群
- (void)deleteGroup:(TIMGroupInfo * _Nonnull)group handler:(void(^ _Nullable)(BOOL result))complection;

#pragma mark 更新

// 更新联系人
- (void)updateContact:(TIMFriend *)friend handler:(void(^ _Nullable)(BOOL result))complection;

// 更新联系人信息
- (void)updateContactProfile:(TIMUserProfile *)profile handler:(void(^ _Nullable)(BOOL result))complection;

// 更新群
- (void)updateGroup:(TIMGroupInfo *)group handler:(void(^ _Nullable)(BOOL result))complection;

@end

NS_ASSUME_NONNULL_END
