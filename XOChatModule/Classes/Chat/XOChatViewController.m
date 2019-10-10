//
//  XOChatViewController.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOChatViewController.h"
#import "XOChatBoxViewController.h"
#import "XOChatMessageController.h"

#import "XOChatModule.h"

@interface XOChatViewController () <XOChatBoxViewControllerDelegate, XOChatMessageControllerDelegate>
{
    UIEdgeInsets   _safeInsets;
}

@property (nonatomic, copy) NSString    * receiver;
@property (nonatomic, strong) XOChatBoxViewController * chatBoxVC;
@property (nonatomic, strong) XOChatMessageController * chatMsgVC;

@end

@implementation XOChatViewController

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    [self.view setBackgroundColor:BG_TableColor];
    [self setHidesBottomBarWhenPushed:YES];
    
    // 聊天对象的userId或者groupId
    self.receiver = [self.conversation getReceiver];
    
    [self initialization];
    
    [self setupSubViews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (_chatBoxVC.view.top == 0) {
        [_chatBoxVC.view setFrame:CGRectMake(0, self.view.height - HEIGHT_TABBAR - _safeInsets.bottom, self.view.width, self.view.height)];
    } else {
        [_chatBoxVC.view setFrame:CGRectMake(0, _chatBoxVC.view.top, self.view.width, self.view.height)];
    }
    _chatMsgVC.view.y = 0;
    _chatMsgVC.view.height = _chatBoxVC.view.y;
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    
    _safeInsets = self.view.safeAreaInsets;
    _chatBoxVC.view.top = self.view.height - HEIGHT_TABBAR - _safeInsets.bottom;
    [_chatBoxVC safeAreaDidChange:self.view.safeAreaInsets];
    [_chatMsgVC safeAreaDidChange:self.view.safeAreaInsets];
}

- (void)initialization
{
    if (TIM_GROUP == self.chatType) {
        self.title = self.conversation.getGroupName;
    } else if (TIM_C2C == self.chatType) {
        TIMFriend *friend = [[TIMManager sharedInstance].friendshipManager queryFriend:self.receiver];
        if (XOIsEmptyString(friend.remark)) {
            if (XOIsEmptyString(friend.profile.nickname)) {
                self.title = self.receiver;
            } else {
                self.title = friend.profile.nickname;
            }
        } else {
            self.title = friend.remark;
        }
    }
}

- (void)setupSubViews
{
    [self addChildViewController:self.chatMsgVC];
    [self.view addSubview:self.chatMsgVC.view];
    
    [self addChildViewController:self.chatBoxVC];
    [self.view addSubview:self.chatBoxVC.view];
}

#pragma mark ====================== lazy load =======================

- (XOChatBoxViewController *)chatBoxVC
{
    if (!_chatBoxVC) {
        _chatBoxVC = [[XOChatBoxViewController alloc] init];
        _chatBoxVC.chatType = self.chatType;
        [_chatBoxVC setDelegate:self];
    }
    return _chatBoxVC;
}

- (XOChatMessageController *)chatMsgVC
{
    if (!_chatMsgVC) {
        _chatMsgVC = [[XOChatMessageController alloc] init];
        _chatMsgVC.conversation = self.conversation;
        _chatMsgVC.chatType = self.chatType;
        [_chatMsgVC setDelegate:self];
    }
    return _chatMsgVC;
}

#pragma mark ====================== XOChatBoxViewControllerDelegate =======================

// chatBoxView 高度改变
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController didChangeChatBoxHeight:(CGFloat)height duration:(float)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.chatBoxVC.view.y = self.view.height - height;
        self.chatMsgVC.view.height = self.chatBoxVC.view.y;
    }];
    [self.view setNeedsLayout];
}
// 用户输入了 @ 群聊有用
- (void)chatBoxViewControllerInputAtSymbol:(XOChatBoxViewController *)chatboxViewController
{
    
}

