//
//  NSDateFormatter+JTExtension.m
//  JTMainProject
//
//  Created by kenter on 2019/6/29.
//  Copyright © 2019 KENTER. All rights reserved.
//

#import "NSDateFormatter+JTExtension.h"

@implementation NSDateFormatter (JTExtension)

+ (instancetype)dateFormatter
{
    return [[self alloc] init];
}

+ (instancetype)dateFormatterWithFormat:(NSString *)dateFormat
{
    NSDateFormatter *dateFormatter = [[self alloc] init];
    dateFormatter.dateFormat = dateFormat;
    return dateFormatter;
}

+ (instancetype)defaultDateFormatter
{
    return [NSDateFormatter dateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss"];
}

@end
