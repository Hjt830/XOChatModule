//
//  UIImage+XOChatExtension.m
//  AFNetworking
//
//  Created by kenter on 2019/9/25.
//

#import "UIImage+XOChatExtension.h"
#import <SDWebImage/SDWebImage.h>
#import <XOBaseLib/XOBaseLib.h>
#import "UIImage+XOChatBundle.h"
#include <math.h>

@implementation UIImage (XOChatExtension)

- (UIImage *)XO_imageWithTintColor:(UIColor *)tintColor
{
    return [self XO_imageWithTintColor:tintColor blendMode:kCGBlendModeDestinationIn];
}

- (UIImage *)XO_imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode
{
    //We want to keep alpha, set opaque to NO; Use 0.0f for scale to use the scale factor of the device’s main screen.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    
    //Draw the tinted image in context
    [self drawInRect:bounds blendMode:blendMode alpha:1.0f];
    
    if (blendMode != kCGBlendModeDestinationIn) {
        [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    }
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

+ (void)combineGroupImageWithGroupId:(NSString * _Nonnull)groupId complection:(void(^)(UIImage *image))complectionHandler
{
    __block UIImage *groupImage = nil;
    BOOL isCache = NO;
    // 从缓存中取
    if (!XOIsEmptyString(groupId)) {
        groupImage = [[SDImageCache sharedImageCache] imageFromCacheForKey:groupId];
        if (groupImage) {
            isCache = YES;
        } else {
            isCache = NO;
        }
    }
    
    if (isCache) {
        if (complectionHandler) {
            complectionHandler (groupImage);
        }
    }
    else {
        // 获取群成员ID
        [[TIMGroupManager sharedInstance] getGroupMembers:groupId succ:^(NSArray <TIMGroupMemberInfo *>* members) {
            
            __block NSMutableArray *memberList = [NSMutableArray arrayWithCapacity:1];
            [members enumerateObjectsUsingBlock:^(TIMGroupMemberInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!XOIsEmptyString(obj.member)) {
                    [memberList addObject:obj.member];
                }
            }];
            
            // 获取群成员资料
            [[TIMFriendshipManager sharedInstance] getUsersProfile:memberList forceUpdate:YES succ:^(NSArray<TIMUserProfile *> *profiles) {
                
                __block NSMutableArray <UIImage *>* avatarList = [NSMutableArray arrayWithCapacity:1];
                [profiles enumerateObjectsUsingBlock:^(TIMUserProfile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    // 最多合成4张图片
                    if (idx < 4) {
                        if (!XOIsEmptyString(obj.faceURL)) {
                            [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:obj.faceURL] completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                                
                                if (image) {
                                    image = [image circleImage];
                                    if (avatarList.count > idx) {
                                        [avatarList insertObject:image atIndex:idx];
                                    } else {
                                        [avatarList addObject:image];
                                    }
                                }
                                else {
                                    UIImage *defaultImage = [[UIImage xo_imageNamedFromChatBundle:@"default_avatar"] circleImage];
                                    if (avatarList.count > idx) {
                                        [avatarList insertObject:defaultImage atIndex:idx];
                                    } else {
                                        [avatarList addObject:defaultImage];
                                    }
                                }
                                
                                if ((profiles.count <= 4 && avatarList.count == profiles.count) || (profiles.count > 4 && avatarList.count == 4)) {
                                    if (complectionHandler) {
                                        UIImage *combineImage = [self combineImageWith:avatarList];
                                        complectionHandler (combineImage);
                                        
                                        dispatch_async(dispatch_get_global_queue(0, 0), ^{
                                            [[SDImageCache sharedImageCache] storeImageToMemory:combineImage forKey:groupId];
                                            NSData *imageData = UIImagePNGRepresentation(combineImage);
                                            [[SDImageCache sharedImageCache] storeImageDataToDisk:imageData forKey:groupId];
                                        });
                                    }
                                }
                            }];
                        }
                        else {
                            UIImage *defaultImage = [[UIImage xo_imageNamedFromChatBundle:@"default_avatar"] circleImage];
                            [avatarList addObject:defaultImage];
                            
                            if ((profiles.count < 9 && avatarList.count == profiles.count) || (profiles.count > 9 && avatarList.count == 9)) {
                                if (complectionHandler) {
                                    UIImage *combineImage = [self combineImageWith:avatarList];
                                    complectionHandler (combineImage);
                                }
                            }
                        }
                    }
                    else {
                        *stop = YES;
                    }
                }];
                
                
            } fail:^(int code, NSString *msg) {
                // 获取失败， 默认合成4张默认的图片返回
                if (complectionHandler) {
                    groupImage = [self groupDefaultImageAvatar];
                    complectionHandler (groupImage);
                }
            }];
            
        } fail:^(int code, NSString *msg) {
            
            // 获取失败， 默认合成4张默认的图片返回
            if (complectionHandler) {
                groupImage = [self groupDefaultImageAvatar];
                complectionHandler (groupImage);
            }
        }];
    }
}

