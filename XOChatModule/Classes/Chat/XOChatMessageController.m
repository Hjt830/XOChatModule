//
//  XOChatMessageController.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOChatMessageController.h"
#import "XOLocationViewController.h"
#import "ZXChatHelper.h"

#import "XOChatClient.h"
#import "WXFaceMessageCell.h"
#import "WXTextMessageCell.h"
#import "WXImageMessageCell.h"
#import "WXSoundMessageCell.h"
#import "WXVideoMessageCell.h"
#import "WXFileMessageCell.h"
#import "WXLocationMessageCell.h"
#import "WXPromptMessageCell.h"

#import "TIMElem+XOExtension.h"
#import "LGAudioKit.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <YBImageBrowser/YBIBVideoData.h>
#import <FLAnimatedImage/FLAnimatedImage.h>

static NSString * const MsgSectionTimeKey = @"timeSection";     // 数据源中的时间key
static NSString * const MsgSectionListKey = @"messageList";     // 数据源中的消息key

static NSString * const TimeMessageCellID       = @"TimeMessageCellID";
static NSString * const TextMessageCellID       = @"TextMessageCellID";
static NSString * const ImageMessageCellID      = @"ImageMessageCellID";
static NSString * const SoundMessageCellID      = @"SoundMessageCellID";
static NSString * const VideoMessageCellID      = @"VideoMessageCellID";
static NSString * const FaceMessageCellID       = @"FaceMessageCellID";
static NSString * const FileMessageCellID       = @"FileMessageCellID";
static NSString * const LocationMessageCellID   = @"LocationMessageCellID";
static NSString * const CarteMessageCellID      = @"CarteMessageCellID";
static NSString * const WalletMessageCellID     = @"WalletMessageCellID";
static NSString * const UITableViewCellID       = @"UITableViewCellID";
static NSString * const PromptMessageCellID     = @"PromptMessageCellID";

static int const MessageTimeSpaceMinute = 5;        // 消息时间间隔时间 单位:分钟
static int const MessageAudioPlayIndex = 1000;    // 语音消息播放基础序列

@interface XOChatMessageController () <UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate, XOChatClientProtocol, XOMessageDelegate, LGAudioPlayerDelegate, WXMessageCellDelegate, YBImageBrowserDelegate>
{
    UIEdgeInsets        _safeInset;
}

@property (nonatomic, strong) TIMMessage                        *earliestMsg;   // 最早的一条消息
@property (nonatomic, strong) CALayer                           * chatBGLayer;
@property (nonatomic, strong) UITableView                       *tableView;     // 会话列表
@property (nonatomic, strong) NSMutableArray    <NSMutableDictionary <NSString *, id>* >*dataSource;    // 数据源
@property (nonatomic, strong) NSLock                            *lock;          // 线程锁
@property (nonatomic, assign) NSUInteger                        page;           // 数据的页数
@property (nonatomic, strong) NSMutableDictionary   <NSString *, NSValue *> *cellSizeDict;              // cell的高度缓存
// 上传、下载消息相关
@property (nonatomic, strong) NSMutableDictionary   <NSString *, NSIndexPath *> *sendingMsgQueue;       // 发送中消息保存列表
@property (nonatomic, strong) NSMutableDictionary   <NSString *, NSIndexPath *> *downloadingMsgQueue;   // 下载中消息保存列表
// 浏览图片视频相关
@property (nonatomic, strong) NSMutableArray        <TIMMessage *>  *imageVideoList;            // 图片或者视频消息
@property (nonatomic, strong) NSMutableDictionary   <NSString *, NSIndexPath *> *imageVideoIndexpathList;   // 图片或者视频消息序号

@end

@implementation XOChatMessageController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.earliestMsg = nil;
        [[XOChatClient shareClient] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[XOChatClient shareClient].messageManager addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)dealloc
{
    [[XOChatClient shareClient] removeDelegate:self];
    [[XOChatClient shareClient].messageManager removeDelegate:self];
    NSLog(@"%s", __func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = BG_TableColor;
    
    // 添加消息列表
    [self.view addSubview:self.tableView];
    // 添加聊天背景
    [self showPreviewChatBGImage];
    // 加载消息
    [self loadMessages];
    // 设置录音播放代理
    [LGAudioPlayer sharePlayer].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[LGAudioPlayer sharePlayer] stopAudioPlayer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat tableW = self.view.width - _safeInset.left - _safeInset.right;
    CGFloat tableH = self.view.height - _safeInset.top;
    self.tableView.frame = CGRectMake(_safeInset.left, _safeInset.top, tableW, tableH);
    self.tableView.backgroundView.frame = self.tableView.bounds;
    if (self.dataSource.count > 0) {
        NSInteger lastSection = self.dataSource.count - 1;
        NSArray *list = [self.dataSource[lastSection] objectForKey:MsgSectionListKey];
        if (list.count > 0) {
            @try {
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:(list.count - 1) inSection:lastSection];
                [self.tableView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            } @catch (NSException *exception) {
                NSLog(@"%s --- 滑动到最底部异常: %@", __func__, exception);
            } @finally {
                
            }
        }
    }
}

// 显示聊天背景页
- (void)showPreviewChatBGImage
{
    [[XOSettingManager defaultManager] getCurrentChatBGImage:^(BOOL finish, UIImage *bgImage) {
        if (finish && bgImage != nil) {
            self.chatBGLayer.contents = (__bridge id)bgImage.CGImage;
            [self.tableView.backgroundView.layer addSublayer:self.chatBGLayer];
        } else {
            [self.chatBGLayer removeFromSuperlayer];
        }
    }];
}

#pragma mark ====================== load message =======================

// 拉取历史消息
- (void)loadMessages
{
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
    
        @try {
            @XOWeakify(self);
            [self.conversation getMessage:20 last:self.earliestMsg succ:^(NSArray *msgs) {
                @XOStrongify(self);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView.mj_header endRefreshing];
                }];
                
                NSArray <TIMMessage *>* array = msgs;
                if (!XOIsEmptyArray(array)) {
                    
                    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
                    array = [array sortedArrayUsingDescriptors:@[descriptor]];
                    __block BOOL isFirstPage = (self.earliestMsg == nil);
                    // 处理数据
                    __block NSArray *dataArray = [self handleDataSource:array];
                    // 查询第一页, 清空数据源
                    if (isFirstPage) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            if ([self.lock tryLock]) {
                                [self.dataSource removeAllObjects];
                                [self.dataSource addObjectsFromArray:dataArray];
                                [self.lock unlock];
                            }
                            [self.tableView reloadData];
                            
                            // 滑动到底部
                            if (self.dataSource.count > 0) {
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    NSInteger lastSection = self.dataSource.count - 1;
                                    NSArray *list = [self.dataSource[lastSection] objectForKey:MsgSectionListKey];
                                    if (list.count > 0) {
                                        @try {
                                            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:(list.count - 1) inSection:lastSection];
                                            [self.tableView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                                        } @catch (NSException *exception) {
                                            NSLog(@"%s --- 滑动到最底部异常: %@", __func__, exception);
                                        } @finally {
                                            
                                        }
                                    }
                                });
                            }
                            
                            // 收集图片和视频消息
                            [self collectionImageVideoList:dataArray resfrsh:YES];
                        }];
                    }
                    // 拉取的更多的消息
                    else {
                        __block NSMutableIndexSet *sets = [NSMutableIndexSet indexSet];
                        [dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            [sets addIndex:idx];
                        }];
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            if ([self.lock tryLock]) {
                                [self.dataSource insertObjects:dataArray atIndexes:sets];
                                [self.lock unlock];
                            }
                            [self.tableView beginUpdates];
                            [self.tableView insertSections:sets withRowAnimation:UITableViewRowAnimationNone];
                            [self.tableView endUpdates];
                        }];
                        
                        // 收集图片和视频消息
                        [self collectionImageVideoList:dataArray resfrsh:NO];
                    }
                    
                    // 记录当前最大的消息时间
                    if ([[array firstObject] isKindOfClass:[TIMMessage class]]) {
                        self.earliestMsg = [array firstObject];
                    }
                }
                else {
                    if (!XOIsEmptyArray(self.dataSource)) {
                        [SVProgressHUD showInfoWithStatus:@"没有更多消息了"];
                        [SVProgressHUD dismissWithDelay:0.5f];
                    }
                }
                
            } fail:^(int code, NSString *msg) {
                @XOStrongify(self);
                [self.tableView.mj_header endRefreshing];
                NSLog(@"---------- %s 拉取历史消息失败！！！  code: %d, msg: %@", __func__, code, msg);
            }];
            
        } @catch (NSException *exception) {
            NSLog(@"exception: %@", exception);
        } @finally {
            
        }
    }];
}

