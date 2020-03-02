//
//  LCContactListViewController.h
//  XOChatModule
//
//  Created by kenter on 2019/10/11.
//

#import <XOBaseLib/XOBaseLib.h>

NS_ASSUME_NONNULL_BEGIN

@interface LCContactListViewController : XOBaseViewController

@end






@interface XOContactListCell : UITableViewCell

@property (nonatomic, strong) XOContact         *contact;
@property (nonatomic, strong) EMGroup           *group;

// 通用设置发生改变
- (void)refreshGenralSetting;

@end


NS_ASSUME_NONNULL_END
