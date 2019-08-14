//
//  UIImage+XOChatBundle.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/8/14.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "UIImage+XOChatBundle.h"
#import "NSBundle+ChatModule.h"
#import "XOChatClient.h"

@implementation UIImage (XOChatBundle)

+ (UIImage *)xo_imageNamedFromChatBundle:(NSString *)name
{
    NSBundle *imageBundle = [XOChatClient shareClient].chatBundle;
    
    // 根据设备分辨率选择图片
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale >= 3.0) {
        // 取三倍图
        name = [name stringByAppendingString:@"@3x"];
        NSString *imagePath = [imageBundle pathForResource:name ofType:@"png"];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        
        if (nil == image) {
            // 没有三倍图, 取两倍图
            name = [name stringByReplacingOccurrencesOfString:@"@3x" withString:@"@2x"];
            imagePath = [imageBundle pathForResource:name ofType:@"png"];
            image = [UIImage imageWithContentsOfFile:imagePath];
            
            if (nil == image) {
                // 没有两倍图, 取一倍图
                name = [name stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
                imagePath = [imageBundle pathForResource:name ofType:@"png"];
                image = [UIImage imageWithContentsOfFile:imagePath];
            }
        }
        
        return image;
    }
    else if (scale >= 2.0) {
        // 取两倍图
        name = [name stringByAppendingString:@"@2x"];
        NSString *imagePath = [imageBundle pathForResource:name ofType:@"png"];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        
        if (nil == image) {
            // 没有两倍图, 取一倍图
            name = [name stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
            imagePath = [imageBundle pathForResource:name ofType:@"png"];
            image = [UIImage imageWithContentsOfFile:imagePath];
        }
        
        return image;
    }
    else {
        // 取一倍图
        NSString *imagePath = [imageBundle pathForResource:name ofType:@"png"];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        
        return image;
    }
}

@end
