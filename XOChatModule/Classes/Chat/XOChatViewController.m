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
#import "XODocumentPickerViewController.h"

#import "XOChatModule.h"

@interface XOChatViewController () <XOChatBoxViewControllerDelegate, XOChatMessageControllerDelegate, UIDocumentPickerDelegate>
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

// 发送文字消息
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendMessage:(NSString *)content
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
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendMp3Audio:(NSString *)mp3Path audioDuration:(NSTimeInterval)duration
{
    
}
- (void)chatBoxViewControllerSendPosition:(XOChatBoxViewController *)chatboxViewController
{
    
}
- (void)chatBoxViewControllerSendCall:(XOChatBoxViewController *)chatboxViewController
{
    
}
- (void)chatBoxViewControllerSendRedPacket:(XOChatBoxViewController *)chatboxViewController
{
    
}
- (void)chatBoxViewControllerSendTransfer:(XOChatBoxViewController *)chatboxViewController
{
    
}
- (void)chatBoxViewControllerSendCarte:(XOChatBoxViewController *)chatboxViewController
{
    
}
- (void)chatBoxViewControllerSendFile:(XOChatBoxViewController *)chatboxViewController
{
    NSArray *documentTypes = @[@"public.text", @"public.plain-text",
                               @"com.adobe.pdf",
                               @"com.microsoft.word.doc", @"org.openxmlformats.wordprocessingml.document",
                               @"com.microsoft.excel.xls", @"org.openxmlformats.spreadsheetml.sheet",
                               @"com.microsoft.powerpoint.ppt", @"org.openxmlformats.presentationml.presentation",
                               @"public.audio",
                               @"public.archive",
                               @"public.image",
                               @"public.source-code", @"public.script", @"public.shell-script",
                               @"com.apple.application", @"com.apple.bundle", @"com.apple.package",
                               @"public.composite-​content"];
    XODocumentPickerViewController *documentVC = [[XODocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeOpen];
    if (@available(iOS 11.0, *)) {
        documentVC.allowsMultipleSelection = NO;
    }
    documentVC.modalPresentationStyle = UIModalPresentationFullScreen;
    documentVC.delegate = self;
    [self.navigationController presentViewController:documentVC animated:YES completion:nil];
}

- (void)dismissDocument:(UIButton *)sender
{
    NSLog(@"%@ %@", self.navigationController.topViewController, self.navigationController.presentedViewController);
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

#pragma mark =========================== UIDocumentPickerDelegate ===========================

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls NS_AVAILABLE_IOS(11_0)
{
    [urls enumerateObjectsUsingBlock:^(NSURL * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        
        BOOL canAccessingResource = [url startAccessingSecurityScopedResource];
        if(canAccessingResource) {
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
            NSError *error;
            __block NSURL *fileUrl = nil;
            [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&error byAccessor:^(NSURL *newURL) {
                fileUrl = newURL;
                [controller dismissViewControllerAnimated:YES completion:nil];
            }];
            if (error) {
                NSLog(@"读取文件失败: %@", error);
            } else {
                [self sendFileMessageWithUrl:fileUrl];
            }
        } else {
            [SVProgressHUD showInfoWithStatus:XOChatLocalizedString(@"tip.chat.file.fail")];
            [SVProgressHUD dismissWithDelay:0.6];
        }
        [url stopAccessingSecurityScopedResource];
    }];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url NS_DEPRECATED_IOS(8_0, 11_0)
{
    BOOL canAccessingResource = [url startAccessingSecurityScopedResource];
    if (canAccessingResource) {
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        NSError *error;
        __block NSURL *fileUrl = nil;
        [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&error byAccessor:^(NSURL *newURL) {
            fileUrl = newURL;
            [controller dismissViewControllerAnimated:YES completion:nil];
        }];
        if (error) {
            NSLog(@"读取文件失败: %@", error);
        } else {
            [self sendFileMessageWithUrl:fileUrl];
        }
    } else {
        [SVProgressHUD showInfoWithStatus:XOChatLocalizedString(@"tip.chat.file.fail")];
        [SVProgressHUD dismissWithDelay:0.6];
    }
    [url stopAccessingSecurityScopedResource];
}

- (void)sendFileMessageWithUrl:(NSURL *)fileUrl
{
    if (!XOIsEmptyString(fileUrl.absoluteString)) {
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            BOOL canAccessingResource = [fileUrl startAccessingSecurityScopedResource];
            if (canAccessingResource) {
                NSData *data = [NSData dataWithContentsOfURL:fileUrl];
                long long fileSize = data.length;
                if ([[NSFileManager defaultManager] fileExistsAtPath:fileUrl.path] && fileSize < 20 * 1024 * 1024) {  // 文件大小不能超过20M
                    // 发送文件
                    NSString *fileName = [[fileUrl path] lastPathComponent];
                    // 图片消息
                    if ([fileName hasSuffix:@".png"] || [fileName hasSuffix:@".jpg"] || [fileName hasSuffix:@".jpeg"]) {
                        NSData *imageData = [NSData dataWithContentsOfURL:fileUrl];
                        if (imageData.length > 0) {
//                            CGSize size = [UIImage imageWithData:imageData].size;
                            
                        } else {
                            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"error.unknown", nil)];
                            [SVProgressHUD dismissWithDelay:0.6f];
                        }
                    }
                    // 文件消息
                    else {
                        
                    }
                }
            }
            [fileUrl stopAccessingSecurityScopedResource];
        }];
    }
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
