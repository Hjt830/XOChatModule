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

static float const ImageWidth = 1080.0f;    // 图片的宽度
static float const ImageHeight = 1920.0;    // 图片的高度
static float const FileWidth = 220.0f;      // 文件的宽度
static float const FileHeight = 80.0f;      // 文件的高度

@interface XOChatMessageController () <UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate, XOMessageDelegate, LGAudioPlayerDelegate, WXMessageCellDelegate>
{
    long _historyTime;  // 查询记录的开始时间
}
@property (nonatomic, strong) CALayer   * chatBGLayer;
@property (nonatomic, strong) UITableView                       *tableView;     // 会话列表
@property (nonatomic, strong) MJRefreshNormalHeader             *refreshView;   // 下拉刷新
@property (nonatomic, strong) NSMutableArray    <NSDictionary *>*dataSource;    // 数据源
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
        [[XOChatClient shareClient].messageManager addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)dealloc
{
    [[XOChatClient shareClient].messageManager removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    // 添加消息列表
    [self.view addSubview:self.tableView];
    [self.tableView setMj_header:self.refreshView];
    // 添加聊天背景
    [self showPreviewChatBGImage];
    // 加载消息
    [self.refreshView beginRefreshing];
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
    
    self.tableView.frame = self.view.bounds;
    self.tableView.backgroundView.frame = self.tableView.bounds;
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

- (void)loadMessages
{
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        
        // 拉取历史消息
        TIMMessage *lastMsg = self.conversation.getLastMsg;
        [self.conversation getMessage:20 last:lastMsg succ:^(NSArray *msgs) {
            [self.refreshView endRefreshing];
            
            NSError *error = nil;
            NSArray <TIMMessage *>* array = msgs;
            
            // 查询消息失败
            if (error) {
                NSLog(@"查询消息失败");
            }
            else {
                if (!XOIsEmptyArray(array)) {
                    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
                    array = [array sortedArrayUsingDescriptors:@[descriptor]];
                    
                    __block BOOL isFirstPage = (self->_historyTime <= 0);
                    // 处理数据
                    NSArray *dataArray = [self handleDataSource:array];
                    if ([self.lock tryLock]) {
                        // 查询第一页, 清空数据源
                        if (isFirstPage) {
                            [self.dataSource removeAllObjects];
                            [self.dataSource addObjectsFromArray:dataArray];
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                                [self.tableView beginUpdates];
                                [self.tableView reloadData];
                                
                                // 滑动到底部
                                if (!XOIsEmptyArray(self.dataSource)) {
                                    NSMutableArray *mutarr = [[self.dataSource lastObject] objectForKey:MsgSectionListKey];
                                    if (!XOIsEmptyArray(mutarr)) {
                                        NSUInteger section = self.dataSource.count - 1;
                                        NSUInteger row = mutarr.count - 1;
                                        NSIndexPath *indexpath = [NSIndexPath indexPathForRow:row inSection:section];
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.18 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            [self.tableView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                                        });
                                    }
                                }
//                                [self.tableView endUpdates];
                            }];
                        }
                        else {
                            __block NSMutableIndexSet *sets = [NSMutableIndexSet indexSet];
                            [dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                [sets addIndex:idx];
                            }];
                            [self.dataSource insertObjects:dataArray atIndexes:sets];
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [self.refreshView endRefreshing];
                                
                                [self.tableView beginUpdates];
                                [self.tableView insertSections:sets withRowAnimation:UITableViewRowAnimationNone];
                                [self.tableView endUpdates];
                            }];
                        }
                        
                        // 记录查询时间
                        self->_historyTime = (long)[[array firstObject].timestamp timeIntervalSince1970];
                        
                        [self.lock unlock];
                    }
                }
                else {
                    if (!XOIsEmptyArray(self.dataSource)) {
                        [SVProgressHUD showInfoWithStatus:@"没有更多消息了"];
                        [SVProgressHUD dismissWithDelay:0.5f];
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self.refreshView endRefreshing];
                            [self.refreshView removeFromSuperview];
                        }];
                    }
                }
            }
            
        } fail:^(int code, NSString *msg) {
            [self.refreshView endRefreshing];
            NSLog(@"---------- %s 拉取历史消息失败！！！  code: %d, msg: %@", __func__, code, msg);
        }];
        
    }];
}

#pragma mark ====================== 数据处理 =======================

