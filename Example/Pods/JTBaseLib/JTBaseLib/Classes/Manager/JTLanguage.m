//
//  JTLanguage.m
//  JTMainProject
//
//  Created by kenter on 2019/7/1.
//  Copyright © 2019 KENTER. All rights reserved.
//

#import "JTLanguage.h"
#import "JTSettingManager.h"

@interface JTLanguage ()

@end

@implementation JTLanguage

// 获取语言
+ (NSString *)getString:(NSString * _Nonnull)key
{
    // 先获取JTBaseLib的资源包
    NSString *bundlePath = [[NSBundle bundleForClass:[JTLanguage class]] pathForResource:@"JTBaseLib" ofType:@"bundle"];
    NSBundle *baseLibBundle = [NSBundle bundleWithPath:bundlePath];
    // 再获取当前语言的资源包
    NSString *language = [[JTSettingManager defaultManager] language];
    NSString *languageBundlePath = nil;
    // 中文简体
    if ([language hasPrefix:JTLanguageNameZh_Hans]) {
        languageBundlePath = [baseLibBundle pathForResource:@"zh-Hans" ofType:@"lproj"];
    }
    // 中文繁体
    else if ([language hasPrefix:JTLanguageNameZh_Hant]) {
        languageBundlePath = [baseLibBundle pathForResource:@"zh-Hant" ofType:@"lproj"];
    }
    // 英文
    else {
        languageBundlePath = [baseLibBundle pathForResource:@"en" ofType:@"lproj"];
    }
    NSBundle *languageBundle = [NSBundle bundleWithPath:languageBundlePath];
    
    return NSLocalizedStringFromTableInBundle(key, nil, languageBundle, @"");
}

// 获取图片
+ (UIImage * _Nullable)getImage:(NSString * _Nonnull)imageName
{
    NSString *bundlePath = [[NSBundle bundleForClass:[JTLanguage class]] pathForResource:@"JTBaseLib" ofType:@"bundle"];
    NSBundle *baseLibBundle = [NSBundle bundleWithPath:bundlePath];
    NSString *imagePath = [baseLibBundle pathForResource:@"btn_back" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    return image;
}

@end
