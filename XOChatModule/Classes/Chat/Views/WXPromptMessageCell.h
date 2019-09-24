//
//  WXPromptMessageCell.h
//  WXMainProject
//
//  Created by 乐派 on 2019/5/5.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface WXPromptMessageCell : UITableViewCell

@property (nonatomic, strong) TIMMessage * message;

@end

NS_ASSUME_NONNULL_END
