//
//  UIImage+XOChatBundle.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/8/14.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (XOChatBundle)

// 读取资源包图片
+ (UIImage *)xo_imageNamedFromChatBundle:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
