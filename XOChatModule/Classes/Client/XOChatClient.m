//
//  XOChatClient.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/5.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOChatClient.h"
#import <GCDMulticastDelegate/GCDMulticastDelegate.h>
#import <XOBaseLib/XOBaseLib.h>
#import "NSBundle+ChatModule.h"
#import "XOContactManager.h"

@interface XOChatClient () <TIMConnListener, TIMMessageListener, TIMUserStatusListener, TIMUploadProgressListener, TIMGroupEventListener, TIMFriendshipListener>
{
    GCDMulticastDelegate    <XOChatClientProtocol> *_multiDelegate;
}
@property (nonatomic, strong) NSThread                      *bgThread;     // 后台常驻线程，用于下载图片、视频、文件等消息中的文件
@property (nonatomic, strong) NSMutableArray <TIMMessage *> *waitTaskQueue; // 待下载任务
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSURLSessionTask *> *taskQueue;    // 任务队列 key:消息ID+消息时间(msgId_timestamp) 下载任务:task

@end

static int MaxDownloadCount = 6; // 最大并发下载任务数
static NSString * const XOChatClientBackgroundThreadName = @"XOChatClientBackgroundThreadName";
static XOChatClient *__chatClient = nil;

@implementation XOChatClient

+ (instancetype)shareClient
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __chatClient = [[XOChatClient alloc] init];
    });
    return __chatClient;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _chatBundle = [NSBundle xo_chatBundle];
        _chatResourceBundle = [NSBundle xo_chatResourceBundle];
        
        NSString *language = [XOSettingManager defaultManager].language;
        NSString *languagePath = [_chatResourceBundle pathForResource:language ofType:@"lproj"];
        _languageBundle = [NSBundle bundleWithPath:languagePath];
        _conversationManager = [XOConversationManager defaultManager];
        _messageManager = [XOMessageManager defaultManager];
        _multiDelegate = (GCDMulticastDelegate <XOChatClientProtocol> *)[[GCDMulticastDelegate alloc] init];
        
        // 开启后台常驻线程
        [self startBackgroundThread];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageDidChange) name:XOLanguageDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    if (_multiDelegate) {
        [_multiDelegate removeAllDelegates];
    }
    [[TIMManager sharedInstance] removeMessageListener:self];
}

#pragma mark ========================= language =========================

- (void)languageDidChange
{
    NSString *language = [XOSettingManager defaultManager].language;
    NSString *languagePath = [_chatResourceBundle pathForResource:language ofType:@"lproj"];
    _languageBundle = [NSBundle bundleWithPath:languagePath];
}

#pragma mark ========================= SDK init & login =========================

/** @brief 初始化腾讯云 （在Appdelegate中初始化腾讯云）
 *  @param AppID 在腾讯云注册的APPID
 *  @param logFunc 云通信的日志回调函数, 仅在DEBUG时会回调
 */
- (void)initSDKWithAppId:(int)AppID logFun:(TIMLogFunc _Nullable)logFunc
{
    TIMSdkConfig *config = [[TIMSdkConfig alloc] init];
    config.sdkAppId = AppID;
    config.connListener = self;
#if DEBUG
    config.disableLogPrint = NO;
    config.logLevel = TIM_LOG_WARN;
    config.logFunc = logFunc;
#else
    config.disableLogPrint = YES;
    config.logLevel = TIM_LOG_NONE;
#endif
    [[TIMManager sharedInstance] initSdk:config];
    
    TIMUserConfig *userConfig = [[TIMUserConfig alloc] init];
    userConfig.enableReadReceipt  = YES;
    userConfig.disableAutoReport = NO;
    userConfig.groupInfoOpt = [[TIMGroupInfoOption alloc] init];
    userConfig.groupMemberInfoOpt = [[TIMGroupMemberInfoOption alloc] init];
    userConfig.friendProfileOpt = [[TIMFriendProfileOption alloc] init];
    
    userConfig.userStatusListener = self;
    userConfig.refreshListener = _conversationManager;
    userConfig.messageReceiptListener = _messageManager;
    userConfig.messageUpdateListener = _messageManager;
    userConfig.messageRevokeListener = _messageManager;
    userConfig.uploadProgressListener = self;
    userConfig.groupEventListener = _messageManager;
    userConfig.friendshipListener = _contactManager;
    
    [[TIMManager sharedInstance] setUserConfig:userConfig];
    
    [[TIMManager sharedInstance] addMessageListener:self];
}

