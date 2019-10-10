//
//  WXLocationMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/4/23.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXLocationMessageCell.h"

@interface WXLocationMessageCell ()

@property (nonatomic ,strong) UIImageView   *addressPoi;
@property (nonatomic ,strong) UILabel       *addressLabel;

@end

@implementation WXLocationMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self.contentView addSubview:self.addressPoi];
        [self.contentView addSubview:self.addressLabel];
    }
    return self;
}

- (void)setMessage:(TIMMessage *)message
{
    [super setMessage:message];
    
    TIMLocationElem *locationElem = (TIMLocationElem *)[message getElem:0];
    // 设置文字
    self.addressLabel.text = locationElem.desc;
    
    if (message.isSelf) {
        _addressLabel.textColor = [UIColor whiteColor];
        _addressPoi.image = [[UIImage xo_imageNamedFromChatBundle:@"message_location_poi"] imageWithTintColor:[UIColor whiteColor]];
    }
    else {
        _addressLabel.textColor = [UIColor darkTextColor];
        _addressPoi.image = [[UIImage xo_imageNamedFromChatBundle:@"message_location_poi"] imageWithTintColor:[UIColor darkTextColor]];
    }
    CGFloat maxWidth = self.contentView.width - (10 + self.avatarImageView.width + 5) * 2 - 40 - 23;
    CGSize size = [self.addressLabel sizeThatFits:CGSizeMake(maxWidth, MAXFLOAT)];
    self.addressLabel.size = size;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    float h = MAX(self.addressLabel.height + 18, self.avatarImageView.height);
    if (self.message.isSelf) {
        float x = self.avatarImageView.x - 27 - self.addressLabel.width;
        float y = MsgCellIconMargin;
        float sendY = y + 20;
        [self.addressLabel setOrigin:CGPointMake(x, y + 9)];
        x = (x - 5 - 18);
        [self.addressPoi setOrigin:CGPointMake(x, y + (40 - 18)/2.0)];
        x -= 18;
        
        [self.messageBackgroundImageView setFrame:CGRectMake(x, CGRectGetMaxY(self.avatarImageView.frame) - h, self.addressLabel.width + 40 + 23, h)];
        [self.messageSendStatusImageView setCenter:CGPointMake(x - 20, sendY)];
        [self.messageSendStatusImageView setHidden:NO];
    }
    else {
        float x = self.avatarImageView.x + self.avatarImageView.width + 23;
        float y = self.avatarImageView.y;
        float sendY = y + 20;
        [self.addressLabel setOrigin:CGPointMake(x, y + 9)];
        [self.addressPoi setOrigin:CGPointMake(x + self.addressLabel.width + 5, y + 9 + (40 - 18)/2.0)];
        
        x -= 18;
        [self.messageBackgroundImageView setFrame:CGRectMake(x, y, self.addressLabel.width + 40 + 23, h)];
        [self.messageSendStatusImageView setCenter:CGPointMake(self.messageBackgroundImageView.right + 20, sendY)];
    }
    [self.addressPoi setSize:CGSizeMake(18, 18)];
}

- (UILabel *)addressLabel
{
    if (!_addressLabel) {
        _addressLabel = [[UILabel alloc] init];
        _addressLabel.font = [UIFont systemFontOfSize:16];
        _addressLabel.clipsToBounds = YES;
        _addressLabel.layer.cornerRadius = 5.0f;
        _addressLabel.numberOfLines = 0;
        _addressLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _addressLabel;
}

- (UIImageView *)addressPoi
{
    if (!_addressPoi) {
        _addressPoi = [[UIImageView alloc] init];
        [_addressPoi setContentMode:UIViewContentModeScaleAspectFit];
    }
    return _addressPoi;
}

/** @brief 更新进度  由子类实现
 *  @param effect  NO:表示上传或者下载失败  YES:表示上传中或者下载中,此时进度才有意义
 */
- (void)updateProgress:(float)progress effect:(BOOL)effect {}


@end
