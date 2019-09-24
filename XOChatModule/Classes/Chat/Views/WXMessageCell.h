//
//  WXMessageCell.h
//  WXMainProject
//
//  Created by 乐派 on 2019/4/22.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImSDK/ImSDK.h>
#import "XOChatModule.h"

NS_ASSUME_NONNULL_BEGIN

@class WXMessageCell;
@protocol WXMessageCellDelegate <NSObject>

@optional
// 点击了用户头像
- (void)messageCellDidTapAvatar:(WXMessageCell *)cell message:(TIMMessage *)message;
// 长按了用户头像
- (void)messageCellLongPressAvatar:(WXMessageCell *)cell message:(TIMMessage *)message;
// 点击了消息
- (void)messageCellDidTapMessage:(WXMessageCell *)cell message:(TIMMessage *)message;
// 长按了消息
- (void)messageCellLongPressMessage:(WXMessageCell *)cell message:(TIMMessage *)message;
// 点击了重发消息
- (void)messageCellDidTapResendMessage:(WXMessageCell *)cell message:(TIMMessage *)message;

@end






@interface WXMessageCell : UITableViewCell

@property (nonatomic, weak)   id   <WXMessageCellDelegate> delegate;
@property (nonatomic, strong) TIMMessage * message;

/**
 *  其他的cell 继承这个cell，这个cell中只有头像是共有的，就只写头像，其他的就在各自cell中去写。
 */
@property (nonatomic, strong) UIImageView   *avatarImageView;                 // 头像
@property (nonatomic, strong) UIImageView   *messageBackgroundImageView;      // 消息背景
@property (nonatomic, strong) UIView        *messageSendStatusImageView;      // 消息发送状态
@property (nonatomic, strong) CAShapeLayer  *progressHud;                     // 文件上传或者下载状态


- (void)sending;

- (void)sendSuccess;

- (void)sendFail;

/** @brief 更新进度  由子类实现
 *  @param effect  NO:表示上传或者下载失败  YES:表示上传中或者下载中,此时进度才有意义
 */
- (void)updateProgress:(float)progress effect:(BOOL)effect;

//改变与图片的颜色
- (UIImage *)image:(UIImage *)image ChangeColor:(UIColor*)color;

@end


@interface WXMessageHeaderFooterView : UITableViewHeaderFooterView

@property (nonatomic, copy) NSString * title;

@end

NS_ASSUME_NONNULL_END
