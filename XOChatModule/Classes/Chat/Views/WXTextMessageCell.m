//
//  WXTextMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/4/22.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXTextMessageCell.h"
#import "ZXChatHelper.h"

@interface WXTextMessageCell ()

@property (nonatomic, strong) UILabel *messageTextLabel;

@end

@implementation WXTextMessageCell

- (WXTextMessageCell *) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.messageTextLabel];
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    if (self.message.isSelf) {
        float y = CGRectGetMaxY(self.avatarImageView.frame) - self.messageTextLabel.height - 9;
        float x = self.avatarImageView.x - 27 - self.messageTextLabel.width;
        [self.messageTextLabel setOrigin:CGPointMake(x, y)];
        
        float h = MAX(self.messageTextLabel.height + 18, self.avatarImageView.height);
        x -= 18;
        y = CGRectGetMaxY(self.avatarImageView.frame) - h;
        [self.messageBackgroundImageView setFrame:CGRectMake(x, y, self.messageTextLabel.width + 40, h)];
        
        if (self.message.isSelf) {
            // 发送状态图标
            float statusWid = self.messageSendStatusImageView.height;
            [self.messageSendStatusImageView setOrigin:CGPointMake(self.messageBackgroundImageView.x - 10 - statusWid, (self.height - statusWid)/2.0)];
        }
    }
    else {
        float y = self.avatarImageView.y + 11;
        float x = self.avatarImageView.x + self.avatarImageView.width + 23;
        [self.messageTextLabel setOrigin:CGPointMake(x, y)];
        
        x -= 18;
        y = self.avatarImageView.y;
        float h = MAX(self.messageTextLabel.height + 18, self.avatarImageView.height);
        [self.messageBackgroundImageView setFrame:CGRectMake(x, y, self.messageTextLabel.width + 40, h)];
    }
}

/** @brief 更新进度  由子类实现
 *  @param effect  NO:表示上传或者下载失败  YES:表示上传中或者下载中,此时进度才有意义
 */
- (void)updateProgress:(float)progress effect:(BOOL)effect {}

#pragma mark - Getter and Setter
- (void)setMessage:(TIMMessage *)message
{
    [super setMessage:message];
    
    NSString *messageStr = @"";
    TIMElem *elem = [message getElem:0];
    if ([elem isKindOfClass:[TIMTextElem class]]) messageStr = ((TIMTextElem *)elem).text;
    else {
        NSData *data = ((TIMCustomElem *)elem).data;
        messageStr = (data.length > 0) ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
    }
    
    NSMutableAttributedString *text = [ZXChatHelper formatMessageString:messageStr].mutableCopy;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 3; // 调整行间距
    [text addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];
    self.messageTextLabel.attributedText = text;
    
    CGSize size = [self.messageTextLabel sizeThatFits:CGSizeMake(KWIDTH * 0.58, MAXFLOAT)];
    self.messageTextLabel.size = size;
    
    if (message.isSelf) {
        self.messageTextLabel.textColor = [UIColor whiteColor];
    } else {
        self.messageTextLabel.textColor = [UIColor darkTextColor];
    }
}

- (UILabel *)messageTextLabel
{
    if (_messageTextLabel == nil) {
        _messageTextLabel = [[UILabel alloc] init];
        [_messageTextLabel setFont:[UIFont systemFontOfSize:16.0f]];
        [_messageTextLabel setNumberOfLines:0];
    }
    return _messageTextLabel;
}

@end