/** @brief 登录腾讯云IM
 *  @param success 登录成功的回调
 *  @param fail 登录失败的回调
 */
- (void)loginWith:(TIMLoginParam * _Nonnull)param successBlock:(TIMLoginSucc _Nullable)success failBlock:(TIMFail _Nullable)fail
{
    [[TIMManager sharedInstance] login:param succ:^{
        
        NSLog(@"=================================");
        NSLog(@"========== 腾讯云登录成功 =========");
        NSLog(@"=================================\n");
        
        if (success) {success();}
        
        // 获取好友列表
        [[XOContactManager defaultManager] asyncFriendList];
        
        // 获取群列表
        [[XOContactManager defaultManager] asyncGroupList];
        
    } fail:^(int code, NSString *msg) {
        
        NSLog(@"=================================");
        NSLog(@"====== 腾讯云登录失败 code: %d  msg: %@ ======", code, msg);
        NSLog(@"=================================\n");
        
        if (fail) {fail(code, msg);}
        
        
        // 初始化存储 仅查看历史消息时使用
        [[TIMManager sharedInstance] initStorage:param succ:^{
            
            NSLog(@"初始化存储, 可查看历史消息");
            
        } fail:^(int code, NSString *msg) {
            
            NSLog(@"初始化存储失败, 不可查看历史消息");
        }];
    }];
}

#pragma mark ========================= TIMMessageListener =========================
/**
 *  新消息回调通知
 *
 *  @param msgs 新消息列表，TIMMessage 类型数组
 */
- (void)onNewMessage:(NSArray *)msgs
{
    XOLog(@"=================================\n=================================\n收到新消息条数: %lu \n收到新消息: %@\n=================================\n=================================", (unsigned long)msgs.count, msgs);
    // 开启下载任务
    [msgs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[TIMMessage class]]) {
            [self ScheduleDownloadTask:(TIMMessage *)obj];
        }
    }];
    
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnForceOffline)]) {
        [_multiDelegate xoOnNewMessage:msgs];
    }
}

#pragma mark ========================= TIMUserStatusListener =========================
/**
 *  踢下线通知
 */
- (void)onForceOffline
{
    XOLog(@"被踢下线");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnForceOffline)]) {
        [_multiDelegate xoOnForceOffline];
    }
}
/**
 *  断线重连失败
 */
- (void)onReConnFailed:(int)code err:(NSString*)err
{
    XOLog(@"断线重连失败");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnReConnFailed:err:)]) {
        [_multiDelegate xoOnReConnFailed:code err:err];
    }
}
/**
 *  用户登录的userSig过期（用户需要重新获取userSig后登录）
 */
- (void)onUserSigExpired
{
    XOLog(@"登录过期");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnUserSigExpired)]) {
        [_multiDelegate xoOnUserSigExpired];
    }
}

#pragma mark ========================= TIMConnListener =========================
/**
 *  网络连接成功
 */
- (void)onConnSucc
{
    XOLog(@"\n=======************======= TIM 网络连接成功");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnConnSucc)]) {
        [_multiDelegate xoOnConnSucc];
    }
}

/**
 *  网络连接失败
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)onConnFailed:(int)code err:(NSString*)err
{
    XOLog(@"\n=======************======= TIM 网络连接失败 code: %d err:%@", code, err);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnConnFailed:err:)]) {
        [_multiDelegate xoOnConnFailed:code err:err];
    }
}

/**
 *  网络连接断开（断线只是通知用户，不需要重新登陆，重连以后会自动上线）
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)onDisconnect:(int)code err:(NSString*)err
{
    XOLog(@"\n=======************======= TIM 网络连接断开 code: %d err:%@", code, err);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnDisconnect:err:)]) {
        [_multiDelegate xoOnDisconnect:code err:err];
    }
}

/**
 *  连接中
 */
- (void)onConnecting
{
    XOLog(@"\n=======************======= TIM 正在连接...");
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnConnecting)]) {
        [_multiDelegate xoOnConnecting];
    }
}