#pragma mark ====================== 数据处理 =======================

// 被筛选掉的消息
- (BOOL)filterMessage:(TIMMessage *)message
{
    BOOL filter = NO;
    switch (message.status) {
        case TIM_MSG_STATUS_HAS_DELETED:
            filter = YES;
            break;
        case TIM_MSG_STATUS_LOCAL_REVOKED:
            filter = YES;
            break;
        default:
            break;
    }
    
    if ([message elemCount] == 0) {
        filter = YES;
    }
    
    return filter;
}

// 处理消息，根据时间分组
- (NSArray *)handleDataSource:(NSArray <TIMMessage *>*)array
{
    if (XOIsEmptyArray(array)) {
        return nil;
    }
    
    // 消息间隔超过5分钟则加一个时间, 并分组
    __block NSMutableArray *dataArray = [NSMutableArray array];
    __block long long startTime = [[array firstObject].timestamp timeIntervalSince1970] * 1000;
    __block NSMutableArray <TIMMessage *>* mutArr = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        BOOL filter = [self filterMessage:obj];
        if (filter) {
            NSLog(@"消息被剔除, 因为该条消息已经被撤回或删除");
        }
        else {
            // 计算与 **上一个时间分组起止时间** 的间隔时间
            long long msgTime = [obj.timestamp timeIntervalSince1970] * 1000;
            long long timeSpace = msgTime - startTime;
            
            // 时间间隔小于5分钟时, 加入同一个分组 且 消息有内容
            if (timeSpace < MessageTimeSpaceMinute * 60 * 1000 && [obj elemCount] > 0) {
                [mutArr addObject:obj];
                
                // 如果最后一条消息在这个分组内, 则在此处保存
                if (idx == array.count - 1) {
                    // 根据消息的本地发送时间进行分组内排序 （确保与发送端的消息顺序一致）
                    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
                    [mutArr sortedArrayUsingDescriptors:@[descriptor]];
                    NSMutableDictionary *mutMsgDict = @{MsgSectionTimeKey : @(startTime),
                                                        MsgSectionListKey : [mutArr mutableCopy]}.mutableCopy;
                    [dataArray addObject:mutMsgDict];
                    [mutArr removeAllObjects];
                    mutArr = nil;
                }
            }
            // 时间间隔大于5分钟时, 保存该分组, 同时 重置 **上一个时间分组起止时间** 并 新建下一个分组
            else {
                // 根据消息的发送时间进行分组内排序 （确保与发送端的消息顺序一致）
                NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
                [mutArr sortedArrayUsingDescriptors:@[descriptor]];
                // 保存该分组数据
                NSMutableDictionary *mutMsgDict = @{MsgSectionTimeKey : @(startTime),
                                                    MsgSectionListKey : [mutArr mutableCopy]}.mutableCopy;
                [dataArray addObject:mutMsgDict];
                [mutArr removeAllObjects];
                mutArr = nil;
                
                // 重置 **上一个时间分组起止时间**
                startTime = (long long)[obj.timestamp timeIntervalSince1970] * 1000;
                // 新建下一个分组
                mutArr = [NSMutableArray array];
                [mutArr addObject:obj];
                
                // 如果这是最后一条消息, 则在此处保存
                if (idx == array.count - 1) {
                    NSMutableDictionary *mutMsgDict = @{MsgSectionTimeKey : @(startTime),
                                                        MsgSectionListKey : [mutArr mutableCopy]}.mutableCopy;
                    [dataArray addObject:mutMsgDict];
                    [mutArr removeAllObjects];
                    mutArr = nil;
                }
            }
            
            // 调度消息文件下载任务(如果需要下载的话)
            [[XOChatClient shareClient] scheduleDownloadTask:obj];
        }
    }];
    
    return dataArray;
}

// 收集多媒体消息（图片、视频）
- (void)addToImageVideoList:(TIMMessage *)message index:(NSIndexPath *)indexpath
{
    if (!message || !indexpath) {
        return;
    }
    
    if ([message elemCount] > 0) {
        TIMElem *elem = [message getElem:0];
        if ([elem isKindOfClass:[TIMImageElem class]] ||
            [elem isKindOfClass:[TIMVideoElem class]])
        {
            NSString *msgKey = getMessageKey(message);
            if (nil == [self.imageVideoList objectForKey:msgKey]) {
                if ([self.lock tryLock]) {
                    [self.imageVideoList setObject:message forKey:msgKey];
                    [self.imageVideoIndexpathList setObject:indexpath forKey:msgKey];
                    [self.lock unlock];
                }
            }
        }
    }
}

// 收集多媒体消息（图片、视频）
- (void)collectionImageVideoList:(NSArray <NSMutableDictionary <NSString *, id>* >*)dataArray resfrsh:(BOOL)refresh
{
    if ([self.lock tryLock]) {
        
        if (refresh) {
            [self.imageVideoList removeAllObjects];
            [self.imageVideoIndexpathList removeAllObjects];
        }
        
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
           
            [dataArray enumerateObjectsUsingBlock:^(NSMutableDictionary <NSString *,id> * _Nonnull sectionDict, NSUInteger section, BOOL * _Nonnull stop) {
                NSArray <TIMMessage *>* msgList = [sectionDict objectForKey:MsgSectionListKey];
                [msgList enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull message, NSUInteger row, BOOL * _Nonnull stop) {
                    
                    if ([message elemCount] > 0) {
                        TIMElem *elem = [message getElem:0];
                        if ([elem isKindOfClass:[TIMImageElem class]] || [elem isKindOfClass:[TIMVideoElem class]])
                        {
                            NSString *msgKey = getMessageKey(message);
                            if (nil == [self.imageVideoIndexpathList objectForKey:msgKey]) {
                                
                                // 保存消息
                                [self.imageVideoList addObject:message];
                                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:row inSection:section];
                                // 保存消息的序列
                                [self.imageVideoIndexpathList setObject:indexpath forKey:msgKey];
                                // 拉取的数据 --- 之前插入的indexpath的数据全部都要增加
                                if (!refresh) {
                                    NSUInteger sec = dataArray.count;
                                    [self.imageVideoIndexpathList enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSIndexPath * _Nonnull oldIndexPath, BOOL * _Nonnull stop) {
                                        oldIndexPath = [NSIndexPath indexPathForRow:oldIndexPath.row inSection:oldIndexPath.section + sec];
                                    }];
                                }
                            }
                        }
                    }
                }];
            }];
        }];
        
        [self.lock unlock];
    }
}

#pragma mark ========================= public method =========================