// 处理消息，根据时间分组
- (NSArray *)handleDataSource:(NSArray <TIMMessage *>*)array
{
    if (XOIsEmptyArray(array)) {
        return nil;
    }
    
    // 消息间隔超过5分钟则加一个时间, 并分组
    __block NSMutableArray *dataArray = [NSMutableArray array];
    __block long long startTime = [[array firstObject].timestamp timeIntervalSince1970];
    __block NSMutableArray <TIMMessage *>* mutArr = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 计算与 **上一个时间分组起止时间** 的间隔时间
        long long msgTime = [obj.timestamp timeIntervalSince1970];
        long long timeSpace = msgTime - startTime;
        
        // 时间间隔小于5分钟时, 加入同一个分组 且 消息有内容
        if (timeSpace < 5 * 60 * 1000 && [obj elemCount] > 0) {
            [mutArr addObject:obj];
            
            // 如果最后一条消息在这个分组内, 则在此处保存
            if (idx == array.count - 1) {
                // 根据消息的本地发送时间进行分组内排序 （确保与发送端的消息顺序一致）
                NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
                [mutArr sortedArrayUsingDescriptors:@[descriptor]];
                NSDictionary *msgDict = @{MsgSectionTimeKey : @(startTime),
                                          MsgSectionListKey : [mutArr mutableCopy]};
                [dataArray addObject:msgDict];
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
            NSDictionary *msgDict = @{MsgSectionTimeKey : @(startTime),
                                      MsgSectionListKey : [mutArr mutableCopy]};
            [dataArray addObject:msgDict];
            [mutArr removeAllObjects];
            mutArr = nil;
            
            // 重置 **上一个时间分组起止时间**
            startTime = (long long)[obj.timestamp timeIntervalSince1970];
            // 新建下一个分组
            mutArr = [NSMutableArray array];
            [mutArr addObject:obj];
        }
    }];
    
    return dataArray;
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
        else if ([elem isKindOfClass:[TIMFaceElem class]]) {
            cell = [tableView dequeueReusableCellWithIdentifier:VideoMessageCellID forIndexPath:indexPath];
        }
        else if ([elem isKindOfClass:[TIMGroupTipsElem class]] ||
                 [elem isKindOfClass:[TIMGroupTipsElemMemberInfo class]] ||
                 [elem isKindOfClass:[TIMGroupSystemElem class]])
        {
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
    }
    return _tableView;
}

- (MJRefreshNormalHeader *)refreshView
{
    if (_refreshView == nil) {
        @XOWeakify(self);
        _refreshView = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            @XOStrongify(self);
            [self loadMessages];
        }];
        _refreshView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    }
    return _refreshView;
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

- (NSMutableArray *)dataSource
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

#pragma mark ========================= help =========================

- (CGSize)messageSize:(TIMMessage *)message
{
    if (0 == [message elemCount]) {
        return CGSizeMake(KWIDTH * 0.6, 70.0f);
    }
    
    // 1、从缓存中取值
    NSString *uniqueKey = [NSString stringWithFormat:@"%@_%ld", message.msgId, (long)[message.timestamp timeIntervalSince1970]];
    NSValue *sizeValueCache = [self.cellSizeDict valueForKey:uniqueKey];
    if (sizeValueCache) {
        return [sizeValueCache CGSizeValue];
    }
    
    // 2、缓存中没有就计算高度
    TIMElem *elem = [message getElem:0];
    CGSize size = CGSizeMake((KWIDTH * 0.6), 70.0f);
    CGFloat height = 70.0f;
    
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
        size = [label sizeThatFits:CGSizeMake(KWIDTH * 0.58, MAXFLOAT)];
        
        CGFloat relHeight = (size.height + 40 <= height) ? height : size.height + 40;
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
        float width = (100 + duration * 5) < KWIDTH * 0.6 ? 100 + duration * 5 : KWIDTH * 0.6;
        size = CGSizeMake(width, 50.0f);
    }
    // 图片|视频消息
    else if ([elem isKindOfClass:[TIMVideoElem class]] ||
             [elem isKindOfClass:[TIMImageElem class]])
    {
        CGSize elemSize = CGSizeMake(ImageWidth, ImageHeight);
        float sizew = ImageWidth;
        float sizeh = ImageHeight;
        if ([elem isKindOfClass:[TIMImageElem class]]) {
            TIMImageElem *imageElem = (TIMImageElem *)elem;
            if (imageElem.imageList.count > 0) {
                TIMImage *image = [imageElem.imageList objectAtIndex:0];
                sizew = image.width;
                sizeh = image.height;
            }
        } else {
            TIMVideoElem *videoElem = (TIMVideoElem *)elem;
            elemSize = CGSizeMake(videoElem.snapshot.width, videoElem.snapshot.height);
            sizew = videoElem.snapshot.width;
            sizeh = videoElem.snapshot.height;
        }
        
        float maxWid = KWIDTH * 0.5;
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