#pragma mark ========================= TIMUploadProgressListener =========================
/**
 *  上传进度回调
 *
 *  @param msg      正在上传的消息
 *  @param elemidx  正在上传的elem的索引
 *  @param taskid   任务id
 *  @param progress 上传进度
 */
- (void)onUploadProgressCallback:(TIMMessage*)msg elemidx:(uint32_t)elemidx taskid:(uint32_t)taskid progress:(uint32_t)progress
{
    NSLog(@"上传进度回调: msg:%@   elemidx:%d   taskid:%d   progress:%d", msg, elemidx, taskid, progress);
    
    if (_multiDelegate > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(messageFileUpload:progress:)]) {
        [_multiDelegate messageFileUpload:msg progress:(progress * 0.01)];
    }
}

#pragma mark ========================= 代理 =========================

- (void)addDelegate:(id <XOChatClientProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (delegate != nil) {
        // 判断是否已经添加同一个类的对象作为代理
        if (delegateQueue == nil || delegateQueue == NULL) {
            if ([_multiDelegate countOfClass:[delegate class]] > 0) {
                [_multiDelegate removeDelegate:delegate];
            }
            [_multiDelegate addDelegate:delegate delegateQueue:dispatch_get_main_queue()];
        } else{
            if ([_multiDelegate countOfClass:[delegate class]] > 0) {
                [_multiDelegate removeDelegate:delegate];
            }
            [_multiDelegate addDelegate:delegate delegateQueue:delegateQueue];
        }
    }
}
- (void)removeDelegate:(id <XOChatClientProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (_multiDelegate && [_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegateQueue delegateQueue:delegateQueue];
    }
}
- (void)removeDelegate:(id <XOChatClientProtocol>)delegate
{
    if (_multiDelegate && [_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegate delegateQueue:NULL];
    }
}

#pragma mark ========================= 常驻线程 =========================

