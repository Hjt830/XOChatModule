//
//  XOContactListViewController.h
//  XOChatModule
//
//  Created by kenter on 2019/10/11.
//

#import <XOBaseLib/XOBaseLib.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface XOContactListViewController : XOBaseViewController

@end






@interface XOContactListCell : UITableViewCell

@property (nonatomic, strong) TIMFriend         *contact;
@property (nonatomic, strong) TIMGroupInfo      *group;

// 通用设置发生改变
- (void)refreshGenralSetting;

@end


NS_ASSUME_NONNULL_END
