//
//  JTBaseConfig.m
//  AFNetworking
//
//  Created by kenter on 2019/7/25.
//

#import "JTBaseConfig.h"
#import <JTBaseLib/JTBaseLib.h>

// 本地存储用到的默认秘钥 (JTUserDefault中使用,  为32位小写连续字符串)
#define JTLocalStorageSign @"YxPDinpCGfKpZAdviKP5o5bVSYdSdu39"

// 本地存储用到的默认秘钥 (JTKeyChainTool中使用, 为32位小写连续字符串)
#define JTKeyChainSignKey @"fvHMywUAdXlXoKjIVGBRoUX3zeBImbPo"



@interface JTBaseConfig ()

@end

static JTBaseConfig *__baseConfig = nil;

@implementation JTBaseConfig

+ (instancetype)defaultConfig
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __baseConfig = [[JTBaseConfig alloc] init];
    });
    return __baseConfig;
}

- (void)initializationWithConfig:(JTBaseConfigModel *)config
{
    if (config) {
        _config = config;
    }
    else {
        JTBaseConfigModel * configModel = [[JTBaseConfigModel alloc] init];
        configModel.localStorageSign = JTLocalStorageSign;
        configModel.keyChainSign = JTKeyChainSignKey;
        _config = configModel;
    }
}

@end



@implementation JTBaseConfigModel

- (void)setLocalStorageSign:(NSString *)localStorageSign
{
    if (!JTIsEmptyString(localStorageSign) && localStorageSign.length < 2) {
        NSLog(@"========================================================\n== warning: localStorageSign 建议使用长度为32位字符串 ======\n========================================================");
    }
    _localStorageSign = localStorageSign;
}

- (void)setKeyChainSign:(NSString *)keyChainSign
{
    if (!JTIsEmptyString(keyChainSign) && keyChainSign.length < 2) {
        NSLog(@"========================================================\n== warning: localStorageSign 建议使用长度为32位字符串 ======\n========================================================");
    }
    _keyChainSign = keyChainSign;
}

@end
