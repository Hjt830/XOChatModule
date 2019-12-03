//
//  XOGroupSelectedController.h
//  xxoogo
//
//  Created by 鼎一  on 2019/5/22.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import <XOBaseLib/XOBaseLib.h>
#import "XOChatModule.h"
#import <ImSDK/ImSDK.h>

// 群成员最大人数
static int const MaxGroupMemberCount = 500;
// 最大转发数
static int const MaxMsgForwardCount = 9;

typedef NS_ENUM(NSInteger, SelectMemberType) {
    SelectMemberType_Create  = 1001,  // 创建群
    SelectMemberType_Add     = 1002,  // 添加群成员
    SelectMemberType_Remove  = 1003,  // 剔除群成员
    SelectMemberType_Forward = 1004,  // 消息转发
};


@class XOGroupSelectedController;
@protocol XOGroupSelectedDelegate <NSObject>

@optional

// 选中成员的回调
- (void)groupSelectController:(XOGroupSelectedController *)selectController selectMemberType:(SelectMemberType)memberType didSelectMember:(NSArray <TIMUserProfile *> *)selectMember;
// 消息转发
- (void)groupSelectController:(XOGroupSelectedController *)selectController forwardMessage:(TIMMessage *)message toReceivers:(NSArray *)receivers;

@end


@interface XOGroupSelectedController : XOBaseViewController

@property (nonatomic, weak) id  <XOGroupSelectedDelegate> delegate;

@property (nonatomic, assign) SelectMemberType             memberType;             // 默认是创建群

@property (nonatomic, strong) TIMGroupInfo                *groupInfo;              // 群信息
@property (nonatomic, strong) NSArray     <TIMUserProfile *>* existGroupMembers;   // 添加|剔除 时的群成员列表

@property (nonatomic, strong) TIMMessage                  *forwardMsg;             // 消息转发时的消息

@end







@interface  MemberTableViewCell: UITableViewCell

@property (nonatomic, strong) TIMFriend             *user;
@property (nonatomic, strong) TIMUserProfile        *profile;

@property (nonatomic, assign) BOOL          isLock; // 是否锁定, 默认不锁定

@property (nonatomic, copy) void(^addblock)(void);


@end




@interface GroupMemberIconCell : UICollectionViewCell

@property (nonatomic, copy) NSString             *imageName;
@property (nonatomic, copy) NSString             *imageUrl;
@property (nonatomic, copy) UIImage              *avatar;

@end

