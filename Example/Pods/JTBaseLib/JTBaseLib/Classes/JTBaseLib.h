//
//  JTBaseLib.h
//  JTBaseLib
//
//  Created by kenter on 2019/6/5.
//  Copyright © 2019 KENTER. All rights reserved.
//

#ifndef JTBaseLib_h
#define JTBaseLib_h

#import <Foundation/Foundation.h>

// 第三方库
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageDownloader.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <YYModel/YYModel.h>
#import <MJRefresh/MJRefresh.h>

// 配置参数
#include "JTBaseConfig.h"

// 工具类
#import "JTHttpTool.h"

// 类扩展
#import "NSString+JTExtension.h"
#import "NSDateFormatter+JTExtension.h"
#import "NSBundle+language.h"
#import "UIView+Frame.h"

// 管理类
#import "JTSettingManager.h"
#import "JTFileManager.h"
#import "JTFileManager.h"
#import "JTSmsCodeManager.h"
#import "JTLocalPushManager.h"
#import "JTLanguage.h"

// Base
#import "JTBaseViewController.h"
#import "JTBaseTableViewController.h"
#import "JTBaseNavigationController.h"
#import "JTBaseTabbarController.h"


#endif /* JTBaseLib_h */
