//
//  CommonTool.h
//  WXChatProject
//
//  Created by 乐派 on 2019/2/22.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <CommonCrypto/CommonDigest.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger,DataType) {
    DataTypeRole =0,
    DataTypeTeam,
    DataTypeBigRegion,
    DataTypeActivity,
};

@interface CommonTool : NSObject

/**
 *  生成UUID
 */
+ (NSString *_Nullable)creatUUID;

// 设置边框&圆角
+ (void)setViewlayer:(UIView *)view cornerRadius:(CGFloat)cornerRadius borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor;
// 设置虚线边框（需先设定size）
+ (void)setViewlayer:(UIView *)view borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor;
// MD5加密
+ (NSString *)Newmd5:(NSString *)inPutText;

// 时间戳解析
typedef NS_ENUM(NSInteger, TimeLevel){
    years = 0,
    months = 1,
    days = 2,
    hours = 3,
    minutes = 4,
    seconds = 5
};

+ (NSString *)timeTransform:(int)time time:(TimeLevel)timeLevel;

// date转时间戳
//+ (NSInteger)timeTransformTimestamp:(NSDate *)date;

// 时间戳倒数天数
+ (NSString *)remainTime:(int)time;

+ (NSString *)getCurrentTime;

// 手机正则判断
+ (BOOL)validateMobile:(NSString *)mobile;

// 密码正则判断
+ (BOOL)validatePassword:(NSString *)passWord;

// 邮箱
+ (BOOL)validateEmail:(NSString *)email;

// 中文正则判断
+ (BOOL)ValidChineseString:(NSString *)string;

// 过滤emoji表情
+ (NSString *)stringContainsEmoji:(NSString *)string;

// 动态高度
+ (CGSize)countingSize:(NSString *)str fontSize:(int)fontSize width:(float)width;

// 动态宽度
+ (CGSize)countingSize:(NSString *)str fontSize:(int)fontSize height:(float)height;

// 生成纯色图片
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

// 按尺寸缩小图片
+ (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize sourceImage:(UIImage * _Nonnull)sourceImage;

// 毛玻璃效果
+ (UIImage *_Nullable)blurryImage:(UIImage *_Nonnull)image withBlurLevel:(CGFloat)blur;

// 十六进制颜色
+ (UIColor *_Nullable)colorWithHexString: (NSString *_Nonnull)color;

// 常规按钮
+ (void)commonWithButton:(UIButton *_Nonnull)btn
                    font:(UIFont *_Nullable)font
                   title:(NSString *_Nullable)title
           selectedTitle:(NSString *_Nullable)selectedTitle
              titleColor:(UIColor *_Nullable)titleColor
      selectedtitleColor:(UIColor *_Nullable)selectedtitleColor
           backgroundImg:(UIImage *_Nullable)backgroundImg
   selectedBackgroundImg:(UIImage *_Nullable)selectedBackgroundImg
                  target:(id _Nullable)target
                  action:(SEL _Nullable)action;

// 把字符串转成字典
+ (NSDictionary *_Nullable)stringToDictionaryWithString:(NSString *_Nonnull)string;

// 把字典转成字符串
+ (NSString *_Nullable)dictionaryToStringWithDictionary:(NSDictionary *_Nonnull)dic;

// 返回当前手机内文件目录
+ (NSString *_Nullable)exchangeNowDocumentFilePath:(NSString *_Nonnull)oldFilePath;

+ (BOOL)ValidCharString:(NSString *_Nonnull)string;


+ (CGSize)sizeWithString:(NSString *_Nonnull)string
                    font:(UIFont *_Nonnull)font
             withMaxSize:(CGSize)maxSize;
+ (BOOL)isNilString:(NSString *_Nonnull)string;

// 处理所有的共有id和名称,
// 返回为二维数组，第一个元素表示所有的ids，第二个元素表示所有的names
//+ (NSArray *_Nullable)getIdsAndNamesByType:(DataType)aDataType;
//+ (NSString *_Nullable)fetchNameById:(NSString *_Nonnull)aId byType:(DataType)aDataType;
//+ (NSString *_Nullable)fetchIdByName:(NSString *_Nonnull)aName byType:(DataType)aDataType;

+ (NSString *_Nullable)passCity:(NSString *_Nullable)city andProvince:(NSString *_Nullable)province;

+ (NSString *_Nullable)formateDate:(NSString *_Nonnull)dateString withFormate:(NSString *_Nonnull) formate WithServiceTime:(NSString *_Nonnull)serviceTimeStr;

/**
 *  判断对象是否为空
 *  PS：nil、NSNil、@""、@0 以上4种返回YES
 *
 *  @return YES 为空  NO 为实例对象
 */
+ (BOOL)ht_isNullOrNilWithObject:(id _Nullable)object;

@end

NS_ASSUME_NONNULL_END
