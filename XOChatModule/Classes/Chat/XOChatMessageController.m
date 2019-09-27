//
//  XOChatMessageController.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOChatMessageController.h"
#import "ZXChatHelper.h"

#import "XOChatClient.h"
#import "WXTextMessageCell.h"
#import "WXImageMessageCell.h"
#import "WXSoundMessageCell.h"
#import "WXVideoMessageCell.h"
#import "WXFileMessageCell.h"
#import "WXLocationMessageCell.h"
#import "WXPromptMessageCell.h"

#import "LGAudioKit.h"
#import <SVProgressHUD/SVProgressHUD.h>

static NSString * const MsgSectionTimeKey = @"timeSection";
static NSString * const MsgSectionListKey = @"messageList";

static NSString * const TimeMessageCellID       = @"TimeMessageCellID";
static NSString * const TextMessageCellID       = @"TextMessageCellID";
static NSString * const ImageMessageCellID      = @"ImageMessageCellID";
static NSString * const SoundMessageCellID      = @"SoundMessageCellID";
static NSString * const VideoMessageCellID      = @"VideoMessageCellID";
static NSString * const FileMessageCellID       = @"FileMessageCellID";
static NSString * const LocationMessageCellID   = @"LocationMessageCellID";
static NSString * const CarteMessageCellID      = @"CarteMessageCellID";
static NSString * const WalletMessageCellID     = @"WalletMessageCellID";
static NSString * const UITableViewCellID       = @"UITableViewCellID";
static NSString * const PromptMessageCellID     = @"PromptMessageCellID";

static int const MessageTimeSpaceMinute = 5;    // 消息时间间隔时间 单位:分钟

@interface XOChatMessageController () <UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate, XOChatClientProtocol, XOMessageDelegate, LGAudioPlayerDelegate, WXMessageCellDelegate>
{
    TIMMessage          *_earliestMsg;  // 最早的一条消息
    UIEdgeInsets        _safeInset;
}
@property (nonatomic, strong) CALayer   * chatBGLayer;
@property (nonatomic, strong) UITableView                       *tableView;     // 会话列表
@property (nonatomic, strong) MJRefreshNormalHeader             *refreshView;   // 下拉刷新
@property (nonatomic, strong) NSMutableArray    <NSMutableDictionary <NSString *, id>* >*dataSource;    // 数据源
@property (nonatomic, strong) NSLock                            *lock;          // 线程锁
@property (nonatomic, assign) NSUInteger                        page;           // 数据的页数
@property (nonatomic, strong) NSMutableDictionary   <NSString *, NSIndexPath *> *updateIndexDict;    // 保存更新进度时的消息位置信息
@property (nonatomic, strong) NSMutableDictionary   <NSString *, NSValue *> *cellSizeDict;    // 保存cell的高度

@property (nonatomic, strong) AVPlayer                          *player;        // 视频播放器
@property (nonatomic, strong) AVPlayerItem                      *playerItem;    // 视频播放器
@property (nonatomic, strong) AVPlayerLayer                     *playerLayer;   // 视频播放器

@end

@implementation XOChatMessageController

