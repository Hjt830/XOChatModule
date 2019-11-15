//
//  UIImage+XOChatExtension.h
//  AFNetworking
//
//  Created by kenter on 2019/9/25.
//

#import <UIKit/UIKit.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (XOChatExtension)

- (UIImage *)XO_imageWithTintColor:(UIColor *)tintColor;

- (UIImage *)XO_imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode;

+ (void)combineGroupImageWithGroupId:(NSString * _Nonnull)groupId complection:(void(^)(UIImage *image))complectionHandler;

+ (UIImage *)groupDefaultImageAvatar;


@end

NS_ASSUME_NONNULL_END
