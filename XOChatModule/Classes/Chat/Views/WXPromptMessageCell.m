//
//  WXPromptMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/5/5.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXPromptMessageCell.h"
#import "XOChatModule.h"

@interface WXPromptMessageCell ()

@property (nonatomic, strong) UILabel * titleLabel;

@end

@implementation WXPromptMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.titleLabel];
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(SCREEN_WIDTH * 0.92, MAXFLOAT)];
    float MaxWidth = SCREEN_WIDTH * 0.92;
    float MinHeight = 20;
    self.titleLabel.size = CGSizeMake(size.width <= MaxWidth ? size.width : MaxWidth, size.height <= MinHeight ? 20 : MinHeight);
    self.titleLabel.center = CGPointMake(self.contentView.width/2.0, self.height/2.0);
}


- (void)setMessage:(TIMMessage *)message
{
    _message = message;
    
    /*
    TIMElem *elem = [message getElem:0];
    
    NSInteger action = [message.ext[@"action"] integerValue];
    NSString *content = nil;
    switch (action) {
        case 6001: // 撤回消息
        {
            if (message.isSelf) {
                content = @"你撤回一条消息";
            } else {
                if (HTChatTypeSingle == message.chatType) {
                    content = @"对方撤回一条消息";
                } else {
                    NSDictionary *ext = message.ext;
                    content = [NSString stringWithFormat:@"'%@' 撤回一条消息", ext[@"nick"]];
                }
            }
        }
            break;
        case 10004: // 红包领取
        {
            NSDictionary *ext = message.ext;
            if (HTChatTypeSingle == message.chatType) { // 单聊红包
                if (message.isSender) {
                    NSString *senderId = ext[@"sender"];
                    NSString *senderNick = nil;
                    if (!WXIsEmptyString(senderId)) senderNick = [[WXContactCoreDataStorage getInstance] getContactWith:senderId].nick;
                    
                    if (WXIsEmptyString(senderNick)) content = @"你领取了对方的红包";
                    else content = [NSString stringWithFormat:@"你领取了 '%@' 的红包", senderNick];
                }
                else {
                    NSString *receiverNick = ext[@"nick"];
                    if (WXIsEmptyString(receiverNick)) content = @"对方领取了你的红包";
                    else content = [NSString stringWithFormat:@"'%@' 领取了你的红包", receiverNick];
                }
            }
            else { // 群聊红包
                // 获取 红包发送人昵称 和 拆红包人昵称
                BOOL isDone = [ext[@"isDone"] boolValue];
                NSString *senderId = ext[@"sender"];
                NSString *groupId = ext[@"groupId"];
                NSString *receiverNick = ext[@"nick"];
                __block NSString *senderNick = nil;
                if (!WXIsEmptyString(groupId)) {
                    WXGroup *group = [[WXGroupCoreDataStorage getInstance] getGroupWith:groupId];
                    [group.members enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSString *memberId = obj[@"userId"];
                        if (!WXIsEmptyString(memberId) && [memberId isEqualToString:senderId]) senderNick = obj[@"nick"];
                    }];
                }
                
                if (message.isSender) {
                    if (WXIsEmptyString(senderNick)) {
                        content = @"你领取了群红包";
                        if (isDone) content = @"你领取了最后一个群红包";
                    }
                    else {
                        content = [NSString stringWithFormat:@"你领取了 '%@' 的红包", senderNick];
                        if (isDone) content = [NSString stringWithFormat:@"你领取了 '%@' 的最后一个红包", senderNick];
                    }
                }
                else {
                    if (!WXIsEmptyString(receiverNick) && !WXIsEmptyString(senderNick)) {
                        content = [NSString stringWithFormat:@"'%@' 领取了 '%@' 的红包", receiverNick, senderNick];
                        if (isDone) content = [NSString stringWithFormat:@"'%@' 领取了 '%@' 的最后一个红包", receiverNick, senderNick];
                    }
                    else if (!WXIsEmptyString(receiverNick) && WXIsEmptyString(senderNick)) {
                        content = [NSString stringWithFormat:@"'%@' 领取了群红包", receiverNick];
                        if (isDone) content = [NSString stringWithFormat:@"'%@' 领取了最后一个群红包", receiverNick];
                    }
                    else if (WXIsEmptyString(receiverNick) && !WXIsEmptyString(senderNick)) {
                        content = [NSString stringWithFormat:@"领取了 '%@' 的红包", senderNick];
                        if (isDone) content = [NSString stringWithFormat:@"领取了 '%@' 的最后一个红包", senderNick];
                    }
                    else if (WXIsEmptyString(receiverNick) && WXIsEmptyString(senderNick)) {
                        content = [NSString stringWithFormat:@"领取了群红包"];
                        if (isDone) content = [NSString stringWithFormat:@"领取了最后一个群红包"];
                    }
                }
            }
        }
            break;
        case 10005: // 转账金额被领取或退还 - 只有单聊
        {
            NSDictionary *ext = message.ext;
            jrmfTransferStatus status = (jrmfTransferStatus)[ext[@"transferStat"] intValue];
            if (kjrmfTrfStatusGet == status) {
                if (message.isSender) {
                    NSString *senderId = ext[@"sender"];
                    if (WXIsEmptyString(senderId)) {
                        WXContact *contact = [[WXContactCoreDataStorage getInstance] getContactWith:senderId];
                        if (contact) {
                            content = [NSString stringWithFormat:@"你领取了 '%@' 的转账", contact.nick];
                        } else {
                            content = @"你领取了对方的转账";
                        }
                    } else {
                        content = @"你领取了对方的转账";
                    }
                }
                else {
                    content = [NSString stringWithFormat:@"'%@' 领取了你的转账", ext[@"nick"]];
                }
            }
            else if (kjrmfTrfStatusReturn == status) {
                content = NSLocalizedString(@"chat.transfer.return", nil);
            }
        }
            break;
        default:
            break;
    }
    
    content = [NSString stringWithFormat:@" %@ ", content];
    self.titleLabel.text = content;
    */
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = XOSystemFont(13.0);
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = RGBA(109, 109, 114, 1.0);
        _titleLabel.backgroundColor = RGBA(200, 200, 200, 1.0);
        _titleLabel.layer.cornerRadius = 5.0f;
        _titleLabel.clipsToBounds = YES;
    }
    return _titleLabel;
}


@end
