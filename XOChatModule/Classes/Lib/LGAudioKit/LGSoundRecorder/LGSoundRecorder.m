//
//  LGSoundRecorder.m
//  下载地址：https://github.com/gang544043963/LGAudioKit
//
//  Created by ligang on 16/8/20.
//  Copyright © 2016年 LG. All rights reserved.
//

#import "LGSoundRecorder.h"
#import "UIImage+XOChatBundle.h"
#import "NSBundle+ChatModule.h"

#pragma clang diagnostic ignored "-Wdeprecated"

#define GetImage(imageName)  [UIImage xo_imageNamedFromChatBundle:imageName]

@interface LGSoundRecorder()

@property (nonatomic, strong) UIView *HUD;
@property (nonatomic, strong) NSString *recordPath;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSTimer *levelTimer;
//Views
@property (nonatomic, strong) UIImageView *imageViewAnimation;
@property (nonatomic, strong) UIImageView *talkPhone;
@property (nonatomic, strong) UIImageView *cancelTalk;
@property (nonatomic, strong) UIImageView *shotTime;
@property (nonatomic, strong) UILabel *textLable;
@property (nonatomic, strong) UILabel *countDownLabel;

@end

@implementation LGSoundRecorder


+ (LGSoundRecorder *)shareInstance {
	static LGSoundRecorder *sharedInstance = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		if (sharedInstance == nil) {
			sharedInstance = [[LGSoundRecorder alloc] init];
		}
	});
	return sharedInstance;
}

#pragma mark - Public Methods

- (void)startSoundRecord:(UIView *)view recordPath:(NSString *)path
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recordPath = path;
        [self initHUBViewWithView:view];
        [self startRecord];
    });
}

- (void)stopSoundRecord:(UIView *)view
{
    if (self.levelTimer) {
        [self.levelTimer invalidate];
        self.levelTimer = nil;
    }
    
    NSString *str = [NSString stringWithFormat:@"%f",_recorder.currentTime];
    
    int times = [str intValue];
    if (self.recorder) {
        [self.recorder stop];
    }
    if (times >= 1) {
        if (view == nil) {
            view = [[[UIApplication sharedApplication] windows] lastObject];
        }
        
        if ([view isKindOfClass:[UIWindow class]]) {
            [view addSubview:_HUD];
        } else {
            [view.window addSubview:_HUD];
        }
        if (_delegate&&[_delegate respondsToSelector:@selector(didStopSoundRecord)]) {
            [_delegate didStopSoundRecord];
        }
    } else {
        [self deleteRecord];
        [self.recorder stop];
        if ([_delegate respondsToSelector:@selector(showSoundRecordFailed)]) {
            [_delegate showSoundRecordFailed];
        }
    }
    [self removeHUD];
    //恢复外部正在播放的音乐
    [[AVAudioSession sharedInstance] setActive:NO
                                     withFlags:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
}

- (void)soundRecordFailed:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recorder stop];
        [self removeHUD];
        //恢复外部正在播放的音乐
        [[AVAudioSession sharedInstance] setActive:NO
                                         withFlags:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                             error:nil];
    });
}

- (void)readyCancelSound {
	_imageViewAnimation.hidden = YES;
	_talkPhone.hidden = YES;
	_cancelTalk.hidden = NO;
	_shotTime.hidden = YES;
	_countDownLabel.hidden = YES;

	_textLable.frame = CGRectMake(0, CGRectGetMaxY(_imageViewAnimation.frame) , 130, 45);
    _textLable.numberOfLines = 2;
	_textLable.text = XOChatLocalizedString(@"chat.keyboard.sound.release");
	_textLable.backgroundColor = [UIColor redColor];
	_textLable.layer.masksToBounds = YES;
	_textLable.layer.cornerRadius = 3;
}

- (void)resetNormalRecord {
	_imageViewAnimation.hidden = NO;
	_talkPhone.hidden = NO;
	_cancelTalk.hidden = YES;
	_shotTime.hidden = YES;
    _countDownLabel.hidden = YES;

	_textLable.frame = CGRectMake(0, CGRectGetMaxY(_imageViewAnimation.frame) , 130, 45);
	_textLable.text = XOChatLocalizedString(@"chat.keyboard.sound.slide");
	_textLable.backgroundColor = [UIColor clearColor];
}

