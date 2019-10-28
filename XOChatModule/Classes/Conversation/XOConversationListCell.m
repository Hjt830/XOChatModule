//
//  XOConversationListCell.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/5.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOConversationListCell.h"
#import "NSBundle+ChatModule.h"
#import "UIImage+XOChatBundle.h"
#import <XOBaseLib/XOBaseLib.h>

@interface XOConversationListCell ()

@property (nonatomic, strong) UIImageView   *iconImageView;
@property (nonatomic, strong) UILabel       *nameLabel;
@property (nonatomic, strong) UILabel       *timeLabel;
@property (nonatomic, strong) UILabel       *messageLabel;
@property (nonatomic, strong) UILabel       *unreadLabel;

@property (nonatomic, strong) NSMutableArray *atLists;      //艾特列表

@end

@implementation XOConversationListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.shouldTopShow = NO;
        self.atLists = [NSMutableArray array];
        
        [self setupView];
    }
    return self;
}

#pragma mark - private actions

- (void)setupView
{
    self.backgroundColor = [UIColor whiteColor];
    
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.layer.cornerRadius = 5;
    _iconImageView.clipsToBounds = YES;
    _iconImageView.backgroundColor = RGBA(221, 222, 224, 1);
    
    _nameLabel = [UILabel new];
    CGFloat fontSize = [XOSettingManager defaultManager].fontSize;
    _nameLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    _nameLabel.textColor = [UIColor blackColor];
    
    _timeLabel = [UILabel new];
    _timeLabel.font = [UIFont systemFontOfSize:12];
    _timeLabel.textColor = [UIColor lightGrayColor];
    
    _messageLabel = [[UILabel alloc] init];
    _messageLabel.font = [UIFont systemFontOfSize:15];
    _messageLabel.textColor = [UIColor lightGrayColor];
    _messageLabel.textAlignment = NSTextAlignmentLeft;
    
    _unreadLabel = [UILabel new];
    _unreadLabel.backgroundColor = [UIColor redColor];
    _unreadLabel.font = [UIFont systemFontOfSize:12];
    _unreadLabel.textColor = [UIColor whiteColor];
    _unreadLabel.textAlignment = NSTextAlignmentCenter;
    _unreadLabel.layer.cornerRadius = 9.0;
    _unreadLabel.clipsToBounds = YES;
    
    [self.contentView addSubview:_iconImageView];
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_timeLabel];
    [self.contentView addSubview:_messageLabel];
    [self.contentView addSubview:_unreadLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat margin = 10.0;
    CGFloat maxWid = self.contentView.frame.size.width;
    CGFloat maxHei = self.contentView.frame.size.height;
    
    self.iconImageView.frame = CGRectMake(margin * 2.0, margin, maxHei - margin * 2, maxHei - margin * 2);
    
    CGFloat timeWid = [self.timeLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 16.0) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: self.timeLabel.font} context:nil].size.width + 5.0;
    CGFloat timeLeft = maxWid - margin - timeWid;
    self.timeLabel.frame = CGRectMake(timeLeft, margin + 5.0, timeWid, 16.0);
    
    CGFloat nameLeft = CGRectGetMaxX(self.iconImageView.frame) + margin * 2;
    CGFloat nameWid = timeLeft - nameLeft - margin;
    self.nameLabel.frame = CGRectMake(nameLeft, margin, nameWid, 24.0);
    
    CGFloat msgLeft = CGRectGetMaxX(self.iconImageView.frame) + margin * 2;
    CGFloat msgTop = CGRectGetMaxY(self.iconImageView.frame) - 20.0;
    CGFloat msgWid = maxWid - margin - msgLeft;
    self.messageLabel.frame = CGRectMake(msgLeft, msgTop, msgWid, 20.0);
    
    CGFloat unredLeft = CGRectGetMaxX(self.iconImageView.frame) - 9.0;
    CGFloat unredTop  = CGRectGetMinY(self.iconImageView.frame) - 8.0;
    self.unreadLabel.frame = CGRectMake(unredLeft, unredTop, 18.0, 18.0);
    
    if (self.shouldTopShow) {
        self.contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        self.contentView.backgroundColor = [UIColor whiteColor];
    }
}

