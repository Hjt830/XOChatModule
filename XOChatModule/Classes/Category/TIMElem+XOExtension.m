//
//  TIMElem+XOExtension.m
//  XOChatModule
//
//  Created by kenter on 2019/11/14.
//

#import "TIMElem+XOExtension.h"
#import "NSBundle+ChatModule.h"
#import "ZXChatHelper.h"
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
                text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.invite.%@.%@.%@") , opUsername, inviteUserName, tipsElem.groupName];
            }
                break;
            case TIM_GROUP_TIPS_TYPE_QUIT_GRP: {        // 退出群
                text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.exit.%@.%@") , opUsername, tipsElem.groupName];
            }
                break;
            case TIM_GROUP_TIPS_TYPE_KICKED: {          // 踢出群
                NSString *lickoutUserName = [self userListCombineNameWith:tipsElem];
                text = [NSString stringWithFormat:XOChatLocalizedString(@"group.tip.kickout.%@.%@.%@") , opUsername, lickoutUserName, tipsElem.groupName];
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
                    switch (changeInfo.type) {
                        case TIM_GROUP_INFO_CHANGE_GROUP_NAME:  // 群名修改
                            
                            break;
                        case TIM_GROUP_INFO_CHANGE_GROUP_INTRODUCTION:  // 群简介修改
                            
                            break;
                        case TIM_GROUP_INFO_CHANGE_GROUP_NOTIFICATION:  // 群公告修改
                            
                            break;
                        case TIM_GROUP_INFO_CHANGE_GROUP_FACE:  // 群头像修改
                            
                            break;
                        case TIM_GROUP_INFO_CHANGE_GROUP_OWNER: // 群主变更
                            
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

        /**
//         *  群资料变更 (opUser & groupName & introduction & notification & faceUrl & owner)
//         */
//        TIM_GROUP_TIPS_TYPE_INFO_CHANGE         = 0x06,
//        /**
//         *  群成员资料变更 (opUser & groupName & memberInfoList)
//         */
//        TIM_GROUP_TIPS_TYPE_MEMBER_INFO_CHANGE         = 0x07,
    }
    else if ([self isKindOfClass:[TIMGroupSystemElem class]]) {
        
    }
    else if ([self isKindOfClass:[TIMCustomElem class]]) {   // 自定义消息
        // 名片
        // 音视频
        // 红包
        // 转账
    }
    return text;
}

- (NSString *)userListCombineNameWith:(TIMGroupTipsElem *)tipsElem
{
    NSMutableString *inviteUserName = [[NSMutableString alloc] init];
    for (int i = 0; i < tipsElem.userList.count; i++) {
        NSString *inviteUser = tipsElem.userList[i];
        [inviteUserName appendString:inviteUser];
        if (i < (tipsElem.userList.count - 1)) {
            [inviteUserName appendString:@"、"];
        }
    }
    return inviteUserName;
}

@end
