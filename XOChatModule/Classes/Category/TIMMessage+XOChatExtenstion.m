//
//  TIMMessage+XOChatExtenstion.m
//  AFNetworking
//
//  Created by kenter on 2019/11/19.
//

#import "TIMMessage+XOChatExtenstion.h"
#import <XOBaseLib/XOBaseLib.h>


@implementation TIMMessage (XOChatExtenstion)

- (NSString *)getThumbImageName
{
    NSString *thumbImageName = nil;
    
    if ([self elemCount] > 0)
    {
        TIMElem *elem = [self getElem:0];
        if ([elem isKindOfClass:[TIMImageElem class]]) {
            TIMImageElem *imageElem = (TIMImageElem *)elem;
            // 自己发送的消息
            if (self.isSelf) {
                if (!XOIsEmptyString(imageElem.path)) {
                    thumbImageName = [[imageElem.path lastPathComponent] stringByReplacingOccurrencesOfString:@"." withString:@"_thumb."];
                } else {
                    if (imageElem.imageList.count > 0) {
                        TIMImage *timImage = imageElem.imageList[0];
                        thumbImageName = [NSString stringWithFormat:@"%@_thumb.%@", timImage.uuid, [self getImageFormat]];
                    }
                }
            }
            // 别人发送的消息
            else {
                if (imageElem.imageList.count > 0) {
                    TIMImage *timImage = imageElem.imageList[0];
                    thumbImageName = [NSString stringWithFormat:@"%@_thumb.%@", timImage.uuid, [self getImageFormat]];
                }
            }
        }
        else if ([elem isKindOfClass:[TIMVideoElem class]]) {
            TIMVideoElem *videoElem = (TIMVideoElem *)elem;
            TIMSnapshot *snapshot = videoElem.snapshot;
            // 自己发送的消息
            if (self.isSelf) {
                if (!XOIsEmptyString(videoElem.snapshotPath)) {
                    thumbImageName = [videoElem.snapshotPath lastPathComponent];
                }
                else if (snapshot) {
                    NSString *snapshotFormat = XOIsEmptyString(snapshot.type) ? @"jpg" : snapshot.type;
                    thumbImageName = [NSString stringWithFormat:@"%@.%@", snapshot.uuid, snapshotFormat];
                }
            }
            // 别人发送的消息
            else {
                if (snapshot) {
                    NSString *snapshotFormat = XOIsEmptyString(snapshot.type) ? @"jpg" : snapshot.type;
                    thumbImageName = [NSString stringWithFormat:@"%@.%@", snapshot.uuid, snapshotFormat];
                }
            }
        }
    }
    return thumbImageName;
}

- (NSString *)getThumbImagePath
{
    NSString *thumbImagePath = nil;
    if ([self elemCount] > 0)
    {
        TIMElem *elem = [self getElem:0];
        if ([elem isKindOfClass:[TIMImageElem class]]) {
            thumbImagePath = [XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:[self getThumbImageName]];
        }
        else if ([elem isKindOfClass:[TIMVideoElem class]]) {
            thumbImagePath = [XOMsgFileDirectory(XOMsgFileTypeVideo) stringByAppendingPathComponent:[self getThumbImageName]];
        }
    }
    return thumbImagePath;
}

- (NSString *)getImageName
{
    NSString *imageName = nil;
    
    if ([self elemCount] > 0)
    {
        TIMElem *elem = [self getElem:0];
        if ([elem isKindOfClass:[TIMImageElem class]]) {
            TIMImageElem *imageElem = (TIMImageElem *)elem;
            
            // 自己发送的消息
            if (self.isSelf) {
                if (!XOIsEmptyString(imageElem.path)) {
                    imageName = [imageElem.path lastPathComponent];
                } else {
                    if (imageElem.imageList.count > 0) {
                        TIMImage *timImage = imageElem.imageList[0];
                        imageName = [NSString stringWithFormat:@"%@.%@", timImage.uuid, [self getImageFormat]];
                    }
                }
            }
            // 别人发送的消息
            else {
                if (imageElem.imageList.count > 0) {
                    TIMImage *timImage = imageElem.imageList[0];
                    imageName = [NSString stringWithFormat:@"%@.%@", timImage.uuid, [self getImageFormat]];
                }
            }
        }
    }
    return imageName;
}

- (NSString *)getImagePath
{
    NSString *imagePath = nil;
    if ([self elemCount] > 0)
    {
        TIMElem *elem = [self getElem:0];
        if ([elem isKindOfClass:[TIMImageElem class]]) {
            imagePath = [XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:[self getImageName]];
        }
        else if ([elem isKindOfClass:[TIMVideoElem class]]) {
            imagePath = [XOMsgFileDirectory(XOMsgFileTypeVideo) stringByAppendingPathComponent:[self getImageName]];
        }
    }
    return imagePath;
}