// 合成群头像
+ (UIImage *)combineImageWith:(NSArray <UIImage *>*)imageList
{
    CGFloat R = 100.0;  // 大圆半径
    CGSize canvasSize = CGSizeMake(R * 2, R * 2); // 画布大小
    int count = (int)imageList.count;    // 小圆个数
    double r = 0.0f;                // 小圆半径
    
    UIGraphicsBeginImageContext(canvasSize);
    
    if (count == 2) {
        r = R/2.0;
    } else if (count == 3) {
        r = 0.0f;
    } else {
        r = R/(1.0 + sqrt(2.0));
    }
    NSLog(@"r: %f", r);
    
    for (int i = 0; i < count; i++) {
        UIImage *image = [imageList[i] circleImage];
        CGRect rect = CGRectZero;
        
        if (count == 2) {
            r = R/2.0;
            if (0 == i) {
                rect = CGRectMake(0, r, r, r);
            }
            else if (1 == i) {
                rect = CGRectMake(R, r, r, r);
            }
        }
        else if (count == 3) {
            r = R / (1.0 + 2.0 * sqrt(3.0)/3.0);
            if (i == 0) {
                rect = CGRectMake(R - 2 * r, R - r - r * (sqrt(3.0)/3.0), 2 * r, 2 * r);
            } else if (i == 1) {
                rect = CGRectMake(R, R - r - r * (sqrt(3.0)/3.0), 2 * r, 2 * r);
            } else if (i == 2) {
                rect = CGRectMake(R - r, 2 * R - 2 * r, 2 * r, 2 * r);
            }
        }
        else {
            r = R/(1.0 + sqrt(2.0));
            if (i == 0) {
                rect = CGRectMake(R - r, 0, 2 * r, 2 * r);
            } else if (i == 1) {
                rect = CGRectMake(0, R - r, 2 * r, 2 * r);
            } else if (i == 2) {
                rect = CGRectMake(2 * R - 2 * r, R - r, 2 * r, 2 * r);
            } else if (i == 3) {
                rect = CGRectMake(R - r, 2 * R - 2 * r, 2 * r, 2 * r);
            }
        }
        [image drawInRect:rect];
    }
    UIImage *combineImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return combineImage;
}

// 合成4张默认图片
+ (UIImage *)groupDefaultImageAvatar
{
    CGFloat R = 100.0;  // 大圆半径
    CGSize canvasSize = CGSizeMake(R * 2, R * 2); // 画布大小
    int count = 4;  // 小圆个数
    double r = R/(1.0 + sqrt(2.0)); // 小圆半径
    
    UIImage *image = [[UIImage xo_imageNamedFromChatBundle:@"default_avatar"] circleImage];
    
    UIGraphicsBeginImageContext(canvasSize);
    for (int i = 0; i < count; i++) {
        CGRect rect = CGRectZero;
        if (i == 0) {
            rect = CGRectMake(R - r, 0, 2 * r, 2 * r);
        } else if (i == 1) {
            rect = CGRectMake(0, R - r, 2 * r, 2 * r);
        } else if (i == 2) {
            rect = CGRectMake(2 * R - 2 * r, R - r, 2 * r, 2 * r);
        } else if (i == 3) {
            rect = CGRectMake(R - r, 2 * R - 2 * r, 2 * r, 2 * r);
        }
        [image drawInRect:rect];
    }
    UIImage *combineImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return combineImage;
}

- (UIImage *)circleImage
{
    // 开始图形上下文，NO代表透明
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0);
    // 获得图形上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // 设置一个范围
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    // 根据一个rect创建一个椭圆
    CGContextAddEllipseInRect(ctx, rect);
    // 裁剪
    CGContextClip(ctx);
    // 将原照片画到图形上下文
    [self drawInRect:rect];
    // 从上下文上获取剪裁后的照片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    // 关闭上下文
    UIGraphicsEndImageContext();

    return newImage;
}

+ (UIImage *)XO_imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end
