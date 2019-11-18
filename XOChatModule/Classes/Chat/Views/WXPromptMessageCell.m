//
//  WXPromptMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/5/5.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXPromptMessageCell.h"
#import "XOChatModule.h"
#import "TIMElem+XOExtension.h"

@interface WXPromptMessageCell ()

@property (nonatomic, strong) UILabel * titleLabel;

@end

@implementation WXPromptMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.titleLabel];
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    float MaxWidth = self.width - 30;
    CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(MaxWidth, MAXFLOAT)];
    self.titleLabel.frame = CGRectMake(15, 10, MaxWidth, size.height);
}

- (void)setMessage:(TIMMessage *)message
{
    _message = message;
    
    TIMElem *elem = [message getElem:0];
    NSString *text = [elem getTextFromMessage];
    if ([text isKindOfClass:[NSAttributedString class]]) {
        self.titleLabel.attributedText = (NSAttributedString *)text;
    } else {
        self.titleLabel.text = text;
    }
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = XOSystemFont(13.0);
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = RGBA(109, 109, 114, 1.0);
    }
    return _titleLabel;
}


@end
