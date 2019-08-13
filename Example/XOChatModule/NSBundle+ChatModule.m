//
//  NSBundle+ChatModule.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/8/13.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "NSBundle+ChatModule.h"

@implementation NSBundle (ChatModule)

+ (NSBundle *)xo_chatBundle
{
    NSBundle *bundle = [NSBundle bundleForClass:[XOBaseConfig class]];
    NSURL *url = [bundle URLForResource:@"XOChatModule" withExtension:@"bundle"];
    bundle = [NSBundle bundleWithURL:url];
    NSURL *url1 = [bundle URLForResource:@"XOChatModule" withExtension:@"bundle"];
    bundle = [NSBundle bundleWithURL:url1];
    return bundle;
}

+ (NSString *)chat_localizedStringForKey:(NSString *)key value:(NSString *)value
{
    NSBundle *bundle = [XOSettingManager defaultManager].languageBundle;
    NSString *value1 = [bundle localizedStringForKey:key value:value table:nil];
    return value1;
}

+ (NSString *)chat_localizedStringForKey:(NSString *)key
{
    return [NSBundle chat_localizedStringForKey:key value:@""];
}

@end