// 添加发送中的消息
- (void)sendingMessage:(TIMMessage *)message
{
    NSIndexPath *indexpath = [self addMessage:message];
    // 缓存发送中的消息
    if (indexpath) {
        NSString *msgKey = getMessageKey(message);
        if ([self.lock tryLock]){
            [self.sendingMsgQueue setValue:indexpath forKey:msgKey];
            [self.lock unlock];
        }
    }
    
    // 收集多媒体消息（图片、视频）
    [self addToImageVideoList:message index:indexpath];
}
// 修改发送中的消息为成功
- (void)sendSuccessMessage:(TIMMessage *)message
{
    NSIndexPath *indexpath = [self findIndexPathWithSendingMessage:message];
    if (indexpath) {
        WXMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexpath];
        if (cell) {
            [cell sendSuccess];
        }
    }
    
    // 从发送消息队列中移除该条消息
    NSString *msgKey = getMessageKey(message);
    if ([self.sendingMsgQueue objectForKey:msgKey]) {
        if ([self.lock tryLock]) {
            [self.sendingMsgQueue removeObjectForKey:msgKey];
            [self.lock unlock];
        }
    }
}
// 修改发送中的消息为失败
- (void)sendFailMessage:(TIMMessage *)message
{
    NSIndexPath *indexpath = [self findIndexPathWithSendingMessage:message];
    if (indexpath) {
        WXMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexpath];
        if (cell) {
            [cell sendFail];
        }
    }
    // 从发送消息队列中移除该条消息
    NSString *msgKey = getMessageKey(message);
    if ([self.sendingMsgQueue objectForKey:msgKey]) {
        if ([self.lock tryLock]) {
            [self.sendingMsgQueue removeObjectForKey:msgKey];
            [self.lock unlock];
        }
    }
}
// 添加消息
- (NSIndexPath *)addMessage:(TIMMessage *)message
{
    __block NSIndexPath *indexpath = nil;
    __block long long msgTime = [message.timestamp timeIntervalSince1970] * 1000;
    long long maxTime = [[self.dataSource lastObject][MsgSectionTimeKey] unsignedIntegerValue];
    long long maxSpace = msgTime - maxTime;
    long long minTime = [[self.dataSource firstObject][MsgSectionTimeKey] unsignedIntegerValue];
    long long minSpace = minTime - msgTime;
    
    // 1、如果插入的消息时间比最大的消息分组的时间大5分钟, 则在最后面追加一组
    if (maxSpace > MessageTimeSpaceMinute * 60 * 1000) {
        NSMutableArray *mutArr = [NSMutableArray array];
        [mutArr addObject:message];
        NSMutableDictionary *mutMsgDict = @{MsgSectionTimeKey : @(msgTime),
                                            MsgSectionListKey : mutArr}.mutableCopy;
        if ([self.lock tryLock]) {
            [self.dataSource addObject:mutMsgDict];
            [self.lock unlock];
        }
        indexpath = [NSIndexPath indexPathForRow:0 inSection:(self.dataSource.count - 1)];
        NSIndexSet *indexset = [[NSIndexSet alloc] initWithIndex:self.dataSource.count - 1];
        [self.tableView insertSections:indexset withRowAnimation:UITableViewRowAnimationBottom];
    }
    // 2、如果插入的消息时间比最小的消息分组的时间小5分钟, 则在最前面插入一组
    else if (minSpace > 0 && minSpace > MessageTimeSpaceMinute * 60 * 1000) {
        NSMutableArray *mutArr = [NSMutableArray array];
        [mutArr addObject:message];
        NSMutableDictionary *mutMsgDict = @{MsgSectionTimeKey : @(msgTime),
                                            MsgSectionListKey : mutArr}.mutableCopy;
        if ([self.lock tryLock]) {
            [self.dataSource insertObject:mutMsgDict atIndex:0];
            [self.lock unlock];
        }
        indexpath = [NSIndexPath indexPathForRow:0 inSection:0];
        NSIndexSet *indexset = [[NSIndexSet alloc] initWithIndex:0];
        [self.tableView insertSections:indexset withRowAnimation:UITableViewRowAnimationTop];
    }
    // 3、如果插入的消息时间在 {最小时间, 最大时间} 范围内
    else {
        // 遍历消息数组, 插入消息
        if ([self.lock tryLock]) {
            @XOWeakify(self);
            [self.dataSource enumerateObjectsUsingBlock:^(NSMutableDictionary <NSString *, id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
                @XOStrongify(self);
                // 获取分组的时间
                NSUInteger sectionTime = [dict[MsgSectionTimeKey] unsignedIntegerValue];
                long long timeSpace = msgTime - sectionTime;
                
                // 如果插入的消息时间在 {上一个消息分组时间 + 5min, 当前消息分组时间}, 则新建分组并插入
                if (timeSpace < 0) {
                    NSMutableArray *mutArr = [NSMutableArray array];
                    [mutArr addObject:message];
                    NSMutableDictionary *mutMsgDict = @{MsgSectionTimeKey : @(msgTime),
                                                        MsgSectionListKey : mutArr}.mutableCopy;
                    [self.dataSource insertObject:mutMsgDict atIndex:idx];
                    indexpath = [NSIndexPath indexPathForRow:0 inSection:idx];
                    NSIndexSet *indexset = [[NSIndexSet alloc] initWithIndex:idx];
                    [self.tableView insertSections:indexset withRowAnimation:UITableViewRowAnimationBottom];
                    
                    *stop = YES;
                }
                // 如果插入的消息时间在 {当前消息分组时间, 当前消息分组时间 + 5min}, 则插入到该分组
                else if (timeSpace >= 0 && timeSpace < MessageTimeSpaceMinute * 60 * 1000) {
                    NSMutableArray <TIMMessage *>* mutArr = dict[MsgSectionListKey];
                    [mutArr addObject:message];
                    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
                    [mutArr sortedArrayUsingDescriptors:@[descriptor]];
                    NSUInteger row = [mutArr indexOfObject:message];
                    indexpath = [NSIndexPath indexPathForRow:row inSection:idx];
                    [self.tableView insertRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationBottom];
                    
                    *stop = YES;
                }
            }];
            [self.lock unlock];
        }
    }
    return indexpath;
}

// 删除消息
- (void)deleteMessage:(TIMMessage *)message
{
    @XOWeakify(self);
    [self.dataSource enumerateObjectsUsingBlock:^(NSMutableDictionary<NSString *,id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        @XOStrongify(self);
        
        NSMutableArray <TIMMessage *>* mutArr = dict[MsgSectionListKey];
        __block BOOL needStop = NO;
        [mutArr enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger subIdx, BOOL * _Nonnull subStop) {
           
            if ([obj.msgId isEqualToString:message.msgId] && [obj.timestamp isEqual:message.timestamp]) {
                [mutArr removeObject:obj];
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:subIdx inSection:idx];
                [self.tableView deleteRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                needStop = YES;
                *subStop = YES;
            }
        }];
        *stop = needStop;
    }];
}

// 更新消息
- (void)updateMessage:(TIMMessage *)message
{
    @XOWeakify(self);
    [self.dataSource enumerateObjectsUsingBlock:^(NSMutableDictionary<NSString *,id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        @XOStrongify(self);
        
        NSMutableArray <TIMMessage *>* mutArr = dict[MsgSectionListKey];
        __block BOOL needStop = NO;
        [mutArr enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger subIdx, BOOL * _Nonnull subStop) {
            
            if ([obj.msgId isEqualToString:message.msgId] && [obj.timestamp isEqual:message.timestamp]) {
                [mutArr replaceObjectAtIndex:subIdx withObject:message];
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:subIdx inSection:idx];
                [self.tableView reloadRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                needStop = YES;
                *subStop = YES;
            }
        }];
        *stop = needStop;
    }];
}

