//
//  NSDateFormatter+JTExtension.h
//  JTMainProject
//
//  Created by kenter on 2019/6/29.
//  Copyright © 2019 KENTER. All rights reserved.
//



NS_ASSUME_NONNULL_BEGIN

@interface NSDateFormatter (JTExtension)

+ (instancetype)dateFormatter;

+ (instancetype)dateFormatterWithFormat:(NSString *)dateFormat;

+ (instancetype)defaultDateFormatter;/*yyyy-MM-dd HH:mm:ss*/

@end

NS_ASSUME_NONNULL_END
