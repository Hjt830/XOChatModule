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
    float   _safeAreaTop;
    float   _safeAreaBottom;
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
        [_chatBoxVC.view setFrame:CGRectMake(0, self.view.height - HEIGHT_TABBAR, KWIDTH, KHEIGHT)];
    } else {
        [_chatBoxVC.view setFrame:CGRectMake(0, _chatBoxVC.view.top, KWIDTH, KHEIGHT)];
    }
    _chatMsgVC.view.y = 0;
    _chatMsgVC.view.height = _chatBoxVC.view.y;
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    
    _safeAreaTop = self.view.safeAreaInsets.top;
    _safeAreaBottom = self.view.safeAreaInsets.bottom;
    _chatBoxVC.view.top = self.view.height - HEIGHT_TABBAR - _safeAreaBottom;
    [_chatBoxVC safeAreaDidChange:self.view.safeAreaInsets];
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
    [textMsg addElem:textElem];
    
    @weakify(self);
    int sendText = [self.conversation sendMessage:textMsg succ:^{
        NSLog(@"发送成功");
        @strongify(self);
        [self.chatMsgVC updateMessage:textMsg];
    } fail:^(int code, NSString *msg) {
        NSLog(@"发送失败");
        @strongify(self);
        [self.chatMsgVC updateMessage:textMsg];
    }];
    if(1 == sendText) NSLog(@"发送文本消息失败!!!");
    
    // 将消息显示出来
    [self.chatMsgVC addMessage:textMsg];
}

// 发送图片消息
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendImage:(NSString *)imagePath imageSize:(CGSize)size imageFormat:(nonnull NSString *)format
{
    TIMImageElem *imageElem = [[TIMImageElem alloc] init];
    imageElem.path = imagePath;
    imageElem.format = [self getImageFormat:format];
    TIMMessage *imageMsg = [[TIMMessage alloc] init];
    [imageMsg addElem:imageElem];
    
    @weakify(self);
    int sendText = [self.conversation sendMessage:imageMsg succ:^{
        NSLog(@"发送成功");
        @strongify(self);
        [self.chatMsgVC updateMessage:imageMsg];
    } fail:^(int code, NSString *msg) {
        NSLog(@"发送失败");
        @strongify(self);
        [self.chatMsgVC updateMessage:imageMsg];
    }];
    if(1 == sendText) NSLog(@"发送图片消息失败!!!");
    
    // 将消息显示出来
    [self.chatMsgVC addMessage:imageMsg];
}

- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendVideo:(NSURL *)videoUrl videoDuration:(float)duration
{
    
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
