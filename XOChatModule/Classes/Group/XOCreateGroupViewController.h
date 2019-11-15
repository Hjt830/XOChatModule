//
//  XOCreateGroupViewController.h
//  xxoogo
//
//  Created by 鼎一  on 2019/5/22.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import <XOBaseLib/XOBaseLib.h>
#import "XOChatModule.h"

typedef NS_ENUM(NSInteger, GroupMemberType) {
    GroupMemberType_Create  = 1001,  // 创建群
    GroupMemberType_Add     = 1002,  // 添加群成员
    GroupMemberType_Remove  = 1003,  // 剔除群成员
};


@class XOCreateGroupViewController;
@protocol XOCreateGroupDelegate <NSObject>

@optional
// 创建群成功回调
- (void)createGroup:(XOCreateGroupViewController *)groupViewController didSuccess:(NSDictionary *)groupInfo;

// 添加群成员回调
- (void)addGroupMember:(XOCreateGroupViewController *)groupViewController selectMember:(NSArray <NSDictionary *> *)selectMember;

// 剔除群成员回调
- (void)removeGroupMember:(XOCreateGroupViewController *)groupViewController selectMember:(NSArray <NSDictionary *> *)selectMember;

@end


@interface XOCreateGroupViewController : XOBaseViewController

@property (nonatomic, weak) id  <XOCreateGroupDelegate> delegate;

@property (nonatomic, assign) GroupMemberType       memberType;             // 默认是创建群

@property (nonatomic, strong) NSArray     <NSString *>* existMemberIds;     // 添加群成员时已经在群中的成员列表

@property (nonatomic, strong) NSArray     <NSDictionary *>* groupMembers;   // 剔除群成员时成员列表

@end






@interface GroupMemberInfoModel : NSObject

@property (nonatomic, copy) NSString    *picture;
@property (nonatomic, copy) NSString    *createTime; // = 1559285420000;
@property (nonatomic, copy) NSString    *groupId; // = 97b0747b76dc4e168b7faa8737d7290d;
@property (nonatomic, copy) NSString    *memId; // = fbf68e6aef09469ba20b8a4935de5002;
@property (nonatomic, copy) NSString    *realName; // = 13228282828;
@property (nonatomic, strong) NSNumber  *type; // = 0;

@property (nonatomic, copy) NSString *sortKey;  // 排序realname时使用的key

@end






@interface GroupMemberSelectCell : UITableViewCell

@end


@interface GroupMemberIconCell : UICollectionViewCell

@property (nonatomic, copy) NSString             *imageName;
@property (nonatomic, copy) NSString             *imageUrl;
@property (nonatomic, copy) UIImage              *avatar;

@end

