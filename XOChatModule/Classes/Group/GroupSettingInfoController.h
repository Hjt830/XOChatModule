//
//  GroupSettingInfoController.h
//  xxoogo
//
//  Created by 黄金柱 on 2019/5/24.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImSDK/ImSDK.h>
#import <XOBaseLib/XOBaseLib.h>

NS_ASSUME_NONNULL_BEGIN

@interface GroupSettingInfoController : XOBaseViewController

@property (nonatomic, strong) TIMGroupInfo          *groupInfo;
@property (nonatomic, copy) NSString                *groupId;

@end



@interface GroupMemberSwitchCell : UITableViewCell

@property (nonatomic, assign) BOOL           isLocked;          // 开关是否需要锁定
@property (nonatomic, copy) void(^switchClick)(BOOL on);        // 切换开关后的回调

- (void)setOn:(BOOL)on;

@end


@interface GroupMemberSettingTailCell : UITableViewCell

@property (nonatomic, copy) NSString             *title;


@end




@interface GroupMemberSettingIconCell : UICollectionViewCell

@property (nonatomic, strong) TIMGroupMemberInfo *memberInfo;

@property (nonatomic, assign) BOOL               showAdd; // 显示+
@property (nonatomic, assign) BOOL               showDel; // 显示-

@property (nonatomic, copy) void(^AddMemberHandler)(void);  // 点击加号的回调
@property (nonatomic, copy) void(^DelMemberHandler)(void);  // 点击减号的回调


@end

NS_ASSUME_NONNULL_END
