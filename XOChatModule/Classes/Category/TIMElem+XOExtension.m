//
//  TIMElem+XOExtension.m
//  XOChatModule
//
//  Created by kenter on 2019/11/14.
//

#import "TIMElem+XOExtension.h"
#import "NSBundle+ChatModule.h"
#import "ZXChatHelper.h"
#import "XOChatMarco.h"
#import <XOBaseLib/XOBaseLib.h>

@implementation TIMElem (XOExtension)

- (NSString *)getTextFromMessage
{
    NSString *text = nil;
    if ([self isKindOfClass:[TIMTextElem class]])    // 群系统消息
    {
        NSString *messageStr = [(TIMTextElem *)self text];
        text = [ZXChatHelper formatMessageString:messageStr].mutableCopy;
    }
    else if ([self isKindOfClass:[TIMImageElem class]]) { // 图片
        text = XOChatLocalizedString(@"conversation.message.image");
    }
    else if ([self isKindOfClass:[TIMSoundElem class]]) { // 语音
        text = XOChatLocalizedString(@"conversation.message.sound");
    }
    else if ([self isKindOfClass:[TIMVideoElem class]]) { // 视频
        text = XOChatLocalizedString(@"conversation.message.video");
    }
    else if ([self isKindOfClass:[TIMFileElem class]]) {  // 文件
        text = XOChatLocalizedString(@"conversation.message.file");
    }
    else if ([self isKindOfClass:[TIMFaceElem class]]) {  // 表情
        text = XOChatLocalizedString(@"conversation.message.face");
    }
    else if ([self isKindOfClass:[TIMLocationElem class]]) { // 地理位置
        text = XOChatLocalizedString(@"conversation.message.location");
    }
    else if ([self isKindOfClass:[TIMGroupTipsElem class]]) // 群Tips
    {
        TIMGroupTipsElem *tipsElem = (TIMGroupTipsElem *)self;
        NSString *opUsername = tipsElem.opUserInfo.nickname;
        
        switch (tipsElem.type) {
            case TIM_GROUP_TIPS_TYPE_INVITE: {          // 邀请加入群
                NSString *inviteUserName = [self userListCombineNameWith:tipsElem];
                text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.invite.%@.%@") , opUsername, inviteUserName];
            }
                break;
            case TIM_GROUP_TIPS_TYPE_QUIT_GRP: {        // 退出群
                text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.exit.%@") , opUsername];
            }
                break;
            case TIM_GROUP_TIPS_TYPE_KICKED: {          // 踢出群
                NSString *lickoutUserName = [self userListCombineNameWith:tipsElem];
                text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.kickout.%@.%@") , opUsername, lickoutUserName];
            }
                break;
            case TIM_GROUP_TIPS_TYPE_SET_ADMIN: {       // 设置管理员
                NSString *adminUserName = [self userListCombineNameWith:tipsElem];
                text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.adminSet.%@.%@") , opUsername, adminUserName];
            }
                break;
            case TIM_GROUP_TIPS_TYPE_CANCEL_ADMIN: {    // 取消管理员
                NSString *adminUserName = [self userListCombineNameWith:tipsElem];
                text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.adminCancel.%@.%@") , opUsername, adminUserName];
            }
                break;
            case TIM_GROUP_TIPS_TYPE_INFO_CHANGE:  {   // 群资料变更
                
                if (tipsElem.groupChangeList.count > 0) {
                    
                    TIMGroupTipsElemGroupInfo *changeInfo = tipsElem.groupChangeList[0];
                    NSString *value = changeInfo.value;
                    switch (changeInfo.type) {
                        case TIM_GROUP_INFO_CHANGE_GROUP_NAME:  // 群名修改
                            text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.changeGroupName.%@.%@") , opUsername, value];
                            break;
                        case TIM_GROUP_INFO_CHANGE_GROUP_INTRODUCTION:  // 群简介修改
                            text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.changeGroupIntroduce.%@.%@") , opUsername, value];
                            break;
                        case TIM_GROUP_INFO_CHANGE_GROUP_NOTIFICATION:  // 群公告修改
                            text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.changeGroupNotification.%@.%@") , opUsername, value];
                            break;
                        case TIM_GROUP_INFO_CHANGE_GROUP_FACE:  // 群头像修改
                            text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.changeGroupIcon.%@") , opUsername];
                            break;
                        case TIM_GROUP_INFO_CHANGE_GROUP_OWNER: // 群主变更
                            text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.changeGroupSuper.%@") , value];
                            break;
                        default:
                            break;
                    }
                }
            }
                break;
            case TIM_GROUP_TIPS_TYPE_MEMBER_INFO_CHANGE:   // 群成员资料变更
                
                break;
                
            default:
                break;
        }
        
        NSMutableParagraphStyle *paragrap = [[NSMutableParagraphStyle alloc] init];
        paragrap.lineSpacing = 5.0;
        paragrap.alignment = NSTextAlignmentCenter;
        NSMutableAttributedString *mutStr = [[NSMutableAttributedString alloc] initWithString:text];
        [mutStr addAttributes:@{NSFontAttributeName: XOSystemFont(13.0f)} range:NSMakeRange(0, text.length)];
        [mutStr addAttributes:@{NSForegroundColorAttributeName: RGBA(109, 109, 114, 1.0)} range:NSMakeRange(0, text.length)];
        [mutStr addAttributes:@{NSParagraphStyleAttributeName: paragrap} range:NSMakeRange(0, text.length)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
        text = mutStr;
#pragma clang diagnostic pop
    }
    else if ([self isKindOfClass:[TIMGroupSystemElem class]])
    {
        text = nil;
    }
    else if ([self isKindOfClass:[TIMCustomElem class]])    // 自定义消息
    {
        TIMCustomElem *customElem = (TIMCustomElem *)self;
        if (customElem.data.length > 0) {
            NSError *jsonError = nil;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:customElem.data options:NSJSONReadingMutableContainers error:&jsonError];
            if (!jsonError) {
                int code = [jsonDict[XOCustomMessage_Key_Code] intValue];
                if (XOCustomMessage_Code_Revoke == code) {          // 撤回消息
                    NSString *operateNickname = jsonDict[XOCustomMessage_Key_OperaNick];
                    text = [NSString stringWithFormat:XOChatLocalizedString(@"chat.message.revoke.%@"), operateNickname];
                }
                else if (XOCustomMessage_Code_VoiceCall == code) {  // 音频通话消息
                    
                }
                else if (XOCustomMessage_Code_VideoCall == code) {  // 视频通话消息
                    
                }
                else if (XOCustomMessage_Code_Redpacket == code) {  // 红包消息
                    
                }
                else if (XOCustomMessage_Code_Transfer == code) {   // 转账消息
                    
                }
            }
        }
        // 音视频
        // 红包
        // 转账
    }
    return text;
}

- (NSString *)userListCombineNameWith:(TIMGroupTipsElem *)tipsElem
{
    NSMutableString *inviteUserName = [[NSMutableString alloc] init];
    for (int i = 0; i < tipsElem.changedUserInfo.allValues.count; i++) {
        TIMUserProfile *profile = tipsElem.changedUserInfo.allValues[i];
        if ([profile isKindOfClass:[TIMUserProfile class]] && !XOIsEmptyString(profile.nickname)) {
            [inviteUserName appendString:profile.nickname];
            if (i < (tipsElem.userList.count - 1)) {
                [inviteUserName appendString:@"、"];
            }
        }
    }
    return inviteUserName;
}

@end