- (void)showShotTimeSign:(UIView *)view {
	_imageViewAnimation.hidden = YES;
	_talkPhone.hidden = YES;
	_cancelTalk.hidden = YES;
	_shotTime.hidden = NO;
    _countDownLabel.hidden = YES;
	[_textLable setFrame:CGRectMake(0, 100, 130, 25)];
	_textLable.text = XOChatLocalizedString(@"chat.keyboard.sound.timeShort");
	_textLable.backgroundColor = [UIColor clearColor];
	
	[self performSelector:@selector(stopSoundRecord:) withObject:view afterDelay:1.f];
}

- (void)showCountdown:(int)countDown
{
	_textLable.text = [NSString stringWithFormat:XOChatLocalizedString(@"chat.keyboard.sound.time.left.%d"), countDown];
}

- (NSTimeInterval)soundRecordTime {
	return _recorder.currentTime;
}

#pragma mark - Private Methods

- (void)initHUBViewWithView:(UIView *)view
{
    if (_HUD) {
        [_HUD removeFromSuperview];
    }
    
    if (_HUD == nil) {
        CGFloat hubWidth = 180;
        CGFloat hubHeight = 160;
        CGFloat hubX = ([UIScreen mainScreen].bounds.size.width - hubWidth) / 2;
        CGFloat hubY = ([UIScreen mainScreen].bounds.size.height - hubHeight) / 2;
        CGFloat cvWidth = 130;
        CGFloat cvHeight = 120;
        CGFloat cvX = (hubWidth - cvWidth) / 2;
        CGFloat cvY = (hubHeight - cvHeight) / 2;
        
        _HUD = [[UIView alloc] initWithFrame:CGRectMake(hubX, hubY, hubWidth, hubHeight)];
        _HUD.backgroundColor = [[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:0.38];
        _HUD.layer.cornerRadius = 12;
        _HUD.layer.masksToBounds = true;
        
        CGFloat left = 22;
        CGFloat top = 0;
        top = 18;
        
        UIView *cv = [[UIView alloc] initWithFrame:CGRectMake(cvX, cvY, cvWidth, cvHeight)];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(left, top, 37, 70)];
        _talkPhone = imageView;
        _talkPhone.image = GetImage(@"toast_microphone");
        [cv addSubview:_talkPhone];
        left += CGRectGetWidth(_talkPhone.frame) + 16;
        
        top+=7;
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(left, top, 29, 64)];
        imageView.animationImages = @[GetImage(@"toast_vol_1"),
                                      GetImage(@"toast_vol_2"),
                                      GetImage(@"toast_vol_3"),
                                      GetImage(@"toast_vol_4"),
                                      GetImage(@"toast_vol_5"),
                                      GetImage(@"toast_vol_6"),
                                      GetImage(@"toast_vol_7")];
        imageView.animationDuration = 1.0f;
        _imageViewAnimation = imageView;
        [cv addSubview:_imageViewAnimation];
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(30, 24, 52, 61)];
        _cancelTalk = imageView;
        _cancelTalk.image = GetImage(@"toast_cancelsend");
        [cv addSubview:_cancelTalk];
        _cancelTalk.hidden = YES;
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(56, 24, 18, 60)];
        self.shotTime = imageView;
        _shotTime.image = GetImage(@"toast_timeshort");
        [cv addSubview:_shotTime];
        _shotTime.hidden = YES;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 14, 70, 71)];
        self.countDownLabel = label;
        self.countDownLabel.backgroundColor = [UIColor clearColor];
        self.countDownLabel.textColor = [UIColor whiteColor];
        self.countDownLabel.textAlignment = NSTextAlignmentCenter;
        self.countDownLabel.font = [UIFont systemFontOfSize:60.0];
        [cv addSubview:self.countDownLabel];
        self.countDownLabel.hidden = YES;
        
        left = -15;
        top += CGRectGetHeight(_imageViewAnimation.frame) + 20;
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(left, top, 160, 14)];
        self.textLable = label;
        _textLable.backgroundColor = [UIColor clearColor];
        _textLable.textColor = [UIColor whiteColor];
        _textLable.textAlignment = NSTextAlignmentCenter;
        _textLable.font = [UIFont systemFontOfSize:12.0];
        _textLable.text = XOChatLocalizedString(@"chat.keyboard.sound.slide");
        [cv addSubview:_textLable];
        
        [_HUD addSubview:cv];
    }
    [view addSubview:_HUD];
}

