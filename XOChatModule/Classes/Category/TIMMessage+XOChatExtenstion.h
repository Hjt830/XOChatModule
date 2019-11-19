//
//  TIMMessage+XOChatExtenstion.h
//  AFNetworking
//
//  Created by kenter on 2019/11/19.
//

#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface TIMMessage (XOChatExtenstion)

- (NSString *)getThumbImageName;
- (NSString *)getThumbImagePath;

- (NSString *)getImageName;
- (NSString *)getImagePath;

- (NSString *)getVideoName;
- (NSString *)getVideoPath;

- (NSString *)getSoundPath;

- (NSString *)getFilePath;

@end

NS_ASSUME_NONNULL_END