- (NSMutableDictionary <NSString *, NSURLSessionTask *>*)taskQueue
{
    if (!_taskQueue) {
        _taskQueue = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    return _taskQueue;
}

- (NSMutableArray<TIMMessage *> *)waitTaskQueue
{
    if (!_waitTaskQueue) {
        _waitTaskQueue = [NSMutableArray arrayWithCapacity:1];
    }
    return _waitTaskQueue;
}

- (void)startBackgroundThread
{
    if (!_bgThread) {
        _bgThread = [[NSThread alloc] initWithTarget:self selector:@selector(backgroundTask:) object:nil];
        [_bgThread setName:XOChatClientBackgroundThreadName];
        [_bgThread setQualityOfService:NSQualityOfServiceDefault];
    }
    [_bgThread start];
}

- (void)backgroundTask:(NSThread *)thread
{
    // 开启子线程的runLoop, 使其不会执行完一次任务就销毁
    [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
}

#pragma mark ========================= 下载任务 =========================

// 调度下载任务
- (void)ScheduleDownloadTask:(TIMMessage *)message
{
    if ([message elemCount] > 0) {
        TIMElem *elem = (TIMElem *)[message getElem:0];
        // 图片消息
        if ([elem isKindOfClass:[TIMImageElem class]]) {
            [self performSelector:@selector(downloadImageMessage:) onThread:self.bgThread withObject:message waitUntilDone:YES];
        }
        // 视频消息
        else if ([elem isKindOfClass:[TIMVideoElem class]]) {
            [self performSelector:@selector(downloadVideoMessage:) onThread:self.bgThread withObject:message waitUntilDone:YES];
        }
        // 语音消息
        else if ([elem isKindOfClass:[TIMSoundElem class]]) {
            [self performSelector:@selector(downloadSoundMessage:) onThread:self.bgThread withObject:message waitUntilDone:YES];
        }
        // 文件消息
        else if ([elem isKindOfClass:[TIMFileElem class]]) {
            [self performSelector:@selector(downloadFileMessage:) onThread:self.bgThread withObject:message waitUntilDone:YES];
        }
    }
}

// 1、下载图片
- (void)downloadImageMessage:(TIMMessage *)message
{
    TIMImageElem *imageElem = (TIMImageElem *)[message getElem:0];
    if (imageElem.imageList.count > 0) {
        
        TIMImage *timImage = [imageElem.imageList objectAtIndex:0];
        if (!XOIsEmptyString(timImage.url)) {
            
            // 判断下载任务是否已满
            if (self.taskQueue.count >= MaxDownloadCount) {
                @synchronized (self) {
                    [self.waitTaskQueue addObject:message];
                }
            }
            else {
                NSURL *imageURL = [NSURL URLWithString:timImage.url];
                __block NSString *imageFomat = [self getImageFormat:imageElem.format];
                __block NSString *imageName = [NSString stringWithFormat:@"%@.%@", timImage.uuid, imageFomat];
                __block NSString *imagePath = [XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:imageName];
                
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageURL];
                NSURLSessionDownloadTask *task = [[AFHTTPSessionManager manager] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
                    
                    // 回调代理下载进度
                    float progress = (downloadProgress.completedUnitCount * 1.0)/downloadProgress.totalUnitCount;
                    if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(message:downloadProgress:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self->_multiDelegate message:message downloadProgress:progress];
                        });
                    }
                } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                    
                    return [NSURL fileURLWithPath:imagePath];
                } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                    
                    // 将任务从下载队列中移除
                    NSString *resultKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
                    @synchronized (self) {
                        [self.taskQueue removeObjectForKey:resultKey];
                    }
                    
                    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath.relativePath];
                    if (error || !fileExist) {
                        
                        // 1、回调代理下载失败
                        if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(messageFileDownloadFail:failError:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self->_multiDelegate messageFileDownloadFail:message failError:error];
                            });
                        }
                        // 2、将下载失败的消息加入到等待下载队列的最后一个
                        @synchronized (self) {
                            [self.waitTaskQueue addObject:message];
                        }
                        // 3、取一个等待下载的消息出来, 开始下载任务
                        if (self.waitTaskQueue.count > 0) {
                            TIMMessage *waitMsg = [self.waitTaskQueue objectAtIndex:0];
                            [self ScheduleDownloadTask:waitMsg];
                        }
                    }
                    else {
                        // 1、根据原图获取缩略图, 写入沙盒
                        UIImage *originImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
                        NSString *thumbImageName = [NSString stringWithFormat:@"%@_thumb.%@", timImage.uuid, imageFomat];
                        NSURL *thumbImageURL = [NSURL fileURLWithPath:[XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:thumbImageName]];
                        CGSize thumbSize = [[XOFileManager shareInstance] getScaleImageSize:originImage];
                        UIImage *thumbImage = [[XOFileManager shareInstance] scaleOriginImage:originImage toSize:thumbSize];
                        NSData *thumbImageData = UIImageJPEGRepresentation(thumbImage, 1.0);
                        BOOL thumbFinish = [thumbImageData writeToURL:thumbImageURL atomically:YES];
                        // 2、回调代理下载成功
                        if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(messageFileDownloadSuccess:fileURL:thumbImageURL:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (thumbFinish) {
                                    [self->_multiDelegate messageFileDownloadSuccess:message fileURL:filePath thumbImageURL:thumbImageURL];
                                } else {
                                    [self->_multiDelegate messageFileDownloadSuccess:message fileURL:filePath thumbImageURL:nil];
                                }
                            });
                        }
                        
                        // 3、取一个等待下载的消息出来, 开始下载任务
                        if (self.waitTaskQueue.count > 0) {
                            TIMMessage *waitMsg = [self.waitTaskQueue objectAtIndex:0];
                            [self ScheduleDownloadTask:waitMsg];
                        }
                    }
                }];
                [task resume];
                
                // 将任务添加到队列中
                NSString *taskKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
                @synchronized (self) {
                    [self.taskQueue setObject:task forKey:taskKey];
                }
            }
        }
    }
}

