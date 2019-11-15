//
//  WXMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/4/22.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXMessageCell.h"

static float const kDefaultMargin = 8.0f;

@interface WXMessageCell ()

@property (nonatomic, strong) UIActivityIndicatorView   *sendingView;       // 消息发送中状态
@property (nonatomic, strong) UIImageView               *sendfailView;      // 消息发送失败状态

@property (nonatomic, strong) UITapGestureRecognizer        *avatarTap;       // 头像点击手势
@property (nonatomic, strong) UILongPressGestureRecognizer  *avaLongTap;      // 头像长按手势
@property (nonatomic, strong) UITapGestureRecognizer        *messageTap;      // 消息点击手势
@property (nonatomic, strong) UILongPressGestureRecognizer  *msgLongTap;      // 消息长按手势
@property (nonatomic, strong) UITapGestureRecognizer        *reSendTap;       // 重发消息手势

@end

@implementation WXMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.messageBackgroundImageView];
        [self.contentView addSubview:self.avatarImageView];
        [self.contentView addSubview:self.messageSendStatusImageView];
        
        [self.messageBackgroundImageView addGestureRecognizer:self.messageTap];
        [self.messageBackgroundImageView addGestureRecognizer:self.msgLongTap];
        [self.avatarImageView addGestureRecognizer:self.avatarTap];
        [self.avatarImageView addGestureRecognizer:self.avaLongTap];
        [self.sendfailView addGestureRecognizer:self.reSendTap];
    }
    
    return  self;
}

- (void)layoutSubviews
{
    /**
     *  聊天的具体界面，只要考虑这两种类型，自己的，别人的。
     */
    [super layoutSubviews];
    if ([_message isSelf]) {
        // 屏幕宽 - 10 - 头像宽
        CGPoint origin = CGPointMake(self.width - 10 - self.avatarImageView.width, self.height - MsgCellIconMargin - self.avatarImageView.height);
        [self.avatarImageView setOrigin:origin];
        [self.messageSendStatusImageView setHidden:NO];
    }
    else {
        [self.avatarImageView setOrigin:CGPointMake(10, MsgCellIconMargin)];
        [self.messageSendStatusImageView setHidden:YES];
    }
}

