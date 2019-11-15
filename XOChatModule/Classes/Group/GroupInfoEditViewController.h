//
//  GroupInfoEditViewController.h
//  xxoogo
//
//  Created by 黄金柱 on 2019/5/28.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImSDK/ImSDK.h>
#import <XOBaseLib/XOBaseLib.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GroupEditType) {
    GroupEditTypeGroupName = 100,
    GroupEditTypeNotification = 101,
};

@class GroupInfoEditViewController;
@protocol GroupInfoEditViewControllerProtocol <NSObject>

- (void)groupInfoEdit:(GroupInfoEditViewController *)editVC didEditSuccess:(NSString *)modifyText editType:(GroupEditType)type;

@end

@interface GroupInfoEditViewController : XOBaseViewController

@property (nonatomic, weak) id       <GroupInfoEditViewControllerProtocol>      delegate;

@property (nonatomic, copy) NSString                    *groupId;
@property (nonatomic, assign) GroupEditType             editType;
@property (nonatomic, strong) TIMGroupInfo              *groupInfo;
@property (nonatomic, assign) BOOL                      isOwner; // 是否是群主

@end

NS_ASSUME_NONNULL_END