// 2、下载视频
- (void)downloadVideoMessage:(TIMMessage *)message
{
    TIMVideoElem *videoElem = (TIMVideoElem *)[message getElem:0];
    if (videoElem.video) {
        // 判断下载任务是否已满
        if (self.taskQueue.count >= MaxDownloadCount) {
            @synchronized (self) {
                [self.waitTaskQueue addObject:message];
            }
        }
        else {
            TIMVideo *timVideo = videoElem.video;
            __block NSString *videoFomat = !XOIsEmptyString(timVideo.type) ? timVideo.type : @"mp4";
            __block NSString *videoName = [NSString stringWithFormat:@"%@.%@", timVideo.uuid, videoFomat];
            __block NSString *videoPath = [XOMsgFileDirectory(XOMsgFileTypeVideo) stringByAppendingPathComponent:videoName];
            
            [timVideo getVideo:videoPath progress:^(NSInteger curSize, NSInteger totalSize) {
                
                // 回调代理下载进度
                float progress = (curSize * 1.0)/totalSize;
                if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(message:downloadProgress:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self->_multiDelegate message:message downloadProgress:progress];
                    });
                }
                
            } succ:^{
                // 1、回调代理下载成功
                if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(messageFileDownloadSuccess:fileURL:thumbImageURL:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self->_multiDelegate messageFileDownloadSuccess:message fileURL:videoPath thumbImageURL:nil];
                    });
                }
                
                // 2、将任务从下载队列中移除
                NSString *resultKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
                @synchronized (self) {
                    [self.taskQueue removeObjectForKey:resultKey];
                }
                
                // 3、取一个等待下载的消息出来, 开始下载任务
                if (self.waitTaskQueue.count > 0) {
                    TIMMessage *waitMsg = [self.waitTaskQueue objectAtIndex:0];
                    [self ScheduleDownloadTask:waitMsg];
                }
                
            } fail:^(int code, NSString *msg) {
                
                // 1、回调代理下载失败
                if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(messageFileDownloadFail:failError:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:@{@"msg": msg}];
                        [self->_multiDelegate messageFileDownloadFail:message failError:error];
                    });
                }
                // 2、将下载失败的消息加入到等待下载队列的最后一个
                @synchronized (self) {
                    [self.waitTaskQueue addObject:message];
                }
                // 3、取一个等待下载的消息出来, 开始下载任务
                if (self.waitTaskQueue.count > 0) {
                    TIMMessage *waitMsg = [self.waitTaskQueue objectAtIndex:0];
                    [self ScheduleDownloadTask:waitMsg];
                }
            }];
            
            NSString *taskKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
            NSURLSessionTask *task = [[NSURLSessionTask alloc] init];
            // 将任务添加到队列中
            @synchronized (self) {
                [self.taskQueue setObject:task forKey:taskKey];
            }
        }
    }
}

// 3、下载语音
- (void)downloadSoundMessage:(TIMMessage *)message
{
    TIMSoundElem *soundElem = (TIMSoundElem *)[message getElem:0];
    // 判断下载任务是否已满
    if (self.taskQueue.count >= MaxDownloadCount) {
        @synchronized (self) {
            [self.waitTaskQueue addObject:message];
        }
    }
    else {
        __block NSString *soundName = [NSString stringWithFormat:@"%@.mp3", soundElem.uuid];
        __block NSString *soundPath = [XOMsgFileDirectory(XOMsgFileTypeAudio) stringByAppendingPathComponent:soundName];
        
        [soundElem getSound:soundPath progress:^(NSInteger curSize, NSInteger totalSize) {
            
            // 回调代理下载进度
            float progress = (curSize * 1.0)/totalSize;
            if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(message:downloadProgress:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_multiDelegate message:message downloadProgress:progress];
                });
            }
            
        } succ:^{
            // 1、回调代理下载成功
            if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(messageFileDownloadSuccess:fileURL:thumbImageURL:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSURL *fileURL = [NSURL URLWithString:soundPath];
                    [self->_multiDelegate messageFileDownloadSuccess:message fileURL:fileURL thumbImageURL:nil];
                });
            }
            
            // 2、将任务从下载队列中移除
            NSString *resultKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
            @synchronized (self) {
                [self.taskQueue removeObjectForKey:resultKey];
            }
            
            // 3、取一个等待下载的消息出来, 开始下载任务
            if (self.waitTaskQueue.count > 0) {
                TIMMessage *waitMsg = [self.waitTaskQueue objectAtIndex:0];
                [self ScheduleDownloadTask:waitMsg];
            }
            
        } fail:^(int code, NSString *msg) {
            
            // 1、回调代理下载失败
            if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(messageFileDownloadFail:failError:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:@{@"msg": msg}];
                    [self->_multiDelegate messageFileDownloadFail:message failError:error];
                });
            }
            // 2、将下载失败的消息加入到等待下载队列的最后一个
            @synchronized (self) {
                [self.waitTaskQueue addObject:message];
            }
            // 3、取一个等待下载的消息出来, 开始下载任务
            if (self.waitTaskQueue.count > 0) {
                TIMMessage *waitMsg = [self.waitTaskQueue objectAtIndex:0];
                [self ScheduleDownloadTask:waitMsg];
            }
        }];
        
        NSString *taskKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
        NSURLSessionTask *task = [[NSURLSessionTask alloc] init];
        // 将任务添加到队列中
        @synchronized (self) {
            [self.taskQueue setObject:task forKey:taskKey];
        }
    }
}