#pragma mark ====================== UITableViewDataSource =======================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *list = [self.dataSource[section] objectForKey:MsgSectionListKey];
    return list.count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.section < self.dataSource.count)
    {
        NSArray *list = [self.dataSource[indexPath.section] objectForKey:MsgSectionListKey];
        if (indexPath.row < list.count) {
            TIMMessage *message = list[indexPath.row];
            TIMElem *elem = [message getElem:0];
            
            WXMessageCell *cell = nil;
            if ([elem isKindOfClass:[TIMTextElem class]] ||
                [elem isKindOfClass:[TIMCustomElem class]])
            {
                cell = [tableView dequeueReusableCellWithIdentifier:TextMessageCellID forIndexPath:indexPath];
                if ([elem isKindOfClass:[TIMCustomElem class]]) {
                    TIMCustomElem *customElem = (TIMCustomElem *)elem;
                    NSString *text = [[NSString alloc] initWithData:customElem.data encoding:NSUTF8StringEncoding];
                    NSLog(@"自定义消息 ============== %@", text);
                }
            }
            else if ([elem isKindOfClass:[TIMImageElem class]]) {
                cell = [tableView dequeueReusableCellWithIdentifier:ImageMessageCellID forIndexPath:indexPath];
            }
            else if ([elem isKindOfClass:[TIMSoundElem class]]) {
                cell = [tableView dequeueReusableCellWithIdentifier:SoundMessageCellID forIndexPath:indexPath];
            }
            else if ([elem isKindOfClass:[TIMVideoElem class]]) {
                cell = [tableView dequeueReusableCellWithIdentifier:VideoMessageCellID forIndexPath:indexPath];
            }
            else if ([elem isKindOfClass:[TIMFileElem class]]) {
                cell = [tableView dequeueReusableCellWithIdentifier:FileMessageCellID forIndexPath:indexPath];
            }
            else if ([elem isKindOfClass:[TIMLocationElem class]]) {
                cell = [tableView dequeueReusableCellWithIdentifier:LocationMessageCellID forIndexPath:indexPath];
            }
            else if ([elem isKindOfClass:[TIMFaceElem class]]) {
                cell = [tableView dequeueReusableCellWithIdentifier:FaceMessageCellID forIndexPath:indexPath];
            }
            else if ([elem isKindOfClass:[TIMGroupTipsElem class]] ||
                     [elem isKindOfClass:[TIMGroupTipsElemMemberInfo class]] ||
                     [elem isKindOfClass:[TIMGroupSystemElem class]])
            {
                cell = [tableView dequeueReusableCellWithIdentifier:PromptMessageCellID forIndexPath:indexPath];
            }
            else {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:UITableViewCellID forIndexPath:indexPath];
                return cell;
            }
            
            WXMessageCell *msgCell = (WXMessageCell *)cell;
            if ([msgCell isKindOfClass:[WXMessageCell class]]) {
                msgCell.delegate = self;
            }
            msgCell.message = message;
            
            return cell;
        }
        else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:UITableViewCellID forIndexPath:indexPath];
            return cell;
        }
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:UITableViewCellID forIndexPath:indexPath];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < self.dataSource.count)
    {
        NSArray *list = [self.dataSource[indexPath.section] objectForKey:MsgSectionListKey];
        if (indexPath.row < list.count) {
            TIMMessage *message = [self.dataSource[indexPath.section] objectForKey:MsgSectionListKey][indexPath.row];
            CGFloat msgHei = [self messageSize:message].height;
            return msgHei;
        }
        return 0.01;
    }
    return 0.01;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *dict = [self.dataSource objectAtIndex:section];
    long long timestamp = [dict[MsgSectionTimeKey] longLongValue]/1000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSString *time = [date minuteDescription];
    return [NSString stringWithFormat:@" %@ ", time];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    WXMessageHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:TimeMessageCellID];
    return headerView;
}

#pragma mark ====================== UITableViewDelegate =======================

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapChatMessageView:)]) {
        [self.delegate didTapChatMessageView:self];
    }
    
    TIMMessage *message = [self.dataSource[indexPath.section] objectForKey:MsgSectionListKey][indexPath.row];
    if ([message elemCount] <= 0) {
        return;
    }
    
    TIMElem *elem = [message getElem:0];
    if ([elem isKindOfClass:[TIMTextElem class]] ||
        [elem isKindOfClass:[TIMCustomElem class]])
    {
        NSLog(@"自定义消息 文本消息 ==============");
    }
    else if ([elem isKindOfClass:[TIMImageElem class]]) {
        NSLog(@"图片消息 ==============");
    }
    else if ([elem isKindOfClass:[TIMVideoElem class]]) {
        NSLog(@"视频消息 ==============");
    }
    else if ([elem isKindOfClass:[TIMSoundElem class]]) {
        NSLog(@"语音消息 ==============");
    }
    else if ([elem isKindOfClass:[TIMFileElem class]]) {
        NSLog(@"文件消息 ==============");
    }
    else if ([elem isKindOfClass:[TIMLocationElem class]]) {
        NSLog(@"位置消息 ==============");
    }
    else if ([elem isKindOfClass:[TIMFaceElem class]]) {
        NSLog(@"表情消息 ==============");
    }
    else if ([elem isKindOfClass:[TIMGroupTipsElem class]] ||
             [elem isKindOfClass:[TIMGroupTipsElemMemberInfo class]] ||
             [elem isKindOfClass:[TIMGroupSystemElem class]])
    {
        NSLog(@"系统提示消息 ==============");
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapChatMessageView:)]) {
        [self.delegate didTapChatMessageView:self];
    }
}

#pragma mark ========================= XOChatClientProtocol =========================