- (void)setConversation:(TIMConversation *)conversation
{
    _conversation = conversation;
    TIMMessage *lastMsg = [_conversation getLastMsg];
    
    if (TIM_C2C == conversation.getType) {
        NSString *receiverID = [conversation getReceiver];
        TIMFriend *friend = [[TIMFriendshipManager sharedInstance] queryFriend:receiverID];
        
        _nameLabel.text = friend.profile.nickname;
        [_iconImageView sd_setImageWithURL:[NSURL URLWithString:friend.profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
        
        // 内容
        if ([lastMsg elemCount] > 0) {
            TIMElem *elem = [lastMsg getElem:0];
            _messageLabel.text = [self getTextFromMessage:elem];
        } else {
            _messageLabel.text = nil;
        }
    }
    else if (TIM_GROUP == conversation.getType) {
        NSString *receiverID = [conversation getReceiver];
        TIMGroupInfo *groupInfo = [[TIMGroupManager sharedInstance] queryGroupInfo:receiverID];
        
        _nameLabel.text = groupInfo.groupName;
        [_iconImageView sd_setImageWithURL:[NSURL URLWithString:groupInfo.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
        
        // 内容
        if ([lastMsg elemCount] > 0) {
            TIMElem *elem = [lastMsg getElem:0];
            _messageLabel.text = [self getTextFromMessage:elem];
        } else {
            _messageLabel.text = nil;
        }
    }
    else if (TIM_SYSTEM == conversation.getType) {
        
    }
    
    // 时间
    NSString *time = [lastMsg.timestamp formattedDateDescription];
    _timeLabel.text = time;
    
    // 未读数角标
    _nameLabel.font = [UIFont boldSystemFontOfSize:[XOSettingManager defaultManager].fontSize];
    _messageLabel.font = [UIFont systemFontOfSize:([XOSettingManager defaultManager].fontSize - 2.0)];
    int num = [conversation getUnReadMessageNum];
    if (num <= 0) {
        _unreadLabel.text = @"";
        _unreadLabel.hidden = YES;
    } else {
        _unreadLabel.text = [NSString stringWithFormat:@"%d", num];
        _unreadLabel.hidden = NO;
    }
}


- (NSString *)getTextFromMessage:(TIMElem *)elem
{
    NSString *text = nil;
    if ([elem isKindOfClass:[TIMTextElem class]] ||         // 文字
        [elem isKindOfClass:[TIMGroupTipsElem class]] ||    // 群Tips
        [elem isKindOfClass:[TIMGroupSystemElem class]])    // 群系统消息
    {
        text = [(TIMTextElem *)elem text];
    }
    else if ([elem isKindOfClass:[TIMImageElem class]]) { // 图片
        text = XOChatLocalizedString(@"conversation.message.image");
    }
    else if ([elem isKindOfClass:[TIMSoundElem class]]) { // 语音
        text = XOChatLocalizedString(@"conversation.message.sound");
    }
    else if ([elem isKindOfClass:[TIMVideoElem class]]) { // 视频
        text = XOChatLocalizedString(@"conversation.message.video");
    }
    else if ([elem isKindOfClass:[TIMFileElem class]]) {  // 文件
        text = XOChatLocalizedString(@"conversation.message.file");
    }
    else if ([elem isKindOfClass:[TIMFaceElem class]]) {  // 表情
        text = XOChatLocalizedString(@"conversation.message.face");
    }
    else if ([elem isKindOfClass:[TIMLocationElem class]]) { // 地理位置
        text = XOChatLocalizedString(@"conversation.message.location");
    }
    else if ([elem isKindOfClass:[TIMCustomElem class]]) {   // 自定义消息
        // 名片
        // 音视频
        // 红包
        // 转账
    }
    return text;
}




- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
