//
//  TIMMessage+XOChatExtenstion.h
//  AFNetworking
//
//  Created by kenter on 2019/11/19.
//

#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface TIMMessage (XOChatExtenstion)

- (NSString * _Nullable)getThumbImageName;
- (NSString * _Nullable)getThumbImagePath;

- (NSString * _Nullable)getImageName;
- (NSString * _Nullable)getImagePath;

- (NSString * _Nullable)getVideoName;
- (NSString * _Nullable)getVideoPath;

- (NSString * _Nullable)getSoundPath;

- (NSString * _Nullable)getFilePath;

@end

NS_ASSUME_NONNULL_END
