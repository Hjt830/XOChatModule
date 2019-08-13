//
//  WXAudioRecorder.h
//  WXMainProject
//
//  Created by 乐派 on 2019/4/30.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WXAudioRecorder : NSObject

+ (instancetype _Nonnull)shareRecorder;

- (void)startRecordAudio:(UIView *)view;

- (void)stopRecordAudio:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
