//
//  NSBundle+JTBaseLib.h.m
//  JTMainProject
//
//  Created by kenter on 2019/7/27.
//  Copyright © 2019 KENTER. All rights reserved.
//

#import "NSBundle+JTBaseLib.h"
#import <JTBaseLib/JTBaseLib.h>

@implementation NSBundle (JTBaseLib)

+ (NSBundle *)jt_baseLibBundle
{
    NSBundle *bundle = [NSBundle bundleForClass:[JTBaseConfig class]];
    NSURL *url = [bundle URLForResource:@"JTBaseLib" withExtension:@"bundle"];
    bundle = [NSBundle bundleWithURL:url];
    NSURL *url1 = [bundle URLForResource:@"JTBaseLib" withExtension:@"bundle"];
    bundle = [NSBundle bundleWithURL:url1];
    return bundle;
}

+ (NSString *)jt_localizedStringForKey:(NSString *)key value:(NSString *)value
{
    NSBundle *bundle = [JTSettingManager defaultManager].languageBundle;
    NSString *value1 = [bundle localizedStringForKey:key value:value table:nil];
    return value1;
}

+ (NSString *)jt_localizedStringForKey:(NSString *)key
{
    return [NSBundle jt_localizedStringForKey:key value:@""];
}


@end