// 收到新消息
- (void)xoOnNewMessage:(NSArray<TIMMessage *> *)msgs
{
    [msgs enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
        
        BOOL isChattingMsg = [message.sender isEqualToString:[self.conversation getReceiver]];
        BOOL isSystemMsg = [[message getElem:0] isKindOfClass:[TIMGroupTipsElem class]];
        if (isChattingMsg || isSystemMsg) {
            BOOL filter = [self filterMessage:message];
            if (filter) {
                NSLog(@"消息被剔除, 因为该条消息已经被撤回或删除");
            }
            else {
                // 插入新消息
                NSIndexPath *indexpath = [self addMessage:message];
                
                // 如果消息是图片或者视频, 加入
                [self addToImageVideoList:message index:indexpath];
                
                // 设置消息已读
                [self.conversation setReadMessage:message succ:^{
                    NSLog(@"----- 设置消息已读成功");
                } fail:^(int code, NSString *msg) {
                    NSLog(@"----- 设置消息已读失败");
                }];
            }
        }
    }];
}
// 消息下载文件进度回调
- (void)message:(TIMMessage *)message downloadProgress:(float)progress
{
    NSIndexPath *indexpath = [self findIndexPathWithDownloadingMessage:message];
    if (indexpath) {
        WXMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexpath];
        if (cell) {
            [cell updateProgress:progress effect:YES];
        }
    }
}
// 消息文件下载成功回调
- (void)messageFileDownloadSuccess:(TIMMessage *)message fileURL:(NSURL *)fileURL thumbImageURL:(NSURL *)thumbImageURL
{
    // 从下载消息队列中移除该条消息
    NSString *msgKey = getMessageKey(message);
    if ([self.downloadingMsgQueue objectForKey:msgKey]) {
        if ([self.lock tryLock]) {
            [self.downloadingMsgQueue removeObjectForKey:msgKey];
            [self.lock unlock];
        }
    }
}
// 消息文件下载失败回调
- (void)messageFileDownloadFail:(TIMMessage *)message failError:(NSError *)error
{
    // 从下载消息队列中移除该条消息
    NSString *msgKey = getMessageKey(message);
    if ([self.downloadingMsgQueue objectForKey:msgKey]) {
        if ([self.lock tryLock]) {
            [self.downloadingMsgQueue removeObjectForKey:msgKey];
            [self.lock unlock];
        }
    }
}
// 缩略图下载成功
- (void)messageThumbImageDownloadSuccess:(TIMMessage * _Nonnull)message thumbImagePath:(NSString * _Nullable)thumbImagePath
{
    NSIndexPath *indexpath = [self findIndexPathWithDownloadingMessage:message];
    if (indexpath && indexpath.section < self.dataSource.count) {
        NSArray *arr = [self.dataSource[indexpath.section] objectForKey:MsgSectionListKey];
        if (indexpath.row < arr.count) {
            [self.tableView reloadRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}
// 缩略图下载失败
- (void)messageThumbImageDownloadFail:(TIMMessage * _Nonnull)message
{
    
}
// 消息文件上传进度回调
- (void)messageFileUpload:(TIMMessage *)message progress:(float)progress
{
    NSIndexPath *indexpath = [self findIndexPathWithSendingMessage:message];
    if (indexpath) {
        WXMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexpath];
        if (cell) {
            [cell updateProgress:progress effect:YES];
        }
    }
}

#pragma mark ========================= WXMessageCellDelegate =========================

// 点击了用户头像
- (void)messageCellDidTapAvatar:(WXMessageCell *)cell message:(TIMMessage *)message
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapChatMessageView:)]) {
        [self.delegate didTapChatMessageView:self];
    }
}
// 长按了用户头像
- (void)messageCellLongPressAvatar:(WXMessageCell *)cell message:(TIMMessage *)message
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapChatMessageView:)]) {
        [self.delegate didTapChatMessageView:self];
    }
}
// 点击了消息
- (void)messageCellDidTapMessage:(WXMessageCell *)cell message:(TIMMessage *)message
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapChatMessageView:)]) {
        [self.delegate didTapChatMessageView:self];
    }

    if ([message elemCount] > 0) {
        TIMElem *elem = [message getElem:0];
        if ([elem isKindOfClass:[TIMImageElem class]] ||
            [elem isKindOfClass:[TIMVideoElem class]])
        {
            [self readImageMessageWith:message withCell:cell];
        }
        else if ([elem isKindOfClass:[TIMSoundElem class]])
        {
            NSIndexPath *indexpath = [self.tableView indexPathForCell:cell];
            NSUInteger index = indexpath.section * MessageAudioPlayIndex + indexpath.row;
            [self readAudioMessageWith:message withIndex:index];
        }
        else if ([elem isKindOfClass:[TIMFileElem class]])
        {
            [self readFileMessageWith:message];
        }
        else if ([elem isKindOfClass:[TIMLocationElem class]])
        {
            [self readLocationMessageWith:message];
        }
    }
}
// 长按了消息
- (void)messageCellLongPressMessage:(WXMessageCell *)cell message:(TIMMessage *)message
{}
// 点击了重发消息
- (void)messageCellDidTapResendMessage:(WXMessageCell *)cell message:(TIMMessage *)message
{}

#pragma mark =========================== LGAudioPlayerDelegate ===========================

- (void)audioPlayerStateDidChanged:(LGAudioPlayerState)audioPlayerState forIndex:(NSUInteger)index
{
    NSUInteger section = 0, row = 0;
    if (index < MessageAudioPlayIndex) {
        section = 0;
        row = index;
    } else {
        section = index/MessageAudioPlayIndex;
        row = index%MessageAudioPlayIndex;
    }
    if (section < self.dataSource.count) {
        NSArray *list = [self.dataSource[section] objectForKey:MsgSectionListKey];
        if (row < list.count) {
            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:row inSection:section];
            @try {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    WXMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexpath];
                    if (cell && [cell isKindOfClass:[WXSoundMessageCell class]]) {
                        WXSoundMessageCell *soundCell = (WXSoundMessageCell *)cell;
                        soundCell.playState = audioPlayerState;
                    }
                }];
            } @catch (NSException *exception) {
                NSLog(@"exception: %@", exception);
            } @finally {
                
            }
        }
    }
}

#pragma mark ====================== lazy load =======================

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.multipleTouchEnabled = NO;
        _tableView.sectionHeaderHeight = 25.0f;
        _tableView.sectionFooterHeight = 0.0f;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.backgroundView = [[UIView alloc] initWithFrame:_tableView.bounds];
        _tableView.backgroundView.backgroundColor = BG_TableColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [_tableView registerClass:[WXTextMessageCell class] forCellReuseIdentifier:TextMessageCellID];
        [_tableView registerClass:[WXImageMessageCell class] forCellReuseIdentifier:ImageMessageCellID];
        [_tableView registerClass:[WXSoundMessageCell class] forCellReuseIdentifier:SoundMessageCellID];
        [_tableView registerClass:[WXVideoMessageCell class] forCellReuseIdentifier:VideoMessageCellID];
        [_tableView registerClass:[WXFileMessageCell class] forCellReuseIdentifier:FileMessageCellID];
        [_tableView registerClass:[WXFaceMessageCell class] forCellReuseIdentifier:FaceMessageCellID];
        [_tableView registerClass:[WXLocationMessageCell class] forCellReuseIdentifier:LocationMessageCellID];
        [_tableView registerClass:[WXPromptMessageCell class] forCellReuseIdentifier:PromptMessageCellID];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:UITableViewCellID];
        [_tableView registerClass:[WXMessageHeaderFooterView class] forHeaderFooterViewReuseIdentifier:TimeMessageCellID];
        
        @XOWeakify(self);
        MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            @XOStrongify(self);
            [self loadMessages];
        }];
        [header setTitle:@"" forState:MJRefreshStateIdle];
        header.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        _tableView.mj_header = header;
    }
    return _tableView;
}

- (CALayer *)chatBGLayer
{
    if (!_chatBGLayer) {
        _chatBGLayer = [CALayer layer];
        _chatBGLayer.frame = self.view.bounds;
        _chatBGLayer.contentsGravity = kCAGravityResizeAspectFill;
    }
    return _chatBGLayer;
}