- (NSString *)getVideoName
{
    NSString *videoName = nil;
    
    if ([self elemCount] > 0)
    {
        TIMElem *elem = [self getElem:0];
        if ([elem isKindOfClass:[TIMVideoElem class]]) {
            TIMVideoElem *videoElem = (TIMVideoElem *)elem;
            // 自己发送的消息
            if (self.isSelf) {
                if (!XOIsEmptyString(videoElem.videoPath)) {
                    videoName = [videoElem.videoPath.lastPathComponent lastPathComponent];
                } else {
                    TIMVideo *timVideo = videoElem.video;
                    NSString *videoFomat = !XOIsEmptyString(timVideo.type) ? timVideo.type : @"mp4";
                    videoName = [NSString stringWithFormat:@"%@.%@", timVideo.uuid, videoFomat];
                }
            }
            // 别人发送的消息
            else {
                TIMVideo *timVideo = videoElem.video;
                NSString *videoFomat = !XOIsEmptyString(timVideo.type) ? timVideo.type : @"mp4";
                videoName = [NSString stringWithFormat:@"%@.%@", timVideo.uuid, videoFomat];
            }
        }
    }
    return videoName;
}
- (NSString *)getVideoPath
{
    NSString *videoPath = nil;
    if ([self elemCount] > 0)
    {
        TIMElem *elem = [self getElem:0];
        if ([elem isKindOfClass:[TIMVideoElem class]]) {
            videoPath = [XOMsgFileDirectory(XOMsgFileTypeVideo) stringByAppendingPathComponent:[self getVideoName]];
        }
    }
    return videoPath;
}

- (NSString *)getSoundPath
{
    NSString *soundPath = nil;
    if ([self elemCount] > 0)
    {
        TIMElem *elem = [self getElem:0];
        if ([elem isKindOfClass:[TIMSoundElem class]]) {
            TIMSoundElem *soundElem = (TIMSoundElem *)elem;
            // 自己发送的消息
            if (self.isSelf) {
                if (!XOIsEmptyString(soundElem.path)) {
                    soundPath = [XOMsgFileDirectory(XOMsgFileTypeAudio) stringByAppendingPathComponent:soundElem.path.lastPathComponent];
                } else {
                    NSString *soundName = [NSString stringWithFormat:@"%@.mp3", soundElem.uuid];
                    soundPath = [XOMsgFileDirectory(XOMsgFileTypeAudio) stringByAppendingPathComponent:soundName];
                }
            }
            // 别人发送的消息
            else {
                NSString *soundName = [NSString stringWithFormat:@"%@.mp3", soundElem.uuid];
                soundPath = [XOMsgFileDirectory(XOMsgFileTypeAudio) stringByAppendingPathComponent:soundName];
            }
        }
    }
    return soundPath;
}

- (NSString *)getFilePath
{
    NSString *filePath = nil;
    if ([self elemCount] > 0)
    {
        TIMElem *elem = [self getElem:0];
        if ([elem isKindOfClass:[TIMFileElem class]]) {
            TIMFileElem *fileElem = (TIMFileElem *)elem;
            // 自己发送的消息
            if (self.isSelf) {
                if (!XOIsEmptyString(fileElem.path)) {
                    filePath = [XOMsgFileDirectory(XOMsgFileTypeFile) stringByAppendingPathComponent:fileElem.filename];
                } else {
                    NSString *filename = !XOIsEmptyString(fileElem.filename) ? fileElem.filename : [NSString stringWithFormat:@"%@.unknow", fileElem.uuid];
                    filePath = [XOMsgFileDirectory(XOMsgFileTypeFile) stringByAppendingPathComponent:filename];
                }
            }
            // 别人发送的消息
            else {
                NSString *filename = !XOIsEmptyString(fileElem.filename) ? fileElem.filename : [NSString stringWithFormat:@"%@.unknow", fileElem.uuid];
                filePath = [XOMsgFileDirectory(XOMsgFileTypeFile) stringByAppendingPathComponent:filename];
            }
        }
    }
    return filePath;
}

// 获取图片的格式
- (NSString *)getImageFormat
{
    NSString *format = @"jpg";
    
    if ([self elemCount] > 0)
    {
        TIMElem *elem = [self getElem:0];
        if ([elem isKindOfClass:[TIMImageElem class]]) {
            TIMImageElem *imageElem = (TIMImageElem *)elem;
            switch (imageElem.format) {
                case TIM_IMAGE_FORMAT_PNG:
                    format = @"png";
                    break;
                case TIM_IMAGE_FORMAT_GIF:
                    format = @"gif";
                    break;
                case TIM_IMAGE_FORMAT_BMP:
                    format = @"bmp";
                    break;
                default:
                    format = @"jpg";
                    break;
            }
        }
        else if ([elem isKindOfClass:[TIMVideoElem class]]) {
            TIMVideoElem *videoElem = (TIMVideoElem *)elem;
            if (videoElem.snapshot) {
                TIMSnapshot *snapshot = videoElem.snapshot;
                if (snapshot && !XOIsEmptyString(snapshot.type)) {
                    format = [snapshot.type copy];
                }
            }
        }
    }
    
    return format;
}

@end