- (void)setMessage:(TIMMessage *)message
{
    _message = message;
    
    if (_message.isSelf) {
        [self.avatarImageView setHidden:NO];
        [self.messageBackgroundImageView setHidden:NO];
        
        TIMUserProfile *profile = [[TIMManager sharedInstance].friendshipManager querySelfProfile];
        if (profile) {
            [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
        } else {
            [[TIMManager sharedInstance].friendshipManager getSelfProfile:^(TIMUserProfile *profile) {
                [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:profile.faceURL] placeholderImage:[UIImage imageNamed:@"default_avatar"]];
            } fail:^(int code, NSString *msg) {
                NSLog(@"获取个人头像失败 ------------ code: %d  msg: %@", code, msg);
            }];
        }
        
        /**
         *  UIImageResizingModeStretch：拉伸模式，通过拉伸UIEdgeInsets指定的矩形区域来填充图片
         UIImageResizingModeTile：平铺模式，通过重复显示UIEdgeInsets指定的矩形区域来填充图片
         比如下面方法中的拉伸区域：UIEdgeInsetsMake(28, 20, 15, 20)
         */
        UIEdgeInsets senderInset = UIEdgeInsetsMake(kDefaultMargin/2, kDefaultMargin/2, kDefaultMargin/2, kDefaultMargin + 1);
        self.messageBackgroundImageView.image = [[[UIImage xo_imageNamedFromChatBundle:@"message_sender_background_normal"] XO_imageWithTintColor:AppTinColor] resizableImageWithCapInsets:senderInset resizingMode:UIImageResizingModeStretch];
        [self.messageSendStatusImageView setHidden:NO];
        
        if (TIM_MSG_STATUS_SEND_FAIL == message.status) {
            [self sendFail];
        } else if (TIM_MSG_STATUS_SENDING == message.status) {
            [self sending];
        } else if (TIM_MSG_STATUS_SEND_SUCC == message.status) {
            [self sendSuccess];
        }
    }
    else {
        [self.avatarImageView setHidden:NO];
        TIMUserProfile *profile = [[TIMManager sharedInstance].friendshipManager queryUserProfile:message.sender];
        if (profile) {
            [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
        } else {
            [[TIMManager sharedInstance].friendshipManager getUsersProfile:@[message.sender] forceUpdate:YES succ:^(NSArray<TIMUserProfile *> *profiles) {
                if (profiles.count > 0) {
                    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
                }
            } fail:^(int code, NSString *msg) {
                NSLog(@"获取个人头像失败 ------------ code: %d  msg: %@", code, msg);
            }];
        }
        
        UIEdgeInsets receiverInset = UIEdgeInsetsMake(kDefaultMargin/2, kDefaultMargin + 2, kDefaultMargin/2, kDefaultMargin/2 + 1);
        [self.messageBackgroundImageView setHidden:NO];
        [self.messageBackgroundImageView setImage:[[[UIImage xo_imageNamedFromChatBundle:@"message_receiver_background_normal"] XO_imageWithTintColor:[UIColor whiteColor]] resizableImageWithCapInsets:receiverInset resizingMode:UIImageResizingModeStretch]];
    }
}

/** @brief 更新进度  由子类实现
 *  @param effect  NO:表示上传或者下载失败  YES:表示上传中或者下载中,此时进度才有意义
 */
- (void)updateProgress:(float)progress effect:(BOOL)effect {}

- (void)sending
{
    if (_message.isSelf) {
        if (!self.sendingView.isAnimating) {
            [self.sendingView startAnimating];
        }
        [self.sendingView setHidden:NO];
        [self.sendfailView setHidden:YES];
        [self.messageSendStatusImageView bringSubviewToFront:self.sendingView];
        [self.messageSendStatusImageView setHidden:NO];
    }
    else {
        [self.messageSendStatusImageView setHidden:YES];
    }
}

- (void)sendSuccess
{
    if (_message.isSelf) {
        if (self.sendingView.isAnimating) {
            [self.sendingView stopAnimating];
        }
        [self.sendingView setHidden:YES];
        [self.sendfailView setHidden:YES];
        [self.messageSendStatusImageView setHidden:NO];
    }
    else {
        [self.messageSendStatusImageView setHidden:YES];
    }
}

- (void)sendFail
{
    if (_message.isSelf) {
        if (self.sendingView.isAnimating) {
            [self.sendingView stopAnimating];
        }
        [self.sendingView setHidden:YES];
        [self.sendfailView setHidden:NO];
        [self.messageSendStatusImageView bringSubviewToFront:self.sendfailView];
        [self.messageSendStatusImageView setHidden:NO];
    }
    else {
        [self.messageSendStatusImageView setHidden:YES];
    }
}

/**
 * avatarImageView 头像
 */
- (UIImageView *)avatarImageView
{
    if (_avatarImageView == nil) {
        float imageWidth = 40;
        CGRect bounds = CGRectMake(0, 0, imageWidth, imageWidth);
        _avatarImageView = [[UIImageView alloc] initWithFrame:bounds];
        [_avatarImageView setHidden:YES];
        [_avatarImageView setUserInteractionEnabled:YES];
        [_avatarImageView setImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:bounds.size];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
        maskLayer.frame = bounds;
        maskLayer.path = maskPath.CGPath;
        _avatarImageView.layer.mask = maskLayer;
    }
    return _avatarImageView;
}

/**
 *  聊天背景图
 */
- (UIImageView *) messageBackgroundImageView
{
    if (_messageBackgroundImageView == nil) {
        _messageBackgroundImageView = [[UIImageView alloc] init];
        [_messageBackgroundImageView setHidden:YES];
        [_messageBackgroundImageView setUserInteractionEnabled:YES];
    }
    return _messageBackgroundImageView;
}

- (UIView *)messageSendStatusImageView
{
    if (_messageSendStatusImageView == nil) {
        _messageSendStatusImageView = [[UIView alloc] init];
        _messageSendStatusImageView.bounds = CGRectMake(0, 0, self.sendingView.width, self.sendingView.height);
        [_messageSendStatusImageView addSubview:self.sendfailView];
        [_messageSendStatusImageView addSubview:self.sendingView];
    }
    return _messageSendStatusImageView;
}

- (UIActivityIndicatorView *)sendingView
{
    if (_sendingView == nil) {
        _sendingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _sendingView;
}

- (UIImageView *)sendfailView
{
    if (_sendfailView == nil) {
        _sendfailView = [[UIImageView alloc] initWithImage:[UIImage xo_imageNamedFromChatBundle:@"message_sendFail"]];
        _sendfailView.size = self.sendingView.size;
        [_sendfailView setUserInteractionEnabled:YES];
    }
    return _sendfailView;
}

- (CAShapeLayer *)progressHud
{
    if (!_progressHud) {
        _progressHud = [CAShapeLayer layer];
        _progressHud.fillColor  = RGBA(210, 210, 210, 0.5).CGColor;
        _progressHud.fillRule   = kCAFillRuleEvenOdd;  //重点， 填充规则
        _progressHud.anchorPoint = CGPointMake(0.5, 0.5);
    }
    return _progressHud;
}

- (UITapGestureRecognizer *)avatarTap
{
    if (!_avatarTap) {
        _avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAvatar:)];
    }
    return _avatarTap;
}