- (void)removeHUD {
	if (_HUD) {
		[_HUD removeFromSuperview];
		_HUD = nil;
	}
}

- (void)startRecord {
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	NSError *err = nil;
	//设置AVAudioSession
	[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
	if(err) {
		return;
	}
	
	//设置录音输入源
	UInt32 doChangeDefaultRoute = 1;
	AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof (doChangeDefaultRoute), &doChangeDefaultRoute);
	err = nil;
	[audioSession setActive:YES error:&err];
	if(err) {
		return;
	}
	//设置文件保存路径和名称
	NSString *fileName = [NSString stringWithFormat:@"voice_%lld.caf", (long long)[[NSDate date] timeIntervalSince1970] * 1000];
	self.recordPath = [self.recordPath stringByAppendingPathComponent:fileName];
	NSURL *recordedFile = [NSURL fileURLWithPath:self.recordPath];
	NSDictionary *dic = [self recordingSettings];
	//初始化AVAudioRecorder
	err = nil;
	_recorder = [[AVAudioRecorder alloc] initWithURL:recordedFile settings:dic error:&err];
	if(_recorder == nil) {
		return;
	}
	//准备和开始录音
	[_recorder prepareToRecord];
	self.recorder.meteringEnabled = YES;
	[self.recorder record];
	[_recorder recordForDuration:0];
	if (self.levelTimer) {
		[self.levelTimer invalidate];
		self.levelTimer = nil;
	}
	self.levelTimer = [NSTimer scheduledTimerWithTimeInterval: 0.0001 target: self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES];
}

- (void)deleteRecord {
	if (self.recorder) {
		[self.recorder stop];
		[self.recorder deleteRecording];
	}
	
	if (self.HUD) {
		[self.HUD removeFromSuperview];
	}
}

- (void)levelTimerCallback:(NSTimer *)timer {
	if (_recorder&&_imageViewAnimation) {
		[_recorder updateMeters];
		double ff = [_recorder averagePowerForChannel:0];
		ff = ff+60;
		if (ff>0&&ff<=10) {
			[_imageViewAnimation setImage:GetImage(@"toast_vol_0")];
		} else if (ff>10 && ff<20) {
			[_imageViewAnimation setImage:GetImage(@"toast_vol_1")];
		} else if (ff >=20 &&ff<30) {
			[_imageViewAnimation setImage:GetImage(@"toast_vol_2")];
		} else if (ff >=30 &&ff<40) {
			[_imageViewAnimation setImage:GetImage(@"toast_vol_3")];
		} else if (ff >=40 &&ff<50) {
			[_imageViewAnimation setImage:GetImage(@"toast_vol_4")];
		} else if (ff >= 50 && ff < 60) {
			[_imageViewAnimation setImage:GetImage(@"toast_vol_5")];
		} else if (ff >= 60 && ff < 70) {
			[_imageViewAnimation setImage:GetImage(@"toast_vol_6")];
		} else {
			[_imageViewAnimation setImage:GetImage(@"toast_vol_7")];
		}
	}
}

#pragma mark - Getters

- (NSDictionary *)recordingSettings
{
	NSMutableDictionary *recordSetting =[NSMutableDictionary dictionaryWithCapacity:10];
    //1 采样率
    [recordSetting setObject:[NSNumber numberWithFloat:16000.0] forKey: AVSampleRateKey];
    //2 采样率
    [recordSetting setObject:[NSNumber numberWithInteger:16000] forKey: AVEncoderBitRateKey];
    //3 音频格式
    [recordSetting setObject:[NSNumber numberWithInteger:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //4 通道的数目
    [recordSetting setObject:[NSNumber numberWithInteger:1] forKey:AVNumberOfChannelsKey];
    //5 采样位数  默认 16
    [recordSetting setObject:[NSNumber numberWithInteger:16] forKey:AVLinearPCMBitDepthKey];
    //6 录音质量
    [recordSetting setObject:[NSNumber numberWithInteger:AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    
	return recordSetting;
}

- (NSString *)soundFilePath {
	return self.recordPath;
}


@end

