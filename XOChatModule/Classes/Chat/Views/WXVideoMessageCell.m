//
//  WXVideoMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/4/23.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXVideoMessageCell.h"

@interface WXVideoMessageCell ()

@property (nonatomic, strong) UIImageView   *playBtn;   // 播放按钮
@property (nonatomic, strong) UILabel       *timeLabel; // 时长文本

@end

@implementation WXVideoMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.messageImageView addSubview:self.playBtn];
        [self.messageImageView addSubview:self.timeLabel];
    }
    return self;
}

- (void)setMessage:(TIMMessage *)message
{
    [super setMessage:message];
    
    TIMVideoElem *videoElem = (TIMVideoElem *)[message getElem:0];
    int duration = videoElem.video.duration;
    int min = duration / 60;
    int sec = duration % 60;
    NSString *time = [NSString stringWithFormat:@"%.2d:%.2d", min, sec];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[UIColor lightTextColor]];
    [shadow setShadowOffset:CGSizeMake(-0.3, 0.3)];
    
    NSMutableAttributedString *timeAttr = [[NSMutableAttributedString alloc] initWithString:time];
    [timeAttr addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, timeAttr.length)];
    [timeAttr addAttribute:NSShadowAttributeName value:shadow range:NSMakeRange(0, timeAttr.length)];
    self.timeLabel.attributedText = timeAttr;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.playBtn.frame = CGRectMake((self.messageImageView.width - 50)/2, (self.messageImageView.height-50)/2, 50, 50);
    self.timeLabel.frame = CGRectMake(0, self.messageImageView.height - 20, self.messageImageView.width, 16);
}

- (UIImageView *)playBtn
{
    if (!_playBtn) {
        _playBtn = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"message_playVideo"]];
        _playBtn.userInteractionEnabled = YES;
    }
    return _playBtn;
}

- (UILabel *)timeLabel
{
    if (_timeLabel == nil) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.textColor = [UIColor whiteColor];
        [_timeLabel setFont:[UIFont boldSystemFontOfSize:12]];
        [_timeLabel setNumberOfLines:1];
    }
    return _timeLabel;
}

@end
