//
//  JTFileManager.h
//  JTMainProject
//
//  Created by kenter on 2019/7/1.
//  Copyright © 2019 KENTER. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///////////////////////////////////////////////////////////////////
/////////////////////////// app文件管理器 ///////////////////////////
///////////////////////////////////////////////////////////////////


#define JTFM [NSFileManager defaultManager]


// 沙盒Document路径
static inline NSString *DocumentDirectory() {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

// 沙盒Library路径
static inline NSString *LibraryDirectory() {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
}

// 用户设置文件路径
static inline NSString * JTFileUserSettingPath() {
    NSString *path = @"/user/setting";
    NSString *userSettingPath = [DocumentDirectory() stringByAppendingPathComponent:path];
    // 判断目录是否存在，不存在就创建目录
    BOOL isDirectory = NO;
    BOOL isExist = [JTFM fileExistsAtPath:userSettingPath isDirectory:&isDirectory];
    if (!(isDirectory && isExist)) {
        NSError *error = nil;
        BOOL isCreate = [JTFM createDirectoryAtPath:userSettingPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!isCreate) {
            NSLog(@"文件路径创建失败: %@", userSettingPath);
        }
    }
    // 用户设置文件名
    NSString *settingFile = @"JTUserSetting.plist";
    userSettingPath = [userSettingPath stringByAppendingPathComponent:settingFile];

    return userSettingPath;
}

// 系统设置文件路径
static inline NSString *JTFileDefaultSettingPath() {
    return  [[NSBundle mainBundle] pathForResource:@"JTDefaultSetting" ofType:@"plist"];
}

@interface JTFileManager : NSObject

@end

NS_ASSUME_NONNULL_END
