//
//  WXAudioRecorder.m
//  WXMainProject
//
//  Created by 乐派 on 2019/4/30.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXAudioRecorder.h"
// 录音
#import <XOBaseLib/XOBaseLib.h>
#import "LGAudioKit.h"

static WXAudioRecorder *__recorder = nil;

@interface WXAudioRecorder ()
{
    dispatch_source_t   _timer;     // 定时器
    int                 _seconds;   // 时间
}

@end

@implementation WXAudioRecorder

+ (instancetype _Nonnull)shareRecorder
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __recorder = [[WXAudioRecorder alloc] init];
    });
    return __recorder;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _seconds = 0;
        // 创建一个定时器(dispatch_source_t本质还是个OC对象)
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        // 设置定时器的各种属性
        dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)); // 启动时间比当前晚0.0秒，即马上启动
        uint64_t interval = (uint64_t)(1.0 * NSEC_PER_SEC); // 执行间隔时间
        dispatch_source_set_timer(_timer, start, interval, 0);
        // 设置事件回调
        dispatch_source_set_event_handler(_timer, ^{
            self->_seconds++;
            
            if (self->_seconds == 60) {
                // 结束定时器
                dispatch_source_cancel(self->_timer);
                // 重置时间
                self->_seconds = 0;
            }
            else if (self->_seconds >= 50) {
                
            }
        });
    }
    return self;
}

- (void)startRecordAudio:(UIView *)view
{
    //停止播放录音
    [[LGAudioPlayer sharePlayer] stopAudioPlayer];
    //开始录音
    NSString *audioPath = [DocumentDirectory() stringByAppendingPathComponent:XOMsgFileDirectory(XOMsgFileTypeAudio)];
    [[LGSoundRecorder shareInstance] startSoundRecord:view recordPath:audioPath];
    //开启定时器
    self->_seconds = 0;
    dispatch_resume(self->_timer);
}

- (void)stopRecordAudio:(UIView *)view
{
    [[LGSoundRecorder shareInstance] stopSoundRecord:view];
}

@end
