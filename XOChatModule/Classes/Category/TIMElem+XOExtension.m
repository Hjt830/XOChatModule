//
//  TIMElem+XOExtension.m
//  XOChatModule
//
//  Created by kenter on 2019/11/14.
//

#import "TIMElem+XOExtension.h"

#import <AppKit/AppKit.h>


@implementation TIMElem (XOExtension)

- (NSString *)getTextFromMessage:(TIMElem *)elem
{
    NSString *text = nil;
    if ([elem isKindOfClass:[TIMTextElem class]] ||         // 文字
        [elem isKindOfClass:[TIMGroupTipsElem class]] ||    // 群Tips
        [elem isKindOfClass:[TIMGroupSystemElem class]])    // 群系统消息
    {
        NSString *messageStr = [(TIMTextElem *)elem text];
        text = [ZXChatHelper formatMessageString:messageStr].mutableCopy;
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

@end
