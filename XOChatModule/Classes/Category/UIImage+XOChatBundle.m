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

+ (UIImage *)xo_1xImageNamed:(NSString *)name
{
    NSBundle *imageBundle = [XOChatClient shareClient].chatResourceBundle;
    NSString *imagePath = [imageBundle pathForResource:name ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    return image;
}

+ (UIImage *)xo_2xImageNamed:(NSString *)name
{
    NSBundle *imageBundle = [XOChatClient shareClient].chatResourceBundle;
    name = [name stringByAppendingString:@"@2x"];
    NSString *imagePath = [imageBundle pathForResource:name ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    return image;
}

+ (UIImage *)xo_3xImageNamed:(NSString *)name
{
    NSBundle *imageBundle = [XOChatClient shareClient].chatResourceBundle;
    name = [name stringByAppendingString:@"@3x"];
    NSString *imagePath = [imageBundle pathForResource:name ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    return image;
}

+ (UIImage *)xo_imageNamedFromChatBundle:(NSString *)name
{
    // 根据设备分辨率选择图片
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale >= 3.0) {
        // 取三倍图
        UIImage *image = [UIImage xo_3xImageNamed:name];
        
        if (nil == image) {
            // 没有三倍图, 取二倍图
            image = [UIImage xo_2xImageNamed:name];
            
            if (nil == image) {
                // 没有二倍图, 取一倍图
                image = [UIImage xo_1xImageNamed:name];
            }
        }
        
        return image;
    }
    else if (scale >= 2.0) {
        // 取二倍图
        UIImage *image = [UIImage xo_2xImageNamed:name];
        
        if (nil == image) {
            // 没有二倍图, 取一倍图
            image = [UIImage xo_1xImageNamed:name];
            
            if (nil == image) {
                // 没有一倍图, 取三倍图
                image = [UIImage xo_1xImageNamed:name];
            }
        }
        
        return image;
    }
    else {
        // 取一倍图
        UIImage *image = [UIImage xo_1xImageNamed:name];
        
        if (nil == image) {
            // 没有一倍图, 取二倍图
            image = [UIImage xo_2xImageNamed:name];
            
            if (nil == image) {
                // 没有二倍图, 取三倍图
                image = [UIImage xo_3xImageNamed:name];
            }
        }
        
        return image;
    }
}

@end