- (NSMutableArray <NSMutableDictionary <NSString *, id>* >*)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (NSMutableDictionary <NSString *, NSIndexPath *>* )sendingMsgQueue
{
    if (!_sendingMsgQueue) {
        _sendingMsgQueue = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return _sendingMsgQueue;
}

- (NSMutableDictionary<NSString *,NSIndexPath *> *)downloadingMsgQueue
{
    if (!_downloadingMsgQueue) {
        _downloadingMsgQueue = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return _downloadingMsgQueue;
}

- (NSMutableArray <TIMMessage *> *)imageVideoList
{
    if (!_imageVideoList) {
        _imageVideoList = [NSMutableArray dictionaryWithCapacity:5];
    }
    return _imageVideoList;
}

- (NSMutableDictionary<NSString *, NSIndexPath *> *)imageVideoIndexpathList
{
    if (!_imageVideoIndexpathList) {
        _imageVideoIndexpathList = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return _imageVideoIndexpathList;
}

- (NSMutableDictionary<NSString *,NSValue *> *)cellSizeDict
{
    if (!_cellSizeDict) {
        _cellSizeDict = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    return _cellSizeDict;
}

- (NSLock *)lock
{
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

- (void)safeAreaDidChange:(UIEdgeInsets)safeAreaInset
{
    _safeInset = safeAreaInset;
}

#pragma mark ========================= private method =========================

// 读取图片消息
- (void)readImageMessageWith:(TIMMessage *)message withCell:(WXMessageCell *)cell
{
    @autoreleasepool {
        // 排序
        NSArray <TIMMessage *>* msgList = [self.imageVideoList allValues];
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
        msgList = [msgList sortedArrayUsingDescriptors:@[descriptor]];
        __block NSMutableArray <NSString *>* msgKeyList = [NSMutableArray arrayWithCapacity:5];
        [msgList enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [msgKeyList addObject:getMessageKey(obj)];
        }];
        NSInteger currentPage = [msgKeyList indexOfObject:getMessageKey(message)];
        
        __block NSMutableArray <id <YBIBDataProtocol>>* sourceList = [NSMutableArray arrayWithCapacity:10];
        [msgKeyList enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            
            TIMMessage *obj = [self.imageVideoList objectForKey:key];
            if ([obj elemCount] > 0) {
                TIMElem *elem = [obj getElem:0];
                // 图片
                if ([elem isKindOfClass:[TIMImageElem class]]) {
                    TIMImageElem *imageElem = (TIMImageElem *)elem;
                    if (imageElem.imageList.count > 0) {
                        TIMImage *timImage = [imageElem.imageList objectAtIndex:0];
                        NSString *imagePath = nil;
                        NSURL *thumbImageURL = nil;
                        if (obj.isSelf) {
                            imagePath = [XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:imageElem.path.lastPathComponent];
                            NSString *thumbImageName = [[imagePath lastPathComponent] stringByReplacingOccurrencesOfString:@"." withString:@"_thumb."];
                            NSString *thumbImagePath = [XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:thumbImageName];
                            thumbImageURL = [NSURL fileURLWithPath:thumbImagePath];
                        }
                        NSLog(@"imagePath: %d", XOIsEmptyString(imagePath));
                        NSLog(@"fileExistsAtPath: %d", [[NSFileManager defaultManager] fileExistsAtPath:imagePath]);
                        if (XOIsEmptyString(imagePath) || ![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                            NSString *imageFomat = [[XOChatClient shareClient] getImageFormat:imageElem.format];
                            NSString *imageName = [NSString stringWithFormat:@"%@.%@", timImage.uuid, imageFomat];
                            imagePath = [XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:imageName];
                            NSString *thumbImageName = [NSString stringWithFormat:@"%@_thumb.%@", timImage.uuid, imageFomat];
                            thumbImageURL = [NSURL fileURLWithPath:[XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:thumbImageName]];
                        }
                        
                        UIImageView * translateView = nil;
                        NSIndexPath *indexPath = [self.imageVideoIndexpathList objectForKey:key];
                        if (indexPath && indexPath.section < self.dataSource.count) {
                            NSArray *arr = [self.dataSource[indexPath.section] objectForKey:MsgSectionListKey];
                            if (indexPath.row < arr.count) {
                                WXMessageCell *msgCell = [self.tableView cellForRowAtIndexPath:indexPath];
                                if ([msgCell isKindOfClass:[WXImageMessageCell class]]) {
                                    translateView = ((WXImageMessageCell *)msgCell).messageImageView;
                                }
                            }
                        }
                        
                        YBIBImageData *imageData = [[YBIBImageData alloc] init];
                        imageData.imagePath = imagePath;
                        imageData.thumbURL = thumbImageURL;
                        imageData.projectiveView = translateView;
                        imageData.extraData = key;
                        [sourceList addObject:imageData];
                    }
                }
                // 视频
                else if ([elem isKindOfClass:[TIMVideoElem class]]) {
                    TIMVideoElem *videoElem = (TIMVideoElem *)elem;
                    UIImage *thumbImage = nil;
                    NSURL *videoURL = nil;
                    if (!obj.isSelf) {
                        videoURL = [NSURL fileURLWithPath:videoElem.videoPath];
                        thumbImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:videoElem.snapshotPath]];
                    }
                    
                    if (!videoURL || ![[NSFileManager defaultManager] fileExistsAtPath:videoElem.videoPath]) {
                        TIMVideo *timVideo = videoElem.video;
                        NSString *videoFomat = !XOIsEmptyString(timVideo.type) ? timVideo.type : @"mp4";
                        NSString *videoName = [NSString stringWithFormat:@"%@.%@", timVideo.uuid, videoFomat];
                        NSString *videoPath = [XOMsgFileDirectory(XOMsgFileTypeVideo) stringByAppendingPathComponent:videoName];
                        videoURL = [NSURL fileURLWithPath:videoPath];
                    }
                    if (XOIsEmptyString(videoElem.snapshotPath) || ![[NSFileManager defaultManager] fileExistsAtPath:videoElem.snapshotPath]) {
                        TIMSnapshot *snapshot = videoElem.snapshot;
                        NSString *snapshotformat = XOIsEmptyString(snapshot.type) ? @"jpg" : snapshot.type;
                        NSString *snapshotName = [NSString stringWithFormat:@"%@.%@", snapshot.uuid, snapshotformat];
                        NSString *snapshotPath = [XOMsgFileDirectory(XOMsgFileTypeVideo) stringByAppendingPathComponent:snapshotName];
                        thumbImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:snapshotPath]];
                    }
                    
                    UIImageView * translateView = nil;
                    NSIndexPath *indexPath = [self.imageVideoIndexpathList objectForKey:key];
                    if (indexPath && indexPath.section < self.dataSource.count) {
                        NSArray *arr = [self.dataSource[indexPath.section] objectForKey:MsgSectionListKey];
                        if (indexPath.row < arr.count) {
                            WXMessageCell *msgCell = [self.tableView cellForRowAtIndexPath:indexPath];
                            if ([msgCell isKindOfClass:[WXVideoMessageCell class]]) {
                                translateView = ((WXVideoMessageCell *)msgCell).messageImageView;
                            }
                        }
                    }
                    
                    YBIBVideoData *videoData = [[YBIBVideoData alloc] init];
                    videoData.videoURL = videoURL;
                    videoData.thumbImage = thumbImage;
                    videoData.projectiveView = translateView;
                    videoData.extraData = key;
                    [sourceList addObject:videoData];
                }
            }
        }];
        
        if (sourceList.count > 0) {
            YBImageBrowser *browser = [[YBImageBrowser alloc] init];
            browser.dataSourceArray = sourceList;
            browser.currentPage = (currentPage > 0) ? currentPage : 0;
            browser.webImageMediator = [[XOImageBrowerMediator alloc] init];
            browser.delegate = self;
            [browser show];
        }
    }
}

// 读取语音消息
- (void)readAudioMessageWith:(TIMMessage *)message withIndex:(NSUInteger)index
{
    // 静音时提示用户打开声音
    CGFloat currentVol = [AVAudioSession sharedInstance].outputVolume;
    if (currentVol == 0) {
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"chat.audio.noVolume", nil)];
        [SVProgressHUD dismissWithDelay:1.0f];
    }
    
    BOOL isMp3Exist = NO;
    NSString *soundPath = nil;
    TIMSoundElem *soundElem = (TIMSoundElem *)[message getElem:0];
    if (message.isSelf) {
        NSString *soundName = [soundElem.path lastPathComponent];
        soundPath = [XOMsgFileDirectory(XOMsgFileTypeAudio) stringByAppendingPathComponent:soundName];
    } else {
        NSString *soundName = [NSString stringWithFormat:@"%@.mp3", soundElem.uuid];
        soundPath = [XOMsgFileDirectory(XOMsgFileTypeAudio) stringByAppendingPathComponent:soundName];
    }
    isMp3Exist = [XOFM fileExistsAtPath:soundPath];
    
    // 音频文件存在
    if (isMp3Exist) {
        [[LGAudioPlayer sharePlayer] stopAudioPlayer];
        [[LGAudioPlayer sharePlayer] playAudioWithURLString:soundPath atIndex:index];
    }
    // 音频文件不存在
    else {
        // 是否正在下载中
        BOOL isDownloading = [[XOChatClient shareClient] isOnDownloading:message];
        BOOL isWaitDownload = [[XOChatClient shareClient] isWaitingDownload:message];
        if (!isDownloading && !isWaitDownload) {
            [[XOChatClient shareClient] scheduleDownloadTask:message];
        }
    }
}