// 3、下载文件
- (void)downloadFileMessage:(TIMMessage *)message
{
    TIMFileElem *fileElem = (TIMFileElem *)[message getElem:0];
    // 判断下载任务是否已满
    if (self.taskQueue.count >= MaxDownloadCount) {
        @synchronized (self) {
            [self.waitTaskQueue addObject:message];
        }
    }
    else {
        NSString *filename = !XOIsEmptyString(fileElem.filename) ? fileElem.filename : [NSString stringWithFormat:@"%@.unknow", fileElem.uuid];
        __block NSString *filePath = [XOMsgFileDirectory(XOMsgFileTypeFile) stringByAppendingPathComponent:filename];
        
        [fileElem getFile:filePath progress:^(NSInteger curSize, NSInteger totalSize) {
            
            // 回调代理下载进度
            float progress = (curSize * 1.0)/totalSize;
            if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(message:downloadProgress:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_multiDelegate message:message downloadProgress:progress];
                });
            }
            
        } succ:^{
            // 1、回调代理下载成功
            if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(messageFileDownloadSuccess:fileURL:thumbImageURL:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSURL *fileURL = [NSURL URLWithString:filePath];
                    [self->_multiDelegate messageFileDownloadSuccess:message fileURL:fileURL thumbImageURL:nil];
                });
            }
            
            // 2、将任务从下载队列中移除
            NSString *resultKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
            @synchronized (self) {
                [self.taskQueue removeObjectForKey:resultKey];
            }
            
            // 3、取一个等待下载的消息出来, 开始下载任务
            if (self.waitTaskQueue.count > 0) {
                TIMMessage *waitMsg = [self.waitTaskQueue objectAtIndex:0];
                [self ScheduleDownloadTask:waitMsg];
            }
            
        } fail:^(int code, NSString *msg) {
            
            // 1、回调代理下载失败
            if (self->_multiDelegate && [self->_multiDelegate hasDelegateThatRespondsToSelector:@selector(messageFileDownloadFail:failError:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:@{@"msg": msg}];
                    [self->_multiDelegate messageFileDownloadFail:message failError:error];
                });
            }
            // 2、将下载失败的消息加入到等待下载队列的最后一个
            @synchronized (self) {
                [self.waitTaskQueue addObject:message];
            }
            // 3、取一个等待下载的消息出来, 开始下载任务
            if (self.waitTaskQueue.count > 0) {
                TIMMessage *waitMsg = [self.waitTaskQueue objectAtIndex:0];
                [self ScheduleDownloadTask:waitMsg];
            }
        }];
        
        NSString *taskKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
        NSURLSessionTask *task = [[NSURLSessionTask alloc] init];
        // 将任务添加到队列中
        @synchronized (self) {
            [self.taskQueue setObject:task forKey:taskKey];
        }
    }
}


#pragma mark ========================= help =========================

// 获取图片的格式
- (NSString *)getImageFormat:(TIM_IMAGE_FORMAT)imageFormat
{
    NSString *format = nil;
    
    switch (imageFormat) {
        case TIM_IMAGE_FORMAT_PNG:
            format = @"png";
            break;
        case TIM_IMAGE_FORMAT_GIF:
            format = @"gif";
            break;
        case TIM_IMAGE_FORMAT_BMP:
            format = @"bmp";
            break;
        default:
            format = @"jpg";
            break;
    }
    return format;
}


@end