- (instancetype)init
{
    self = [super init];
    if (self) {
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
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
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
                [self.tableView scrollToRow:(list.count - 1) inSection:lastSection atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
    @weakify(self);
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        @strongify(self);
        
        NSLog(@"%@  --- %@", self->_earliestMsg, self->_earliestMsg.timestamp);
        
        [self.conversation getMessage:20 last:self->_earliestMsg succ:^(NSArray *msgs) {
            @strongify(self);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.refreshView endRefreshing];
            }];
            
            NSArray <TIMMessage *>* array = msgs;
            if (!XOIsEmptyArray(array)) {
                
                NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
                array = [array sortedArrayUsingDescriptors:@[descriptor]];
                __block BOOL isFirstPage = (self->_earliestMsg == nil);
                // 处理数据
                NSArray *dataArray = [self handleDataSource:array];
                if ([self.lock tryLock]) {
                    // 查询第一页, 清空数据源
                    if (isFirstPage) {
                        [self.dataSource removeAllObjects];
                        [self.dataSource addObjectsFromArray:dataArray];
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self.tableView reloadData];
                            
                            // 滑动到底部
                            if (self.dataSource.count > 0) {
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    NSInteger lastSection = self.dataSource.count - 1;
                                    NSArray *list = [self.dataSource[lastSection] objectForKey:MsgSectionListKey];
                                    if (list.count > 0) {
                                        @try {
                                            [self.tableView scrollToRow:(list.count - 1) inSection:lastSection atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                                        } @catch (NSException *exception) {
                                            NSLog(@"%s --- 滑动到最底部异常: %@", __func__, exception);
                                        } @finally {
                                            
                                        }
                                    }
                                });
                            }
                        }];
                    }
                    else {
                        __block NSMutableIndexSet *sets = [NSMutableIndexSet indexSet];
                        [dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            [sets addIndex:idx];
                        }];
                        [self.dataSource insertObjects:dataArray atIndexes:sets];
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            
                            [self.tableView beginUpdates];
                            [self.tableView insertSections:sets withRowAnimation:UITableViewRowAnimationNone];
                            [self.tableView endUpdates];
                        }];
                    }
                    
                    [self.lock unlock];
                }
                // 记录
                self->_earliestMsg = [array firstObject];
            }
            else {
                if (!XOIsEmptyArray(self.dataSource)) {
                    [SVProgressHUD showInfoWithStatus:@"没有更多消息了"];
                    [SVProgressHUD dismissWithDelay:0.5f];
                }
            }
            
        } fail:^(int code, NSString *msg) {
            [self.refreshView endRefreshing];
            NSLog(@"---------- %s 拉取历史消息失败！！！  code: %d, msg: %@", __func__, code, msg);
        }];
        
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
                // 根据消息的本地发送时间进行分组内排序 （确保与发送端的消息顺序一致）
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
        }
    }];
    
    return dataArray;
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
        @synchronized (self) {
            [self.dataSource addObject:mutMsgDict];
        }
        [self.tableView insertSection:(self.dataSource.count - 1) withRowAnimation:UITableViewRowAnimationBottom];
        indexpath = [NSIndexPath indexPathForRow:0 inSection:(self.dataSource.count - 1)];
    }
    // 2、如果插入的消息时间比最小的消息分组的时间小5分钟, 则在最前面插入一组
    else if (minSpace > 0 && minSpace > MessageTimeSpaceMinute * 60 * 1000) {
        NSMutableArray *mutArr = [NSMutableArray array];
        [mutArr addObject:message];
        NSMutableDictionary *mutMsgDict = @{MsgSectionTimeKey : @(msgTime),
                                            MsgSectionListKey : mutArr}.mutableCopy;
        @synchronized (self) {
            [self.dataSource insertObject:mutMsgDict atIndex:0];
        }
        [self.tableView insertSection:0 withRowAnimation:UITableViewRowAnimationTop];
        indexpath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    // 3、如果插入的消息时间在 {最小时间, 最大时间} 范围内
    else {
        // 遍历消息数组, 插入消息
        @synchronized (self) {
            @weakify(self);
            [self.dataSource enumerateObjectsUsingBlock:^(NSMutableDictionary <NSString *, id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
                @strongify(self);
                // 获取分组的时间
                NSUInteger sectionTime = [dict[MsgSectionTimeKey] unsignedIntegerValue];
                long long timeSpace = msgTime - sectionTime;
                
                // 如果插入的消息时间在 {上一个消息分组时间 + 5min, 当前消息分组时间}, 则新建分组并插入
                if (timeSpace < 0) {
                    NSMutableArray *mutArr = [NSMutableArray array];
                    [mutArr addObject:message];
                    NSMutableDictionary *mutMsgDict = @{MsgSectionTimeKey : @(msgTime),
                                                        MsgSectionListKey : mutArr}.mutableCopy;
                    @synchronized (self) {
                        [self.dataSource insertObject:mutMsgDict atIndex:idx];
                    }
                    [self.tableView insertSection:idx withRowAnimation:UITableViewRowAnimationBottom];
                    indexpath = [NSIndexPath indexPathForRow:0 inSection:idx];
                    
                    *stop = YES;
                }
                // 如果插入的消息时间在 {当前消息分组时间, 当前消息分组时间 + 5min}, 则插入到该分组
                else if (timeSpace >= 0 && timeSpace < MessageTimeSpaceMinute * 60 * 1000) {
                    NSMutableArray <TIMMessage *>* mutArr = dict[MsgSectionListKey];
                    [mutArr addObject:message];
                    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
                    [mutArr sortedArrayUsingDescriptors:@[descriptor]];
                    NSUInteger row = [mutArr indexOfObject:message];
                    [self.tableView insertRow:row inSection:idx withRowAnimation:UITableViewRowAnimationBottom];
                    indexpath = [NSIndexPath indexPathForRow:row inSection:idx];
                    
                    *stop = YES;
                }
            }];
        }
    }
    
    return indexpath;
}