// 读取文件消息
- (void)readFileMessageWith:(TIMMessage *)message
{
    TIMFileElem *fileElem = (TIMFileElem *)[message getElem:0];
    NSString *filename = !XOIsEmptyString(fileElem.filename) ? fileElem.filename : [NSString stringWithFormat:@"%@.unknow", fileElem.uuid];
    NSString *filePath = [XOMsgFileDirectory(XOMsgFileTypeFile) stringByAppendingPathComponent:filename];
    BOOL isFileExist = [XOFM fileExistsAtPath:filePath];
    
    // 文件存在
    if (isFileExist) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        UIDocumentInteractionController *documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        documentInteractionController.delegate = self;
        documentInteractionController.name = filename;
        [documentInteractionController presentPreviewAnimated:YES];
    }
    // 文件不存在
    else {
        // 是否正在下载中
        BOOL isDownloading = [[XOChatClient shareClient] isOnDownloading:message];
        BOOL isWaitDownload = [[XOChatClient shareClient] isWaitingDownload:message];
        if (!isDownloading && !isWaitDownload) {
            // 开启下载
            [[XOChatClient shareClient] scheduleDownloadTask:message];
        }
    }
}

// 读取定位
- (void)readLocationMessageWith:(TIMMessage *)message
{
    TIMLocationElem *locationElem = (TIMLocationElem *)[message getElem:0];
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(locationElem.latitude, locationElem.longitude);
    
    XOLocationViewController *locationVC = [[XOLocationViewController alloc] init];
    locationVC.locationType = XOLocationTypeRecive;
    locationVC.location = location;
    locationVC.address = locationElem.desc;
    [self.navigationController pushViewController:locationVC animated:YES];
}

#pragma mark ====================== UIDocumentInteractionControllerDelegate =======================

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.parentViewController.navigationController;
}
- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller
{
    [[UINavigationBar appearance] setTintColor:AppTinColor];
    [[UINavigationBar appearance] setBarTintColor:AppTinColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor],
                                                           NSFontAttributeName: [UIFont boldSystemFontOfSize:19.0f]}];
}
- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor],
                                                           NSFontAttributeName: [UIFont boldSystemFontOfSize:19.0f]}];
}

#pragma mark ========================= YBImageBrowserDelegate =========================
/**
 页码变化
 
 @param imageBrowser 图片浏览器
 @param page 当前页码
 @param data 数据
 */
- (void)yb_imageBrowser:(YBImageBrowser *)imageBrowser pageChanged:(NSInteger)page data:(id<YBIBDataProtocol>)data
{
    NSIndexPath *indexPath = [self.imageVideoIndexpathList objectForKey:(NSString *)data];
    if (indexPath && indexPath.section < self.dataSource.count) {
        NSArray *arr = [self.dataSource[indexPath.section] objectForKey:MsgSectionListKey];
        if (indexPath.row < arr.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
            });
        }
    }
}

#pragma mark ========================= help =========================

// 根据发送中的消息找到其位置indexpath
- (NSIndexPath *)findIndexPathWithSendingMessage:(TIMMessage *)message
{
    __block NSIndexPath *indexpath = nil;
    NSString *msgKey = getMessageKey(message);
    // 从发送消息队列中找
    if (self.sendingMsgQueue.count > 0) {
        indexpath = [self.sendingMsgQueue objectForKey:msgKey];
    }
    // 如果发送消息队列中没有则从数据源中找
    if (!indexpath) {
        [self.dataSource enumerateObjectsUsingBlock:^(NSMutableDictionary<NSString *,id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSMutableArray <TIMMessage *>* mutArr = dict[MsgSectionListKey];
            __block BOOL needStop = NO;
            [mutArr enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger subIdx, BOOL * _Nonnull subStop) {
                if ([obj.msgId isEqualToString:message.msgId] && [obj.timestamp isEqual:message.timestamp]) {
                    indexpath = [NSIndexPath indexPathForRow:subIdx inSection:idx];
                    needStop = YES;
                    *subStop = YES;
                }
            }];
            *stop = needStop;
        }];
        // 如果找到就缓存到发送消息队列中
        if (indexpath) {
            if ([self.lock tryLock]) {
                [self.sendingMsgQueue setObject:indexpath forKey:msgKey];
                [self.lock unlock];
            }
        }
    }
    return indexpath;
}

// 根据下载中的消息找到其位置indexpath
- (NSIndexPath *)findIndexPathWithDownloadingMessage:(TIMMessage *)message
{
    __block NSIndexPath *indexpath = nil;
    NSString *msgKey = getMessageKey(message);
    // 从下载消息队列中找
    if (self.downloadingMsgQueue.count > 0) {
        indexpath = [self.downloadingMsgQueue objectForKey:msgKey];
    }
    // 如果下载消息队列中没有则从数据源中找
    if (!indexpath) {
        [self.dataSource enumerateObjectsUsingBlock:^(NSMutableDictionary<NSString *,id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSMutableArray <TIMMessage *>* mutArr = dict[MsgSectionListKey];
            __block BOOL needStop = NO;
            [mutArr enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger subIdx, BOOL * _Nonnull subStop) {
                if ([obj.msgId isEqualToString:message.msgId] && [obj.timestamp isEqual:message.timestamp]) {
                    indexpath = [NSIndexPath indexPathForRow:subIdx inSection:idx];
                    needStop = YES;
                    *subStop = YES;
                }
            }];
            *stop = needStop;
        }];
        // 如果找到就缓存到下载消息队列中
        if (indexpath) {
            if ([self.lock tryLock]) {
                [self.downloadingMsgQueue setObject:indexpath forKey:msgKey];
                [self.lock unlock];
            }
        }
    }
    return indexpath;
}

