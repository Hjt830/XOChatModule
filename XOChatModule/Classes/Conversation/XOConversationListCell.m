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
#import "UIImage+XOChatExtension.h"
#import <XOBaseLib/XOBaseLib.h>
#import "ZXChatHelper.h"
#import "TIMElem+XOExtension.h"
#import "UIColor+XOExtension.h"
#import "XOContactManager.h"

@interface XOConversationListCell ()

@property (nonatomic, strong) UIImageView   *iconImageView;
@property (nonatomic, strong) UILabel       *nameLabel;
@property (nonatomic, strong) UILabel       *timeLabel;
@property (nonatomic, strong) UILabel       *messageLabel;
@property (nonatomic, strong) UILabel       *unreadLabel;
@property (nonatomic, strong) UILabel       *topLabel;

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
    self.backgroundColor = [UIColor XOWhiteColor];
   
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.clipsToBounds = YES;
    _iconImageView.backgroundColor = RGBA(221, 222, 224, 1);
    
    _nameLabel = [UILabel new];
    CGFloat fontSize = [XOSettingManager defaultManager].fontSize;
    _nameLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    _nameLabel.textColor = [UIColor XOTextColor];
    
    
    _timeLabel = [UILabel new];
    _timeLabel.font = [UIFont systemFontOfSize:12];
    _timeLabel.textColor = [UIColor lightGrayColor];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    
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
    
    _topLabel = [[UILabel alloc] init];
    _topLabel.font = [UIFont systemFontOfSize:13];
    _topLabel.textColor = [UIColor redColor];
    _topLabel.textAlignment = NSTextAlignmentRight;
    _topLabel.text = XOChatLocalizedString(@"conversation.top.title");
    
    [self.contentView addSubview:_iconImageView];
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_timeLabel];
    [self.contentView addSubview:_messageLabel];
    [self.contentView addSubview:_unreadLabel];
    [self.contentView addSubview:_topLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat margin = 10.0;
    CGFloat maxWid = self.contentView.frame.size.width;
    CGFloat maxHei = self.contentView.frame.size.height;
    
    self.iconImageView.frame = CGRectMake(margin * 2.0, margin, maxHei - margin * 2, maxHei - margin * 2);
    self.iconImageView.layer.cornerRadius = (maxHei - margin * 2)/2.0;
    
    CGFloat timeWid = [self.timeLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 16.0) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: self.timeLabel.font} context:nil].size.width + 5.0;
    CGFloat timeLeft = maxWid - margin - timeWid;
    self.timeLabel.frame = CGRectMake(timeLeft, margin + 5.0, timeWid, 16.0);
    
    CGFloat nameLeft = CGRectGetMaxX(self.iconImageView.frame) + margin * 2;
    CGFloat nameWid = timeLeft - nameLeft - margin;
    self.nameLabel.frame = CGRectMake(nameLeft, margin, nameWid, 24.0);
    
    CGFloat unredLeft = CGRectGetMaxX(self.iconImageView.frame) - 8.0;
    CGFloat unredTop  = CGRectGetMinY(self.iconImageView.frame) - 5.0;
    self.unreadLabel.frame = CGRectMake(unredLeft, unredTop, 18.0, 18.0);
    
    CGFloat msgTop = CGRectGetMaxY(self.iconImageView.frame) - 20.0;
    if (self.shouldTopShow) {
        self.topLabel.hidden = NO;
        self.topLabel.frame = CGRectMake(maxWid - margin - 40, msgTop, 40, 16.0);
    } else {
        self.topLabel.hidden = YES;
        self.topLabel.frame = CGRectZero;
    }
    
    CGFloat msgLeft = CGRectGetMaxX(self.iconImageView.frame) + margin * 2;
    CGFloat msgWid = maxWid - margin - msgLeft;
    if (self.shouldTopShow) msgWid -= (margin + 40);
    self.messageLabel.frame = CGRectMake(msgLeft, msgTop, msgWid, 20.0);
}

- (void)setConversation:(TIMConversation *)conversation
{
    _conversation = conversation;
    
    self.shouldTopShow = [[XOContactManager defaultManager] isToppingReceiver:[conversation getReceiver]];
    if (self.shouldTopShow) {
        self.backgroundColor = BG_TableColor;
    } else {
        if (@available(iOS 13.0, *)) {
            self.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            self.backgroundColor = [UIColor whiteColor];
        }
    }
    
    TIMMessage *lastMsg = [_conversation getLastMsg];
    
    if (TIM_C2C == conversation.getType) {
        NSString *receiverID = [conversation getReceiver];
        TIMFriend *friend = [[TIMFriendshipManager sharedInstance] queryFriend:receiverID];
        
        _nameLabel.text = friend.profile.nickname;
        [_iconImageView sd_setImageWithURL:[NSURL URLWithString:friend.profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
        
        // 内容
        if ([lastMsg elemCount] > 0) {
            TIMElem *elem = [lastMsg getElem:0];
            NSString *text = [elem getTextFromMessage];
            if ([text isKindOfClass:[NSAttributedString class]]) {
                NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:(NSAttributedString *)text];
                NSMutableParagraphStyle *par = [[NSMutableParagraphStyle alloc] init];
                par.alignment = NSTextAlignmentLeft;
                [string addAttributes:@{NSParagraphStyleAttributeName: par} range:NSMakeRange(0, text.length)];
                _messageLabel.attributedText = (NSAttributedString *)string;
            } else {
                _messageLabel.text = text;
            }
        } else {
            _messageLabel.text = nil;
        }
    }
    else if (TIM_GROUP == conversation.getType) {
        NSString *receiverID = [conversation getReceiver];
        __block TIMGroupInfo *groupInfo = [[TIMGroupManager sharedInstance] queryGroupInfo:receiverID];
        _nameLabel.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.groupName, groupInfo.memberNum];
        
        [[TIMGroupManager sharedInstance] getGroupInfo:@[receiverID] succ:^(NSArray<TIMGroupInfo *> *arr) {
            if (arr > 0) {
                groupInfo = arr[0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_nameLabel.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.groupName, groupInfo.memberNum];
                });
            }
        } fail:^(int code, NSString *msg) {
            
        }];
        
        if (!XOIsEmptyString(groupInfo.faceURL)) {
            [_iconImageView sd_setImageWithURL:[NSURL URLWithString:groupInfo.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
            [_iconImageView sd_setImageWithURL:[NSURL URLWithString:groupInfo.faceURL] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (image) {
                    self.iconImageView.image = image;
                } else {
                    self.iconImageView.image = [UIImage groupDefaultImageAvatar];
                }
            }];
        } else {
            [UIImage combineGroupImageWithGroupId:receiverID complection:^(UIImage * _Nonnull image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.iconImageView.image = image;
                });
            }];
        }
        
        // 内容
        if ([lastMsg elemCount] > 0) {
            TIMElem *elem = [lastMsg getElem:0];
            NSString *text = [elem getTextFromMessage];
            if ([text isKindOfClass:[NSAttributedString class]]) {
                NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:(NSAttributedString *)text];
                NSMutableParagraphStyle *par = [[NSMutableParagraphStyle alloc] init];
                par.alignment = NSTextAlignmentLeft;
                [string addAttributes:@{NSParagraphStyleAttributeName: par} range:NSMakeRange(0, text.length)];
                _messageLabel.attributedText = string;
            } else {
                _messageLabel.text = text;
            }
        }
        else {
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
    
    [self setNeedsLayout];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
