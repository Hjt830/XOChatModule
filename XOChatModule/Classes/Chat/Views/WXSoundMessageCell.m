//
//  WXSoundMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/4/23.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXSoundMessageCell.h"

@interface WXSoundMessageCell ()

@property(nonatomic,strong) UIImageView     *audioAniImageView;
@property(nonatomic,strong) UILabel         *audioTimeLabel;

@end

@implementation WXSoundMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.messageBackgroundImageView addSubview:self.audioAniImageView];
        [self.messageBackgroundImageView addSubview:self.audioTimeLabel];
    }
    return self;
}


- (void)setMessage:(TIMMessage *)message
{
    [super setMessage:message];
    
    if (message.isSelf) {
        self.audioAniImageView.image = [UIImage xo_imageNamedFromChatBundle:@"message_voice_sender_normal"];
        self.audioAniImageView.animationImages = @[[UIImage xo_imageNamedFromChatBundle:@"message_voice_sender_playing_1"],
                                                   [UIImage xo_imageNamedFromChatBundle:@"message_voice_sender_playing_2"],
                                                   [UIImage xo_imageNamedFromChatBundle:@"message_voice_sender_playing_3"],
                                                   [UIImage xo_imageNamedFromChatBundle:@"message_voice_sender_normal"]];
    }
    else {
        self.audioAniImageView.image = [UIImage xo_imageNamedFromChatBundle:@"message_voice_receiver_normal"];
        self.audioAniImageView.animationImages = @[[UIImage xo_imageNamedFromChatBundle:@"message_voice_receiver_playing_1"],
                                                   [UIImage xo_imageNamedFromChatBundle:@"message_voice_receiver_playing_2"],
                                                   [UIImage xo_imageNamedFromChatBundle:@"message_voice_receiver_playing_3"],
                                                   [UIImage xo_imageNamedFromChatBundle:@"message_voice_receiver_normal"]];
    }
    TIMSoundElem *soundElem = (TIMSoundElem *)[message getElem:0];
    self.audioTimeLabel.text = [NSString stringWithFormat:@"%d\"", soundElem.second];
    [self.audioTimeLabel sizeToFit];
}

- (void)setPlayState:(LGAudioPlayerState)playState
{
    if (_playState != playState) _playState = playState;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self->_playState == LGAudioPlayerStatePlaying) { // 播放状态
            [self->_audioAniImageView startAnimating];
        }
        else { // 停止动画
            [self->_audioAniImageView stopAnimating];
        }
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    TIMSoundElem *soundElem = (TIMSoundElem *)[self.message getElem:0];
    int duration = soundElem.second;
    float width = (100 + duration * 5) < KWIDTH * 0.6 ? 100 + duration * 5 : KWIDTH * 0.6;
    float height = self.avatarImageView.height + 6;
    float y = self.avatarImageView.y - 3;
    float x = self.avatarImageView.x + (self.message.isSelf ? - width - 5 : self.avatarImageView.width + 5);
    self.messageBackgroundImageView.frame = CGRectMake(x, y, width, height);
    self.messageSendStatusImageView.center = CGPointMake(self.message.isSelf ? x - 20 : x + 20, y + height/2.0);
    
    self.audioAniImageView.size = CGSizeMake(24, 24);
    self.audioAniImageView.origin = CGPointMake(self.message.isSelf ? width - 44 : 20, (height - 24.0)/2.0);
    
    self.audioTimeLabel.height = 20;
    self.audioTimeLabel.origin = CGPointMake(self.message.isSelf ? (width - 49 - self.audioTimeLabel.width) : 49, (height - 20.0)/2.0);
}

- (UIImageView *)audioAniImageView
{
    if (!_audioAniImageView) {
        _audioAniImageView = [[UIImageView alloc] init];
        _audioAniImageView.animationDuration = 0.75;    //设置动画时间
        _audioAniImageView.animationRepeatCount = 0;    //设置动画次数 0 表示无限
        _audioAniImageView.userInteractionEnabled = YES;
    }
    return _audioAniImageView;
}

- (UILabel *)audioTimeLabel
{
    if (!_audioTimeLabel) {
        _audioTimeLabel = [[UILabel alloc] init];
        _audioTimeLabel.font = [UIFont systemFontOfSize:15];
        _audioTimeLabel.textColor = [UIColor darkTextColor];
        _audioTimeLabel.userInteractionEnabled = YES;
    }
    return _audioTimeLabel;
}

/** @brief 更新进度  由子类实现
 *  @param effect  NO:表示上传或者下载失败  YES:表示上传中或者下载中,此时进度才有意义
 */
- (void)updateProgress:(float)progress effect:(BOOL)effect {}

@end
