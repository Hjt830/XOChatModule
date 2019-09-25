//
//  UIImage+XOChatExtension.h
//  AFNetworking
//
//  Created by kenter on 2019/9/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (XOChatExtension)

- (UIImage *)imageWithTintColor:(UIColor *)tintColor;

- (UIImage *)imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode;

@end

NS_ASSUME_NONNULL_END