- (CGSize)messageSize:(TIMMessage *)message
{
    CGFloat standradW = (SCREEN_WIDTH < SCREEN_HEIGHT) ? SCREEN_WIDTH : SCREEN_HEIGHT;
    
    if (0 == [message elemCount]) {
        return CGSizeMake(standradW * 0.6, 56.0f);
    }
    
    // 1、从缓存中取值
    NSString *uniqueKey = getMessageKey(message);
    NSValue *sizeValueCache = [self.cellSizeDict valueForKey:uniqueKey];
    if (sizeValueCache) {
        return [sizeValueCache CGSizeValue];
    }
    
    // 2、缓存中没有就计算高度
    TIMElem *elem = [message getElem:0];
    CGSize size = CGSizeMake((standradW * 0.6), 56.0f);
    CGFloat height = 56.0f;
    
    // 文字消息
    if ([elem isKindOfClass:[TIMTextElem class]] ||
        [elem isKindOfClass:[TIMCustomElem class]])
    {
        UILabel *label = [[UILabel alloc] init];
        [label setNumberOfLines:0];
        [label setFont:[UIFont systemFontOfSize:16.0f]];
        // 筛选 emoji
        NSString *messageStr = @"";
        if ([elem isKindOfClass:[TIMTextElem class]]) messageStr = ((TIMTextElem *)elem).text;
        else {
            NSData *data = ((TIMCustomElem *)elem).data;
            messageStr = (data.length > 0) ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        }
        NSMutableAttributedString *text = [ZXChatHelper formatMessageString:messageStr].mutableCopy;
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 3; // 调整行间距
        [text addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];
        label.attributedText = text;
        CGFloat maxWidth = standradW - (10 + 40 + 5) * 2 - 40;
        size = [label sizeThatFits:CGSizeMake(maxWidth, MAXFLOAT)];
        
        CGFloat aboutH = size.height + 18 + MsgCellIconMargin * 2; // label的高度加上 距离泡泡上下边距之和 和 泡泡距离cell上下边距之和
        CGFloat relHeight = aboutH <= height ? height : aboutH;
        size = CGSizeMake(size.width, relHeight);
    }
    // 图片|视频消息
    else if ([elem isKindOfClass:[TIMVideoElem class]] ||
             [elem isKindOfClass:[TIMImageElem class]])
    {
        float sizew = ImageWidth;  // 图片的宽度
        float sizeh = ImageHeight;  // 图片的高度
        size = CGSizeZero;
        
        if ([elem isKindOfClass:[TIMImageElem class]]) {
            TIMImageElem *imageElem = (TIMImageElem *)elem;
            if (imageElem.imageList.count > 0) {
                TIMImage *image = [imageElem.imageList objectAtIndex:0];
                sizew = image.width;
                sizeh = image.height;
            }
        }
        else if ([elem isKindOfClass:[TIMVideoElem class]]) {
            TIMVideoElem *videoElem = (TIMVideoElem *)elem;
            if (videoElem.snapshot) {
                sizew = videoElem.snapshot.width;
                sizeh = videoElem.snapshot.height;
            }
        }
        
        float maxWid = standradW * 0.3;
        if (sizew <= maxWid) {
            size = CGSizeMake(sizew, sizeh);
        } else {
            if (sizew > sizeh) {
                float resizeh = (maxWid/sizew) * sizeh;
                size = CGSizeMake(maxWid, resizeh);
            } else {
                float resizeW = (maxWid/sizeh) * sizew;
                size = CGSizeMake(resizeW, maxWid);
            }
        }
        
        CGFloat relHeight = (size.height + MsgCellIconMargin * 2 <= height) ? height : size.height + MsgCellIconMargin * 2;
        size = CGSizeMake(size.width, relHeight);
    }
    // 文件消息
    else if ([elem isKindOfClass:[TIMFileElem class]])
    {
        size = CGSizeMake(FileWidth + 16, FileHeight + MsgCellIconMargin * 2);
    }
    // 语音消息
    else if ([elem isKindOfClass:[TIMSoundElem class]])
    {
        TIMSoundElem *soundElem = (TIMSoundElem *)elem;
        int duration = soundElem.second;
        float width = (80 + duration * 5) < standradW * 0.6 ? 80 + duration * 5 : standradW * 0.6;
        size = CGSizeMake(width, 40 + MsgCellIconMargin * 2);
    }
    // 位置消息
    else if ([elem isKindOfClass:[TIMLocationElem class]])
    {
        TIMLocationElem *locationElem = (TIMLocationElem *)[message getElem:0];
        UILabel *label = [[UILabel alloc] init];
        [label setNumberOfLines:0];
        [label setFont:[UIFont systemFontOfSize:16.0f]];
        label.text = locationElem.desc;
        CGFloat maxWidth = standradW - (10 + 40 + 5) * 2 - 40 - 23;
        size = [label sizeThatFits:CGSizeMake(maxWidth, MAXFLOAT)];
        CGFloat aboutH = size.height + 18 + MsgCellIconMargin * 2; // label的高度加上 距离泡泡上下边距之和 和 泡泡距离cell上下边距之和
        CGFloat relHeight = aboutH <= height ? height : aboutH;
        
        size = CGSizeMake(size.width, relHeight);
    }
    // 表情消息
    else if ([elem isKindOfClass:[TIMFaceElem class]])
    {
        TIMFaceElem *faceElem = (TIMFaceElem *)[message getElem:0];
        if (faceElem.data.length > 0) {
            NSString *groupId = [[NSString alloc] initWithData:faceElem.data encoding:NSUTF8StringEncoding];
            int faceIndex = faceElem.index;
            if (!XOIsEmptyString(groupId)) {
                NSArray <ChatFace *> * chatFaceArray = [[ChatFaceHelper sharedFaceHelper].faceGroupsSet objectForKey:groupId];
                if (chatFaceArray.count > faceIndex) {
                    ChatFace *face = [chatFaceArray objectAtIndex:faceIndex];
                    NSURL *url = [[NSBundle xo_chatResourceBundle] URLForResource:face.faceID withExtension:@"gif"];
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
                    
                    size = CGSizeMake(animatedImage.size.width/2.0 + 16, animatedImage.size.height/2.0 + MsgCellIconMargin * 2);
                }
            }
        }
    }
    // 提示消息
    else if ([elem isKindOfClass:[TIMGroupTipsElem class]] ||
             [elem isKindOfClass:[TIMGroupTipsElemMemberInfo class]] ||
             [elem isKindOfClass:[TIMGroupSystemElem class]])
    {
        NSAttributedString *text = (NSAttributedString *)[elem getTextFromMessage];
        CGFloat height = [text boundingRectWithSize:CGSizeMake(self.view.width - 30, MAXFLOAT) options:0|1 context:nil].size.height;
        size = CGSizeMake(self.view.width - 30, height + 20);
    }
    
    // 3、保存到缓存中
    NSValue *sizeValue = [NSValue valueWithCGSize:size];
    [self.cellSizeDict setValue:sizeValue forKey:uniqueKey];
    
    return size;
}


@end




#pragma mark ========================= XOImageBrowerMediator =========================

@implementation XOImageBrowerMediator

- (id)yb_downloadImageWithURL:(NSURL *)URL requestModifier:(nullable YBIBWebImageRequestModifierBlock)requestModifier progress:(nonnull YBIBWebImageProgressBlock)progress success:(nonnull YBIBWebImageSuccessBlock)success failed:(nonnull YBIBWebImageFailedBlock)failed
{
    if (!URL) return nil;
    
    SDWebImageContext *context = nil;
    if (requestModifier) {
        SDWebImageDownloaderRequestModifier *modifier = [SDWebImageDownloaderRequestModifier requestModifierWithBlock:requestModifier];
        context = @{SDWebImageContextDownloadRequestModifier:modifier};
    }
    
    SDWebImageDownloaderOptions options = SDWebImageDownloaderLowPriority | SDWebImageDownloaderAvoidDecodeImage;
    
    SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:URL options:options context:context progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        if (progress) progress(receivedSize, expectedSize);
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (error) {
            if (failed) failed(error, finished);
        } else {
            if (success) success(data, finished);
        }
    }];
    return token;
}

- (void)yb_cancelTaskWithDownloadToken:(id)token
{
    if (token && [token isKindOfClass:SDWebImageDownloadToken.class]) {
        [((SDWebImageDownloadToken *)token) cancel];
    }
}

- (void)yb_storeToDiskWithImageData:(NSData *)data forKey:(NSURL *)key
{
    if (!key) return;
    NSString *cacheKey = [SDWebImageManager.sharedManager cacheKeyForURL:key];
    if (!cacheKey) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:cacheKey];
    });
}

- (void)yb_queryCacheOperationForKey:(NSURL *)key completed:(YBIBWebImageCacheQueryCompletedBlock)completed
{
#define QUERY_CACHE_FAILED if (completed) {completed(nil, nil); return;}
    if (!key) QUERY_CACHE_FAILED
        NSString *cacheKey = [SDWebImageManager.sharedManager cacheKeyForURL:key];
    if (!cacheKey) QUERY_CACHE_FAILED
#undef QUERY_CACHE_FAILED
        
        // 'NSData' of image must be read to ensure decoding correctly.
        SDImageCacheOptions options = SDImageCacheQueryMemoryData | SDImageCacheAvoidDecodeImage;
    [[SDImageCache sharedImageCache] queryCacheOperationForKey:cacheKey options:options done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        if (completed) completed(image, data);
    }];
}

@end
