//
//  JTLanguage.h
//  JTMainProject
//
//  Created by kenter on 2019/7/1.
//  Copyright © 2019 KENTER. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JTLanguage : NSObject

// 获取字符串
+ (NSString * _Nullable)getString:(NSString * _Nonnull)key;

// 获取图片
+ (UIImage * _Nullable)getImage:(NSString * _Nonnull)imageName;


@end

NS_ASSUME_NONNULL_END