- (UILongPressGestureRecognizer *)avaLongTap
{
    if (!_avaLongTap) {
        _avaLongTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAvatar:)];
    }
    return _avaLongTap;
}

- (UITapGestureRecognizer *)messageTap
{
    if (!_messageTap) {
        _messageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapMessage:)];
    }
    return _messageTap;
}

- (UILongPressGestureRecognizer *)msgLongTap
{
    if (!_msgLongTap) {
        _msgLongTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressMessage:)];
    }
    return _msgLongTap;
}

- (UITapGestureRecognizer *)reSendTap
{
    if (!_reSendTap) {
        _reSendTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapReSendMsg:)];
    }
    return _reSendTap;
}

- (void)tapAvatar:(UITapGestureRecognizer *)tap
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageCellDidTapAvatar:message:)]) {
        [self.delegate messageCellDidTapAvatar:self message:self.message];
    }
}
- (void)longPressAvatar:(UILongPressGestureRecognizer *)tap
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageCellLongPressAvatar:message:)]) {
        [self.delegate messageCellLongPressAvatar:self message:self.message];
    }
}
- (void)tapMessage:(UITapGestureRecognizer *)tap
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageCellDidTapMessage:message:)]) {
        [self.delegate messageCellDidTapMessage:self message:self.message];
    }
}
- (void)longPressMessage:(UILongPressGestureRecognizer *)tap
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageCellLongPressMessage:message:)]) {
        [self.delegate messageCellLongPressMessage:self message:self.message];
    }
}
- (void)tapReSendMsg:(UITapGestureRecognizer *)tap
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageCellDidTapResendMessage:message:)]) {
        [self.delegate messageCellDidTapResendMessage:self message:self.message];
    }
}

//改变与图片的颜色
- (UIImage *)image:(UIImage *)image ChangeColor:(UIColor*)color
{
    //获取画布
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    //画笔沾取颜色
    [color setFill];
    
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    //绘制一次
    [image drawInRect:bounds blendMode:kCGBlendModeOverlay alpha:1.0f];
    //再绘制一次
    [image drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    //获取图片
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end







@implementation WXMessageHeaderFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        self.textLabel.font = [UIFont systemFontOfSize:14];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.textLabel.font = [UIFont systemFontOfSize:12.0];
    self.textLabel.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.textLabel.clipsToBounds = YES;
    self.textLabel.layer.cornerRadius = 5.0f;
    [self.textLabel setCenter:CGPointMake(self.width/2.0, self.height/2.0)];
    
    [self.backgroundView removeFromSuperview];
    self.contentView.backgroundColor = [UIColor clearColor];
    [[self subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.backgroundColor = [UIColor clearColor];
    }];
}


@end