// 删除消息
- (void)deleteMessage:(TIMMessage *)message
{
    @weakify(self);
    [self.dataSource enumerateObjectsUsingBlock:^(NSMutableDictionary<NSString *,id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        
        NSMutableArray <TIMMessage *>* mutArr = dict[MsgSectionListKey];
        __block BOOL needStop = NO;
        [mutArr enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger subIdx, BOOL * _Nonnull subStop) {
           
            if ([obj.msgId isEqualToString:message.msgId] && [obj.timestamp isEqual:message.timestamp]) {
                [mutArr removeObject:obj];
                [self.tableView deleteRow:subIdx inSection:idx withRowAnimation:UITableViewRowAnimationAutomatic];
                
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
    @weakify(self);
    [self.dataSource enumerateObjectsUsingBlock:^(NSMutableDictionary<NSString *,id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        
        NSMutableArray <TIMMessage *>* mutArr = dict[MsgSectionListKey];
        __block BOOL needStop = NO;
        [mutArr enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger subIdx, BOOL * _Nonnull subStop) {
            
            if ([obj.msgId isEqualToString:message.msgId] && [obj.timestamp isEqual:message.timestamp]) {
                [mutArr replaceObjectAtIndex:subIdx withObject:message];
                [self.tableView reloadRow:subIdx inSection:idx withRowAnimation:UITableViewRowAnimationAutomatic];
                
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
        TIMMessage *message = [self.dataSource[indexPath.section] objectForKey:MsgSectionListKey][indexPath.row];
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
//        else if ([elem isKindOfClass:[TIMFaceElem class]]) {
//            cell = [tableView dequeueReusableCellWithIdentifier:VideoMessageCellID forIndexPath:indexPath];
//        }
        else if ([elem isKindOfClass:[TIMGroupTipsElem class]] ||
                 [elem isKindOfClass:[TIMGroupTipsElemMemberInfo class]] ||
                 [elem isKindOfClass:[TIMGroupSystemElem class]])
        {
            cell = [tableView dequeueReusableCellWithIdentifier:PromptMessageCellID forIndexPath:indexPath];
        }
        else {
            cell = [tableView dequeueReusableCellWithIdentifier:PromptMessageCellID forIndexPath:indexPath];
        }
        
        WXMessageCell *msgCell = (WXMessageCell *)cell;
        msgCell.delegate = self;
        msgCell.message = message;
        
        return cell;
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:UITableViewCellID forIndexPath:indexPath];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TIMMessage *message = [self.dataSource[indexPath.section] objectForKey:MsgSectionListKey][indexPath.row];
    CGFloat msgHei = [self messageSize:message].height;
    return msgHei;
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

#pragma mark =========================== LGAudioPlayerDelegate ===========================

- (void)audioPlayerStateDidChanged:(LGAudioPlayerState)audioPlayerState forIndex:(NSUInteger)index
{
    NSUInteger section = 0, row = 0;
    if (index < 10000) {
        section = 0;
        row = index;
    } else {
        section = index/10000;
        row = index%10000;
    }
    NSIndexPath *indexpath = [NSIndexPath indexPathForRow:row inSection:section];
    @try {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            WXSoundMessageCell *cell = [self.tableView cellForRowAtIndexPath:indexpath];
            if (cell) cell.playState = audioPlayerState;
        }];
    } @catch (NSException *exception) {
        NSLog(@"exception: %@", exception);
    } @finally {
        
    }
}

#pragma mark ========================= XOChatClientProtocol =========================

- (void)xoOnNewMessage:(NSArray<TIMMessage *> *)msgs
{
    [msgs enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.sender isEqualToString:[self.conversation getReceiver]]) {
            BOOL filter = [self filterMessage:obj];
            if (filter) {
                NSLog(@"消息被剔除, 因为该条消息已经被撤回或删除");
            }
            else {
                [self addMessage:obj];
            }
        }
    }];
}

- (void)message:(TIMMessage *)message downloadProgress:(float)progress
{
    [self updateProgress:progress withMessage:message];
}

- (void)messageFileDownloadSuccess:(TIMMessage *)message fileURL:(NSURL *)fileURL thumbImageURL:(NSURL *)thumbImageURL
{
    
}

- (void)messageFileDownloadFail:(TIMMessage *)message failError:(NSError *)error
{
    
}

- (void)messageFileUpload:(TIMMessage *)message progress:(float)progress
{
    [self updateProgress:progress withMessage:message];
}

- (void)updateProgress:(float)progress withMessage:(TIMMessage *)message
{
    __block NSIndexPath *indexpath = nil;
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
{}
// 长按了用户头像
- (void)messageCellLongPressAvatar:(WXMessageCell *)cell message:(TIMMessage *)message
{}
// 点击了消息
- (void)messageCellDidTapMessage:(WXMessageCell *)cell message:(TIMMessage *)message
{}
// 长按了消息
- (void)messageCellLongPressMessage:(WXMessageCell *)cell message:(TIMMessage *)message
{}
// 点击了重发消息
- (void)messageCellDidTapResendMessage:(WXMessageCell *)cell message:(TIMMessage *)message
{}


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
        _tableView.backgroundView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [_tableView registerClass:[WXTextMessageCell class] forCellReuseIdentifier:TextMessageCellID];
        [_tableView registerClass:[WXImageMessageCell class] forCellReuseIdentifier:ImageMessageCellID];
        [_tableView registerClass:[WXSoundMessageCell class] forCellReuseIdentifier:SoundMessageCellID];
        [_tableView registerClass:[WXVideoMessageCell class] forCellReuseIdentifier:VideoMessageCellID];
        [_tableView registerClass:[WXFileMessageCell class] forCellReuseIdentifier:FileMessageCellID];
        [_tableView registerClass:[WXLocationMessageCell class] forCellReuseIdentifier:LocationMessageCellID];
        [_tableView registerClass:[WXPromptMessageCell class] forCellReuseIdentifier:PromptMessageCellID];
        [_tableView registerClass:[WXMessageHeaderFooterView class] forHeaderFooterViewReuseIdentifier:TimeMessageCellID];
        
        @XOWeakify(self);
        _refreshView = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            @XOStrongify(self);
            [self loadMessages];
        }];
        _refreshView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        _tableView.mj_header = _refreshView;
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

- (NSMutableDictionary <NSString *, NSIndexPath *>* )updateIndexDict
{
    if (!_updateIndexDict) {
        _updateIndexDict = [NSMutableDictionary dictionaryWithCapacity:15];
    }
    return _updateIndexDict;
}

- (NSMutableDictionary<NSString *,NSValue *> *)cellSizeDict
{
    if (!_cellSizeDict) {
        _cellSizeDict = [NSMutableDictionary dictionaryWithCapacity:15];
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

#pragma mark ========================= help =========================

- (CGSize)messageSize:(TIMMessage *)message
{
    CGFloat standradW = (KWIDTH < KHEIGHT) ? KWIDTH : KHEIGHT;
    
    if (0 == [message elemCount]) {
        return CGSizeMake(standradW * 0.6, 70.0f);
    }
    
    // 1、从缓存中取值
    NSString *uniqueKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
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
        size = [label sizeThatFits:CGSizeMake(standradW * 0.58, MAXFLOAT)];
        
        CGFloat relHeight = (size.height + 36 <= height) ? height : size.height + 36;
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
        
        CGFloat relHeight = (size.height + 17 <= height) ? height : size.height + 17;
        size = CGSizeMake(size.width, relHeight);
    }
    // 文件消息
    else if ([elem isKindOfClass:[TIMFileElem class]])
    {
        size = CGSizeMake(FileWidth + 16, FileHeight + 20);
    }
    // 语音消息
    else if ([elem isKindOfClass:[TIMSoundElem class]])
    {
        TIMSoundElem *soundElem = (TIMSoundElem *)elem;
        int duration = soundElem.second;
        float width = (100 + duration * 5) < standradW * 0.6 ? 100 + duration * 5 : standradW * 0.6;
        size = CGSizeMake(width, 50.0f);
    }
    // 位置消息
    else if ([elem isKindOfClass:[TIMLocationElem class]])
    {
        size = CGSizeMake(FileWidth + 16, FileHeight + 20);
    }
    // 表情消息
    else if ([elem isKindOfClass:[TIMFaceElem class]])
    {
        size = CGSizeMake(FileWidth + 16, FileHeight + 20);
    }
    // 提示消息
    else if ([elem isKindOfClass:[TIMGroupTipsElem class]] ||
             [elem isKindOfClass:[TIMGroupTipsElemMemberInfo class]] ||
             [elem isKindOfClass:[TIMGroupSystemElem class]])
    {
        size = CGSizeMake(FileWidth + 16, FileHeight + 20);
    }
    
    // 3、保存到缓存中
    NSValue *sizeValue = [NSValue valueWithCGSize:size];
    [self.cellSizeDict setValue:sizeValue forKey:uniqueKey];
    
    return size;
}


@end
