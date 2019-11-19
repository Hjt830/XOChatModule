//
//  TIMImage+XOChatExtenstion.m
//  AFNetworking
//
//  Created by kenter on 2019/11/19.
//

#import "TIMImage+XOChatExtenstion.h"
#import <XOBaseLib/XOBaseLib.h>


@implementation TIMMessage (XOChatExtenstion)

- (NSString *)thumbImageName
{
    NSString *thumbImageName = [NSString stringWithFormat:@"%@_thumb.%@", self.uuid, [self getImageFormat]];
    return thumbImageName;
}
- (NSString *)thumbImagePath
{
    
}


// 获取图片的格式
- (NSString *)getImageFormat
{
    NSString *format = nil;
    
    switch (self.format) {
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
    return format;
}

@end