// 发送Gif表情
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendGifwithGroup:(NSString *)groupID face:(int)faceIndex
{
    TIMFaceElem *faceElem = [[TIMFaceElem alloc] init];
    faceElem.index = faceIndex;
    if (!XOIsEmptyString(groupID)) {
        faceElem.data = [groupID dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    TIMMessage *faceMsg = [[TIMMessage alloc] init];
    int result = [faceMsg addElem:faceElem];
    
    if (0 == result) {
        @XOWeakify(self);
        int sendFace = [self.conversation sendMessage:faceMsg succ:^{
            @XOStrongify(self);
            [self.chatMsgVC sendSuccessMessage:faceMsg];
        } fail:^(int code, NSString *msg) {
            @XOStrongify(self);
            [self.chatMsgVC sendFailMessage:faceMsg];
        }];
        
        // 将消息显示出来
        if(0 == sendFace) {
            [self.chatMsgVC sendingMessage:faceMsg];
        } else {
            NSLog(@"发送文本消息失败 sendFace: %d", sendFace);
        }
    }
    else {
        NSLog(@"添加文本消息失败  result: %d", result);
    }
}
// 发送文字消息
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendTextMessage:(NSString *)content
{
    TIMTextElem *textElem = [[TIMTextElem alloc] init];
    textElem.text = content;
    TIMMessage *textMsg = [[TIMMessage alloc] init];
    int result = [textMsg addElem:textElem];
    
    if (0 == result) {
        @XOWeakify(self);
        int sendText = [self.conversation sendMessage:textMsg succ:^{
            @XOStrongify(self);
            [self.chatMsgVC sendSuccessMessage:textMsg];
        } fail:^(int code, NSString *msg) {
            @XOStrongify(self);
            [self.chatMsgVC sendFailMessage:textMsg];
        }];
        
        // 将消息显示出来
        if(0 == sendText) {
            [self.chatMsgVC sendingMessage:textMsg];
        } else {
            NSLog(@"发送文本消息失败 sendText: %d", sendText);
        }
    }
    else {
        NSLog(@"添加文本消息失败  result: %d", result);
    }
}
// 发送图片消息
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendImage:(NSString *)imagePath imageSize:(CGSize)size imageFormat:(nonnull NSString *)format
{
    TIMImageElem *imageElem = [[TIMImageElem alloc] init];
    imageElem.path = imagePath;
    imageElem.format = [self getImageFormat:format];
    TIMMessage *imageMsg = [[TIMMessage alloc] init];
    int result = [imageMsg addElem:imageElem];
    
    if (0 == result) {
        @XOWeakify(self);
        int sendImage = [self.conversation sendMessage:imageMsg succ:^{
            @XOStrongify(self);
            [self.chatMsgVC sendSuccessMessage:imageMsg];
        } fail:^(int code, NSString *msg) {
            @XOStrongify(self);
            [self.chatMsgVC sendFailMessage:imageMsg];
        }];
        
        // 将消息显示出来
        if (0 == sendImage) {
            [self.chatMsgVC sendingMessage:imageMsg];
        } else {
            NSLog(@"发送图片消息失败 sendImage: %d", sendImage);
        }
    }
    else {
        NSLog(@"添加图片消息失败  result: %d", result);
    }
}
// 发送视频消息
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendVideo:(NSString *)videoPath snapshotImage:(nonnull NSString *)snapshotPath snapshotSize:(CGSize)size videoDuration:(float)duration
{
    // 视频
    TIMVideo *video = [[TIMVideo alloc] init];
    video.duration = (int)duration;
    video.type = @"mp4";
    // 视频截图
    TIMSnapshot *snapshot = [[TIMSnapshot alloc] init];
    snapshot.type = @"jpg";
    snapshot.width = size.width;
    snapshot.height = size.height;
    // 视频消息 Elem
    TIMVideoElem *videoElem = [[TIMVideoElem alloc] init];
    videoElem.videoPath = videoPath;
    videoElem.snapshotPath = snapshotPath;
    videoElem.video = video;
    videoElem.snapshot = snapshot;
    // 视频消息
    TIMMessage *videoMsg = [[TIMMessage alloc] init];
    int result = [videoMsg addElem:videoElem];
    
    // 发送消息
    if (0 == result) {
        @XOWeakify(self);
        int sendVideo = [self.conversation sendMessage:videoMsg succ:^{
            @XOStrongify(self);
            [self.chatMsgVC sendSuccessMessage:videoMsg];
        } fail:^(int code, NSString *msg) {
            @XOStrongify(self);
            [self.chatMsgVC sendFailMessage:videoMsg];
        }];
        
        // 将消息显示出来
        if(0 == sendVideo) {
            [self.chatMsgVC sendingMessage:videoMsg];
        } else {
            NSLog(@"发送视频消息失败 sendVideo: %d", sendVideo);
        }
    }
    else {
        NSLog(@"添加视频消息失败: %d", result);
    }
}
// 发送语音消息
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendMp3Audio:(NSString *)mp3Path soundSize:(long)soundSize audioDuration:(NSTimeInterval)duration
{
    TIMSoundElem *soundElem = [[TIMSoundElem alloc] init];
    soundElem.path = mp3Path;
    soundElem.dataSize = (int)soundSize;
    soundElem.second = duration;
    // 语音消息
    TIMMessage *soundMsg = [[TIMMessage alloc] init];
    int result = [soundMsg addElem:soundElem];
    // 发送消息
    if (0 == result) {
        @XOWeakify(self);
        int sendSound = [self.conversation sendMessage:soundMsg succ:^{
            @XOStrongify(self);
            [self.chatMsgVC sendSuccessMessage:soundMsg];
        } fail:^(int code, NSString *msg) {
            @XOStrongify(self);
            [self.chatMsgVC sendFailMessage:soundMsg];
        }];
        
        // 将消息显示出来
        if(0 == sendSound) {
            [self.chatMsgVC sendingMessage:soundMsg];
        } else {
            NSLog(@"发送语音消息失败 sendSound: %d", sendSound);
        }
    }
    else {
        NSLog(@"添加语音消息失败: %d", result);
    }
}
// 发送文件消息
- (void)chatBoxViewControllerSendFile:(XOChatBoxViewController *)chatboxViewController sendFile:(NSString *)filePath filename:(NSString *)filename fileSize:(int)fileSize
{
    TIMFileElem *fileElem = [[TIMFileElem alloc] init];
    fileElem.path = filePath;
    fileElem.fileSize = fileSize;
    fileElem.filename = filename;
    // 文件消息
    TIMMessage *fileMsg = [[TIMMessage alloc] init];
    int result = [fileMsg addElem:fileElem];
    // 发送消息
    if (0 == result) {
        @XOWeakify(self);
        int sendFile = [self.conversation sendMessage:fileMsg succ:^{
            @XOStrongify(self);
            [self.chatMsgVC sendSuccessMessage:fileMsg];
        } fail:^(int code, NSString *msg) {
            @XOStrongify(self);
            [self.chatMsgVC sendFailMessage:fileMsg];
        }];
        
        // 将消息显示出来
        if(0 == sendFile) {
            [self.chatMsgVC sendingMessage:fileMsg];
        } else {
            NSLog(@"发送文件消息失败 sendSound: %d", sendFile);
        }
    }
    else {
        NSLog(@"添加文件消息失败: %d", result);
    }
}
// 发送位置消息
- (void)chatBoxViewControllerSendPosition:(XOChatBoxViewController *)chatboxViewController sendLocationLatitude:(double)latitude longitude:(double)longitude addressDesc:(nonnull NSString *)address
{
    TIMLocationElem *locationElem = [[TIMLocationElem alloc] init];
    locationElem.desc = address;
    locationElem.latitude = latitude;
    locationElem.longitude = longitude;
    // 位置消息
    TIMMessage *locationMsg = [[TIMMessage alloc] init];
    int result = [locationMsg addElem:locationElem];
    // 发送消息
    if (0 == result) {
        @XOWeakify(self);
        int sendLocation = [self.conversation sendMessage:locationMsg succ:^{
            @XOStrongify(self);
            [self.chatMsgVC sendSuccessMessage:locationMsg];
        } fail:^(int code, NSString *msg) {
            @XOStrongify(self);
            [self.chatMsgVC sendFailMessage:locationMsg];
        }];
        
        // 将消息显示出来
        if(0 == sendLocation) {
            [self.chatMsgVC sendingMessage:locationMsg];
        } else {
            NSLog(@"发送位置消息失败 sendLocation: %d", sendLocation);
        }
    }
    else {
        NSLog(@"添加位置消息失败: %d", result);
    }
}
// 发送名片消息
- (void)chatBoxViewControllerSendCarte:(XOChatBoxViewController *)chatboxViewController
{
    
}
// 发送音视频消息
- (void)chatBoxViewControllerSendCall:(XOChatBoxViewController *)chatboxViewController
{
    
}
// 发送红包消息
- (void)chatBoxViewControllerSendRedPacket:(XOChatBoxViewController *)chatboxViewController
{
    
}
// 发送转账消息
- (void)chatBoxViewControllerSendTransfer:(XOChatBoxViewController *)chatboxViewController
{
    
}

#pragma mark ========================= XOChatMessageControllerDelegate =========================

// 点击了聊天列表页面
- (void) didTapChatMessageView:(XOChatMessageController *)chatMsgViewController
{
    [self.chatBoxVC resignFirstResponder];
}
// @某人
- (void) didAtSomeOne:(NSString *)nick userId:(NSString *)userId
{
    // 群聊 @nick   (可能是陌生人)
    if (TIM_GROUP == self.chatType) {
        [self.chatBoxVC addAtSomeOne:[NSString stringWithFormat:@"@%@ ", nick]];
    }
}
// 拆红包
- (void) didReadRedPacketMessage:(TIMMessage *)message indexpath:(NSIndexPath *)indexPath ChatMessageView:(XOChatMessageController *)chatMsgViewController
{
    
}
// 收转账
- (void) didReadTransferMessage:(TIMMessage *)message indexpath:(NSIndexPath *)indexPath ChatMessageView:(XOChatMessageController *)chatMsgViewController
{
    
}


#pragma mark ========================= help =========================

// 获取图片的格式
- (TIM_IMAGE_FORMAT)getImageFormat:(NSString *)format
{
    TIM_IMAGE_FORMAT imageFormat = TIM_IMAGE_FORMAT_UNKNOWN;
    
    NSString *uniteFormat = [format lowercaseString];
    if ([uniteFormat hasSuffix:@"jpg"] || [uniteFormat hasSuffix:@"jpeg"]) {
        imageFormat = TIM_IMAGE_FORMAT_JPG;
    }
    else if ([uniteFormat hasSuffix:@"png"]) {
        imageFormat = TIM_IMAGE_FORMAT_PNG;
    }
    else if ([uniteFormat hasSuffix:@"gif"]) {
        imageFormat = TIM_IMAGE_FORMAT_GIF;
    }
    else if ([uniteFormat hasSuffix:@"bmp"]) {
        imageFormat = TIM_IMAGE_FORMAT_BMP;
    }
    return imageFormat;
}

@end
