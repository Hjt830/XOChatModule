//
//  ConvertWavToMp3.h
//  HTMessage
//
//  Created by 乐派 on 2019/1/28.
//  Copyright © 2019年 LePai ShenZhen Technology Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConvertWavToMp3 : NSObject

/**
 * 将caf格式的音频转为mp3格式
 * mp3Path 转码后的的mp3文件保存的地址
 * cafPath caf文件地址
 */
+ (BOOL)convertToMp3WithSavePath:(NSString*)mp3Path sourcePath:(NSString *)cafPath;

@end

NS_ASSUME_NONNULL_END
