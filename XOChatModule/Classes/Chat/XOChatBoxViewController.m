//
//  XOChatBoxViewController.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOChatBoxViewController.h"

#import <TZImagePickerController/TZImagePickerController.h>
#import <Photos/Photos.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "ZXChatBoxView.h"
#import "ZXChatBoxFaceView.h"
#import "ZXChatBoxMoreView.h"
#import "LGAudioKit.h"
#import "ConvertWavToMp3.h"
#import "XOChatModule.h"

static NSTimeInterval MaxAudioRecordTime = 60.0f;
static NSTimeInterval audioRecordTime = 0.0f;

@interface XOChatBoxViewController () <ZXChatBoxDelegate, ZXChatBoxMoreViewDelegate, ZXChatBoxFaceViewDelegate, LGSoundRecorderDelegate, TZImagePickerControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    int                 _seconds;   // 录音时间
    UIEdgeInsets        _safeInset;
}
@property (nonatomic, assign) CGFloat                   lastHeight;
@property (nonatomic, assign) CGRect                    keyboardFrame;
@property (nonatomic, strong) ZXChatBoxView             *chatBox;
@property (nonatomic, strong) ZXChatBoxMoreView         *chatBoxMoreView;
@property (nonatomic, strong) ZXChatBoxFaceView         *chatBoxFaceView;
@property (nonatomic, strong) TZImagePickerController   *TZImagePicker;
@property (nonatomic, strong) UIImagePickerController   *imagePicker;
@property (nonatomic, strong) dispatch_source_t         timer; // 定时器

@end

@implementation XOChatBoxViewController

#pragma mark ========================= 构造 & 析构 =========================

- (instancetype)init
{
    self = [super init];
    if (self) {
        _seconds = 0;
        self.lastHeight = 0.0f;
    }
    return self;
}

- (void)dealloc
{
    if (nil != _timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    NSLog(@"%s", __func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = DEFAULT_CHATBOX_COLOR;
    [self.view addSubview:self.chatBox];
    
    [LGSoundRecorder shareInstance].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.chatBox.height = HEIGHT_TABBAR + _safeInset.bottom;
    self.chatBox.width = self.view.width;
    self.chatBoxFaceView.width = self.view.width - (_safeInset.left + _safeInset.right);
    self.chatBoxMoreView.width = self.view.width - (_safeInset.left + _safeInset.right);
    [self.chatBox setNeedsLayout];
    [self.chatBoxFaceView setNeedsLayout];
    [self.chatBoxMoreView setNeedsLayout];
}

#pragma mark ====================== lazy load =======================

- (ZXChatBoxView *) chatBox
{
    if (_chatBox == nil) {
        _chatBox = [[ZXChatBoxView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, HEIGHT_TABBAR)];
        [_chatBox setDelegate:self];
    }
    return _chatBox;
}

- (ZXChatBoxFaceView *) chatBoxFaceView
{
    if (_chatBoxFaceView == nil) {
        _chatBoxFaceView = [[ZXChatBoxFaceView alloc] initWithFrame:CGRectMake(0, HEIGHT_TABBAR, self.view.width, HEIGHT_CHATBOXVIEW)];
        [_chatBoxFaceView setDelegate:self];
    }
    return _chatBoxFaceView;
}

// 添加创建更多View
- (ZXChatBoxMoreView *) chatBoxMoreView
{
    if (_chatBoxMoreView == nil) {
        ZXChatBoxItemView *albumItem = [ZXChatBoxItemView createChatBoxMoreItemWithTitle:XOChatLocalizedString(@"chat.more.album") imageName:@"more_pic"];       // 相册
        ZXChatBoxItemView *cameraItem = [ZXChatBoxItemView createChatBoxMoreItemWithTitle:XOChatLocalizedString(@"chat.more.camera") imageName:@"more_camera"];      // 相机
        ZXChatBoxItemView *callItem = [ZXChatBoxItemView createChatBoxMoreItemWithTitle:XOChatLocalizedString(@"chat.more.voice.call") imageName:@"more_call"];// 通话
        ZXChatBoxItemView *positionItem = [ZXChatBoxItemView createChatBoxMoreItemWithTitle:XOChatLocalizedString(@"chat.more.location") imageName:@"more_position"];  // 位置
        ZXChatBoxItemView *videoItem = [ZXChatBoxItemView createChatBoxMoreItemWithTitle:XOChatLocalizedString(@"chat.more.video") imageName:@"more_video"];     // 视频
        ZXChatBoxItemView *redPacketItem = [ZXChatBoxItemView createChatBoxMoreItemWithTitle:XOChatLocalizedString(@"chat.more.redPacket") imageName:@"more_redpacket"]; // 红包
        ZXChatBoxItemView *transferItem = [ZXChatBoxItemView createChatBoxMoreItemWithTitle:XOChatLocalizedString(@"chat.more.transfer") imageName:@"more_transfer"];   // 转账
        ZXChatBoxItemView *CarteItem = [ZXChatBoxItemView createChatBoxMoreItemWithTitle:XOChatLocalizedString(@"chat.more.carte") imageName:@"more_carte"];    // 名片
        ZXChatBoxItemView *fileItem = [ZXChatBoxItemView createChatBoxMoreItemWithTitle:XOChatLocalizedString(@"chat.more.file") imageName:@"more_file"];       // 文件
        
        _chatBoxMoreView = [[ZXChatBoxMoreView alloc] initWithFrame:CGRectMake(0, HEIGHT_TABBAR, KWIDTH, HEIGHT_CHATBOXVIEW)];
        _chatBoxMoreView.delegate = self;
        if (TIM_C2C == self.chatType) { // 单聊
            [_chatBoxMoreView setItems:[[NSMutableArray alloc] initWithObjects:albumItem, cameraItem, callItem, positionItem, videoItem, redPacketItem, transferItem, CarteItem, fileItem, nil]];
        }
        else if (TIM_GROUP == self.chatType) { // 群聊
            [_chatBoxMoreView setItems:[[NSMutableArray alloc] initWithObjects:albumItem, cameraItem, callItem, positionItem, videoItem, redPacketItem, CarteItem, fileItem, nil]];
        }
    }
    return _chatBoxMoreView;
}

- (TZImagePickerController *)TZImagePicker
{
    if (_TZImagePicker == nil) {
        _TZImagePicker = [[TZImagePickerController alloc] initWithMaxImagesCount:9 columnNumber:3 delegate:self];
        _TZImagePicker.isSelectOriginalPhoto = NO;
        _TZImagePicker.statusBarStyle = UIStatusBarStyleLightContent;
        _TZImagePicker.maxImagesCount = 9;
        _TZImagePicker.videoMaximumDuration = 15;
        // 2. 在这里设置imagePickerVc的外观
        _TZImagePicker.iconThemeColor = AppTinColor;
        _TZImagePicker.navigationBar.barTintColor = AppTinColor;
        _TZImagePicker.navigationBar.tintColor = [UIColor whiteColor];
        _TZImagePicker.oKButtonTitleColorDisabled = MainPurpleLightColor;
        _TZImagePicker.oKButtonTitleColorNormal = AppTinColor;
        // 3. 设置是否可以选择视频/图片/原图
        _TZImagePicker.allowPickingOriginalPhoto = YES;
        // 4. 照片排列按修改时间升序
        _TZImagePicker.sortAscendingByModificationDate = YES;
        // 5. 设置语言
        NSString *language = [XOSettingManager defaultManager].language;
        if (!XOIsEmptyString(language) && ![language isEqualToString:@"default"]) {
            if ([language isEqualToString:@"zh"]) {
                _TZImagePicker.preferredLanguage = @"zh-Hans";
            } else if ([language isEqualToString:@"en"]) {
                _TZImagePicker.preferredLanguage = @"en";
            }
        } else {
            // 否则就是默认为系统语言
        }
    }
    return _TZImagePicker;
}

- (UIImagePickerController *)imagePicker
{
    if (!_imagePicker) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.modalPresentationStyle = UIModalPresentationOverFullScreen;
        _imagePicker.delegate = self;
        _imagePicker.navigationBar.barTintColor = AppTinColor;
        _imagePicker.navigationBar.tintColor = [UIColor whiteColor];
    }
    return _imagePicker;
}

- (dispatch_source_t)timer
{
    if (!_timer) {
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        // 设置定时器的各种属性
        dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)); // 启动时间比当前晚0.0秒，即马上启动
        uint64_t interval = (uint64_t)(1.0 * NSEC_PER_SEC); // 执行间隔时间
        dispatch_source_set_timer(_timer, start, interval, 0);
        // 设置事件回调
        @weakify(self);
        dispatch_source_set_event_handler(_timer, ^{
            @strongify(self);
            
            self->_seconds++;
            if ([LGSoundRecorder shareInstance].soundRecordTime >= MaxAudioRecordTime) {
                // 结束定时器
                dispatch_source_cancel(self->_timer);
                self->_timer = nil;
                // 结束录音
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    audioRecordTime = [LGSoundRecorder shareInstance].soundRecordTime;
                    [[LGSoundRecorder shareInstance] stopSoundRecord:self.view];
                }];
            }
            else if ([LGSoundRecorder shareInstance].soundRecordTime >= (MaxAudioRecordTime - 10)) {
                // 倒计时提示
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    int countDown = (int)(MaxAudioRecordTime - [LGSoundRecorder shareInstance].soundRecordTime);
                    [[LGSoundRecorder shareInstance] showCountdown:countDown];
                }];
            }
        });
    }
    return _timer;
}

#pragma mark ====================== noti =======================
/**
 *  点击了 textView 的时候，这个方法的调用是比  - (void) :(UITextView *)textView 要早的。
 */
- (void)keyboardWillShow:(NSNotification *)noti
{
    self.keyboardFrame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (_chatBox.status == TLChatBoxStatusShowKeyboard && self.keyboardFrame.size.height <= HEIGHT_CHATBOXVIEW) {
        return;
    }
    else if ((_chatBox.status == TLChatBoxStatusShowFace || _chatBox.status == TLChatBoxStatusShowMore) && self.keyboardFrame.size.height <= HEIGHT_CHATBOXVIEW) {
        return;
    }
    
    float duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
        // 改变控制器.View 的高度 键盘的高度 + 当前的 49
        [self.delegate chatBoxViewController:self didChangeChatBoxHeight:(self.keyboardFrame.size.height + self.chatBox.curHeight - self.chatBox.safeInset.bottom) duration:duration];
    }
}

- (void)keyboardWillHide:(NSNotification *)noti
{
    self.keyboardFrame = CGRectZero;
    if (_chatBox.status == TLChatBoxStatusShowFace || _chatBox.status == TLChatBoxStatusShowMore) {
        return;
    }
    
    float duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
        [self.delegate chatBoxViewController:self didChangeChatBoxHeight:self.chatBox.curHeight duration:duration];
    }
}

#pragma mark ====================== ZXChatBoxDelegate =======================
/**
 *  发送消息调用这个代理方法
 */
- (void) chatBox:(ZXChatBoxView *)chatBox sendTextMessage:(NSString *)textMessage
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:sendMessage:)]) {
        [self.delegate chatBoxViewController:self sendMessage:textMessage];
    }
}

- (void)chatBox:(ZXChatBoxView *)chatBox changeChatBoxHeight:(CGFloat)height
{
    if (self.lastHeight == 0 || self.lastHeight == height) {
        self.chatBoxFaceView.y = height - self.chatBox.safeInset.bottom;
        self.chatBoxMoreView.y = height - self.chatBox.safeInset.bottom;
    } else {
        self.chatBoxFaceView.y += (height - self.lastHeight);
        self.chatBoxMoreView.y += (height - self.lastHeight);
    }
    self.lastHeight = height;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
        // 改变 控制器高度
        float h = (self.chatBox.status == TLChatBoxStatusShowFace ? HEIGHT_CHATBOXVIEW + self.chatBox.safeInset.bottom : self.keyboardFrame.size.height) + height - self.chatBox.safeInset.bottom;
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
            [self.delegate chatBoxViewController:self didChangeChatBoxHeight:h duration:0.25];
        }
    }
}

// 用户输入了 @ 符号
- (void)chatBoxDidInputAtSymbol:(ZXChatBoxView *)chatBox
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewControllerInputAtSymbol:)]) {
        [self.delegate chatBoxViewControllerInputAtSymbol:self];
    }
}

/**
 *  代理方法，传递状态改变要显示那个view
 */
- (void) chatBox:(ZXChatBoxView *)chatBox changeStatusForm:(ZXChatBoxStatus)fromStatus to:(ZXChatBoxStatus)toStatus
{
    if (toStatus == TLChatBoxStatusShowKeyboard) {      // 显示键盘 删除FaceView 和 MoreView
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.chatBoxFaceView removeFromSuperview];
            [self.chatBoxMoreView removeFromSuperview];
        });
        
        return;
    }
    else if (toStatus == TLChatBoxStatusShowVoice)
    {
        // 显示语音输入按钮
        // 从显示更多或表情状态 到 显示语音状态需要动画
        if (fromStatus == TLChatBoxStatusShowMore || fromStatus == TLChatBoxStatusShowFace) {
            [UIView animateWithDuration:0.25 animations:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
                    
                    [self.delegate chatBoxViewController:self didChangeChatBoxHeight:(HEIGHT_TABBAR + self.chatBox.safeInset.bottom) duration:0.25];
                }
            } completion:^(BOOL finished) {
                
                [self.chatBoxFaceView removeFromSuperview];
                [self.chatBoxMoreView removeFromSuperview];
            }];
        }
        else {
            
            [UIView animateWithDuration:0.25 animations:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
                    
                    [self.delegate chatBoxViewController:self didChangeChatBoxHeight:(HEIGHT_TABBAR + self.chatBox.safeInset.bottom) duration:0.25];
                }
            }];
        }
    }
    else if (toStatus == TLChatBoxStatusShowFace)
    {
        /**
         *   变化到展示 表情View 的状态，这个过程中，根据 fromStatus 区分，要是是声音和无状态改变过来的，则高度变化是一样的。 其他的高度就是另外一种，根据 fromStatus 来进行一个区分。
         */
        if (fromStatus == TLChatBoxStatusShowVoice || fromStatus == TLChatBoxStatusNothing) {
            
            [self.chatBoxFaceView setY:self.chatBox.curHeight - self.chatBox.safeInset.bottom];
            // 添加表情View
            [self.view addSubview:self.chatBoxFaceView];
            [UIView animateWithDuration:0.25 animations:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
                    [self.delegate chatBoxViewController:self didChangeChatBoxHeight:self.chatBox.curHeight + HEIGHT_CHATBOXVIEW duration:0.25];
                }
            }];
        }
        else {
            // 表情高度变化
            self.chatBoxFaceView.y = self.chatBox.curHeight + HEIGHT_CHATBOXVIEW;
            [self.view addSubview:self.chatBoxFaceView];
            [UIView animateWithDuration:0.25 animations:^{
                self.chatBoxFaceView.y = self.chatBox.curHeight - self.chatBox.safeInset.bottom;
            } completion:^(BOOL finished) {
                [self.chatBoxMoreView removeFromSuperview];
            }];
            // 整个界面高度变化
            if (fromStatus != TLChatBoxStatusShowMore) {
                [UIView animateWithDuration:0.2 animations:^{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
                        [self.delegate chatBoxViewController:self didChangeChatBoxHeight:self.chatBox.curHeight + HEIGHT_CHATBOXVIEW duration:0.25];
                    }
                }];
            }
        }
    }
    else if (toStatus == TLChatBoxStatusShowMore)
    {
        // 显示更多面板
        if (fromStatus == TLChatBoxStatusShowVoice || fromStatus == TLChatBoxStatusNothing) {
            [self.chatBoxMoreView setY:self.chatBox.curHeight - self.chatBox.safeInset.bottom];
            [self.view addSubview:self.chatBoxMoreView];
            
            [UIView animateWithDuration:0.25 animations:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
                    [self.delegate chatBoxViewController:self didChangeChatBoxHeight:self.chatBox.curHeight + HEIGHT_CHATBOXVIEW duration:0.25];
                }
            }];
        }
        else {
            self.chatBoxMoreView.y = self.chatBox.curHeight + HEIGHT_CHATBOXVIEW;
            [self.view addSubview:self.chatBoxMoreView];
            [UIView animateWithDuration:0.5 animations:^{
                self.chatBoxMoreView.y = self.chatBox.curHeight - self.chatBox.safeInset.bottom;
            } completion:^(BOOL finished) {
                [self.chatBoxFaceView removeFromSuperview];
            }];
            
            if (fromStatus != TLChatBoxStatusShowFace) {
                [UIView animateWithDuration:0.25 animations:^{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)]) {
                        [self.delegate chatBoxViewController:self didChangeChatBoxHeight:self.chatBox.curHeight + HEIGHT_CHATBOXVIEW duration:0.25];
                    }
                }];
            }
        }
    }
}

// 开始录音
- (void)chatBoxDidBeginTalking:(ZXChatBoxView *)chatBox
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (AVAuthorizationStatusAuthorized == authStatus) {
        // 停止播放音乐之类的
        [[LGAudioPlayer sharePlayer] stopAudioPlayer];
        // 重置时间
        _seconds = 0;
        // 开始倒计时
        dispatch_resume(self.timer);
        // 开始录音
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSString *audioPath = [DocumentDirectory() stringByAppendingPathComponent:XOMsgFileDirectory(XOMsgFileTypeAudio)];
            [[LGSoundRecorder shareInstance] startSoundRecord:self.view.superview recordPath:audioPath];
        }];
    }
    else if (AVAuthorizationStatusDenied == authStatus || AVAuthorizationStatusRestricted == authStatus) {
        // 打开授权提示
        [self showAlertAuthor:XORequestAuthMicphone];
    }
    else {
        // 申请权限
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (!granted) {
                NSLog(@"未授权麦克风权限");
            } else {
                NSLog(@"授权麦克风权限");
            }
        }];
    }
}
// 结束录音
- (void)chatBoxDidEndTalking:(ZXChatBoxView *)chatBox
{
    if (_timer) {
        dispatch_source_cancel(_timer);
    }
    _timer = nil;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([LGSoundRecorder shareInstance].soundRecordTime < 1.0) {
            [[LGSoundRecorder shareInstance] showShotTimeSign:self.view];
        } else {
            audioRecordTime = [LGSoundRecorder shareInstance].soundRecordTime;
            [[LGSoundRecorder shareInstance] stopSoundRecord:self.view];
        }
    }];
}
// 取消录音
- (void)chatBoxDidCancelTalking:(ZXChatBoxView *)chatBox
{
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[LGSoundRecorder shareInstance] soundRecordFailed:self.view];
    }];
}
// 将要取消录音
- (void)chatBoxWillCancelTalking:(ZXChatBoxView *)chatBox
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[LGSoundRecorder shareInstance] readyCancelSound];
    }];
}
// 继续录音
- (void)chatBoxWillGoOnTalking:(ZXChatBoxView *)chatBox
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[LGSoundRecorder shareInstance] resetNormalRecord];
    }];
}

#pragma mark ====================== help =======================
/**
 *  回收键盘方法
 */
- (BOOL) resignFirstResponder
{
    if (self.chatBox.status != TLChatBoxStatusNothing && self.chatBox.status != TLChatBoxStatusShowVoice)
    {
        // 回收键盘
        [self.chatBox resignFirstResponder];
        /**
         *  在外层已经判断是不是声音状态 和 Nothing 状态了，且判断是都不是才进来的，下面在判断是否多余了？
         *  它是判断是不是要设置成Nothing状态
         */
        self.chatBox.status = (self.chatBox.status == TLChatBoxStatusShowVoice ? self.chatBox.status : TLChatBoxStatusNothing);
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:didChangeChatBoxHeight:duration:)])
        {
            [UIView animateWithDuration:0.3 animations:^{
                
                [self.delegate chatBoxViewController:self didChangeChatBoxHeight:self.chatBox.curHeight duration:0.25];
                
            } completion:^(BOOL finished) {
                
                [self.chatBoxFaceView removeFromSuperview];
                [self.chatBoxMoreView removeFromSuperview];
            }];
        }
    }
    
    return [super resignFirstResponder];
}

#pragma mark ====================== ChatBoxMoreViewDelegate =======================

- (void)chatBoxMoreView:(ZXChatBoxMoreView *)chatBoxMoreView didSelectItem:(NSUInteger)itemIndex
{
    if (0 == itemIndex) {            // 相册
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (PHAuthorizationStatusAuthorized == status) { // 已授权
            [self pickPhotos];
        }
        else if (PHAuthorizationStatusNotDetermined == status) { // 未选择过, 申请授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (PHAuthorizationStatusAuthorized == status) {
                    [self pickPhotos];
                } else {
                    [SVProgressHUD showInfoWithStatus:XOChatLocalizedString(@"tip.auth.fail")];
                    [SVProgressHUD dismissWithDelay:0.6f];
                }
            }];
        }
        else { // 提示授权
            [self showAlertAuthor:XORequestAuthPhotos];
        }
    }
    else if (1 == itemIndex) {       // 相机
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (AVAuthorizationStatusAuthorized == status) { // 已授权
            [self takePhoto];
        }
        else if (AVAuthorizationStatusNotDetermined == status) { // 未选择过, 申请授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self takePhoto];
                } else {
                    [SVProgressHUD showInfoWithStatus:XOChatLocalizedString(@"tip.auth.fail")];
                    [SVProgressHUD dismissWithDelay:0.6f];
                }
            }];
        }
        else { // 提示授权
            [self showAlertAuthor:XORequestAuthCamera];
        }
    }
    else if (2 == itemIndex) {       // 通话
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewControllerSendCall:)]) {
            [self.delegate chatBoxViewControllerSendCall:self];
        }
    }
    else if (3 == itemIndex) {       // 位置
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewControllerSendPosition:)]) {
            [self.delegate chatBoxViewControllerSendPosition:self];
        }
    }
    else if (4 == itemIndex) {       // 视频
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (PHAuthorizationStatusAuthorized == status) {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                [self takeVideo];
            } else {
                [SVProgressHUD showInfoWithStatus:@"当前设备不支持拍照"];
                [SVProgressHUD dismissWithDelay:1.3f];
            }
        }
        else if (PHAuthorizationStatusNotDetermined == status) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (PHAuthorizationStatusAuthorized == status) {
                    [self takeVideo];
                }
                else if (PHAuthorizationStatusDenied == status) {
                    [SVProgressHUD showInfoWithStatus:XOChatLocalizedString(@"tip.auth.fail")];
                    [SVProgressHUD dismissWithDelay:0.8];
                }
            }];
        }
        else {
            [self showAlertAuthor:XORequestAuthCamera];
        }
    }
    else if (5 == itemIndex) {       // 红包
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewControllerSendCall:)]) {
            [self.delegate chatBoxViewControllerSendRedPacket:self];
        }
    }
    else if (6 == itemIndex) {       // 转账(单聊时) | 名片(群聊时)
        if (TIM_C2C == self.chatType) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewControllerSendCall:)]) {
                [self.delegate chatBoxViewControllerSendTransfer:self];
            }
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewControllerSendCall:)]) {
                [self.delegate chatBoxViewControllerSendCarte:self];
            }
        }
    }
    else if (7 == itemIndex) {       // 名片(单聊时) | 文件(群聊时)
        if (TIM_C2C == self.chatType) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewControllerSendCall:)]) {
                [self.delegate chatBoxViewControllerSendCarte:self];
            }
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewControllerSendCall:)]) {
                [self.delegate chatBoxViewControllerSendFile:self];
            }
        }
    }
    else if (8 == itemIndex) {       // 文件
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewControllerSendCall:)]) {
            [self.delegate chatBoxViewControllerSendFile:self];
        }
    }
}

- (void) chatBoxFaceViewDidSelectedFace:(ChatFace *)face type:(TLFaceType)type
{
    if (type == TLFaceTypeEmoji) {
        // 发送emoji表情
        [self.chatBox addEmojiFace:face];
    }
    else {
        // 发送gif表情
        NSLog(@"gif: %@",face.faceName);
    }
}

- (void) chatBoxFaceViewDeleteButtonDown
{
    [self.chatBox deleteButtonDown];
}

- (void) chatBoxFaceViewSendButtonDown
{
    [self.chatBox sendCurrentMessage];
}

#pragma mark =========================== event ===========================
// 选照片
- (void)pickPhotos
{
    self.TZImagePicker.allowPickingVideo = YES;
    self.TZImagePicker.allowPickingImage = YES;
    self.TZImagePicker.allowPickingMultipleVideo = YES;
    self.TZImagePicker.allowTakePicture = NO;
    self.TZImagePicker.allowTakeVideo = NO;
    [self.parentViewController presentViewController:self.TZImagePicker animated:YES completion:NULL];
}
// 拍照片
- (void)takePhoto
{
    self.imagePicker.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        } else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
    }
    self.imagePicker.showsCameraControls = YES;
    [self.parentViewController.navigationController presentViewController:self.imagePicker animated:YES completion:NULL];
}
// 拍视频
- (void)takeVideo
{
    self.imagePicker.mediaTypes = @[(__bridge NSString *)kUTTypeMovie];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        } else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        self.imagePicker.videoMaximumDuration = 10;
        if (@available(iOS 11.0, *)) {
            self.imagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
        } else {
            self.imagePicker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        }
    }
    [self.parentViewController.navigationController presentViewController:self.imagePicker animated:YES completion:NULL];
}
// 取消选中的图片或视频
- (void)cancelSelectedImageOrVideo
{
    @weakify(self);
    [self.TZImagePicker.selectedModels enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TZAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        [self.TZImagePicker removeSelectedModel:obj];
    }];
}

#pragma mark =========================== LGSoundRecorderDelegate ===========================

- (void)showSoundRecordFailed
{
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

// 录音停止
- (void)didStopSoundRecord
{
    // 录音文件地址
    __block NSString *cafPath = [LGSoundRecorder shareInstance].soundFilePath;
    // 转码后的文件地址
    NSString *mp3Name = [NSString stringWithFormat:@"%@.mp3", [NSString creatUUID]];
    __block NSString *mp3Path = [XOMsgFileDirectory(XOMsgFileTypeAudio) stringByAppendingPathComponent:mp3Name];
    
    if (![XOFM fileExistsAtPath:mp3Path]) {
        NSLog(@"录音文件不存在");
    }
    else { // 发送语音消息
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            // 转码mp3格式
            if ([ConvertWavToMp3 convertToMp3WithSavePath:mp3Path sourcePath:cafPath])
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:sendMp3Audio:audioDuration:)]) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.delegate chatBoxViewController:self sendMp3Audio:mp3Path audioDuration:(int)audioRecordTime];
                        audioRecordTime = 0.0f;
                    }];
                } else {
                    audioRecordTime = 0.0f;
                }
            }
            else {
                if (audioRecordTime > 1.0f) {
                    [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"error.unknown", nil)];
                    [SVProgressHUD dismissWithDelay:0.6f];
                }
            }
        }];
    }
}

#pragma mark ========================= UIImagePickerControllerDelegate =========================
// 拍完图片或者视频
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
    NSLog(@"didFinishPickingMediaWithInfo: %@", info);
    
    if (picker.cameraCaptureMode == UIImagePickerControllerCameraCaptureModePhoto) {
        NSURL *imageURL = info[UIImagePickerControllerMediaURL];
    }
    else if (picker.cameraCaptureMode == UIImagePickerControllerCameraCaptureModeVideo) {
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        if (videoURL) {
            AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
            [self handleTakeVideo:videoAsset];
        }
    }
}
// 取消了拍摄
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

// 处理拍摄的视频
- (void)handleTakeVideo:(AVURLAsset *)videoAsset
{
    // 1、获取视频缩略图
    UIImage *snapshotImage = [self getVideoSnapshotImage:videoAsset];
    NSString *snapshotName = [NSString stringWithFormat:@"%@_%ld_snapshot.jpg", [NSUUID UUID].UUIDString, (long)[[NSDate date] timeIntervalSince1970]];
    __block NSString *snapshotPath = [XOMsgFileDirectory(XOMsgFileTypeVideo) stringByAppendingPathComponent:snapshotName];
    __block NSURL *snapshotURL = [NSURL fileURLWithPath:snapshotPath];
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        NSData *imageData = UIImageJPEGRepresentation(snapshotImage, 1.0);
        if ([imageData writeToURL:snapshotURL atomically:YES]) {
            NSLog(@"写入视频截图成功: %@", snapshotPath);
        }
    }];
    // 2、转化视频格式为mp4
    NSString *videoName = [NSString stringWithFormat:@"%@_%ld.mp4", [NSUUID UUID].UUIDString, (long)[[NSDate date] timeIntervalSince1970]];
    __block NSString *videoPath = [XOMsgFileDirectory(XOMsgFileTypeVideo) stringByAppendingPathComponent:videoName];
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    __block CGFloat duration = CMTimeGetSeconds(videoAsset.duration) * 1000;
    __block CGSize snapshotSize = snapshotImage.size;
    [SVProgressHUD showWithStatus:@"处理视频中..."];
    [self convertToMP4:videoAsset videoURL:videoURL succ:^(NSURL *outputURL) {
        [SVProgressHUD dismiss];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:sendVideo:snapshotImage:snapshotSize:videoDuration:)]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.delegate chatBoxViewController:self sendVideo:videoPath snapshotImage:snapshotPath snapshotSize:snapshotSize videoDuration:duration];
            }];
        }
    } fail:^(NSError *error) {
        [SVProgressHUD showWithStatus:@"视频处理失败..."];
        [SVProgressHUD dismiss];
    }];
}

// 将MOV转为MP4格式的视频
- (void)convertToMP4:(AVURLAsset *)avAsset
            videoURL:(NSURL *)videoURL
                succ:(void(^)(NSURL *outputURL))succ
                fail:(void(^)(NSError *error))fail
{
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    __block AVAssetExportSession *exportSession = nil;
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetHighestQuality];
    } else if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    } else if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality]) {
        exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetLowQuality];
    }
    
    if (exportSession) {
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            exportSession.outputURL = videoURL;
            exportSession.outputFileType = AVFileTypeMPEG4;
            CMTime start = CMTimeMakeWithSeconds(0, avAsset.duration.timescale);
            CMTime duration = avAsset.duration;
            CMTimeRange range = CMTimeRangeMake(start, duration);
            exportSession.timeRange = range;
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                switch ([exportSession status]) {
                    case AVAssetExportSessionStatusCompleted:
                        if (succ) succ(videoURL);
                        break;
                    case AVAssetExportSessionStatusFailed:
                        if (fail) fail([exportSession error]);
                        break;
                    case AVAssetExportSessionStatusUnknown:
                    {
                        NSLog(@"格式转化 -- 状态未知");
//                         if (fail) fail([exportSession error]);
                    }
                        break;
                    case AVAssetExportSessionStatusCancelled:
                    {
                        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:400 userInfo:@{@"userinfo": @"export is cancel"}];
                        if (fail) fail(error);
                    }
                        break;
                    case AVAssetExportSessionStatusWaiting:
                        NSLog(@"格式转化 -- 等待中");
                        break;
                    case AVAssetExportSessionStatusExporting:
                        NSLog(@"格式转化 -- 转码中 %f", exportSession.progress);
                        break;
                }
            }];
        }];
    }
    else {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:400 userInfo:@{@"userinfo": @"there is no movie"}];
        if (fail) fail(error);
    }
}

// 获取视频截图
- (UIImage *)getVideoSnapshotImage:(AVURLAsset *)asset
{
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *originImage = [[UIImage alloc] initWithCGImage:image];
    CGSize scaleSize = [[XOFileManager shareInstance] getScaleImageSize:originImage];
    UIImage *shotImage = [[XOFileManager shareInstance] scaleOriginImage:originImage toSize:scaleSize];
    CGImageRelease(image);
    
    return shotImage;
}

#pragma mark ====================== TZImagePickerControllerDelegate =======================

// 选择图片、视频的回调
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos
{
    [assets enumerateObjectsUsingBlock:^(PHAsset *asset , NSUInteger idx, BOOL *stop){
        
        if (asset.mediaType == PHAssetMediaTypeImage) {
            // 选择了原图, 获取原图
            if (isSelectOriginalPhoto) {
                __block NSMutableArray *mutArr = [NSMutableArray arrayWithCapacity:1];
                [[TZImageManager manager] getOriginalPhotoWithAsset:asset completion:^(UIImage *photo, NSDictionary *info) {
                    if (![mutArr containsObject:asset]) { // 避免同一张图重复发送
                        [mutArr addObject:asset];
                        [self getImageForAsset:asset];
                    }
                }];
            }
            // 未选择原图, 获取封面图
            else {
                __block NSMutableArray *mutArr = [NSMutableArray arrayWithCapacity:1];
                [[TZImageManager manager] getPhotoWithAsset:asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if (![mutArr containsObject:asset]) { // 避免同一张图重复发送
                        [mutArr addObject:asset];
                        [self getImageForAsset:asset];
                    }
                }];
            }
        }
        else if (asset.mediaType == PHAssetMediaTypeVideo) {
            PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
            options.version = PHVideoRequestOptionsVersionOriginal;
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            options.networkAccessAllowed = YES;
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
                AVURLAsset *videoAsset = (AVURLAsset *)avasset;
                [self handleTakeVideo:videoAsset];
            }];
        }
    }];
    // 反选本次所有选中的图片或者视频
    [self cancelSelectedImageOrVideo];
}

// 获取图片
- (void)getImageForAsset:(PHAsset *)asset
{
    if (asset) {
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData *data, NSString *uti, UIImageOrientation orientation, NSDictionary *dic){
            
            if (data != nil) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatBoxViewController:sendImage:imageSize:imageFormat:)]) {
                    
                    // 图片存储的路径
                    NSString *imageName = [dic[@"PHImageFileURLKey"] lastPathComponent];
                    NSString *imagePath = [XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:imageName];

                    // 图片大于6M压缩
                    if (data.length > 6 * 1024 * 1024)
                    {
                        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                            UIImage *originImage = [UIImage imageWithData:data];
                            CGFloat ratio = (6.0 * 1024 * 1024)/data.length;
                            CGSize size = CGSizeMake(originImage.size.width * ratio, originImage.size.height * ratio);
                            UIImage *image = [[XOFileManager shareInstance] scaleOriginImage:originImage toSize:size];
                            [self handleImageWith:image imageName:imageName imagePath:imagePath uti:uti];
                        }];
                    }
                    else {
                        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                            UIImage *originImage = [UIImage imageWithData:data];
                            [self handleImageWith:originImage imageName:imageName imagePath:imagePath uti:uti];
                        }];
                    }
                }
            }
            else {
                [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"image.choose", @"Image size is too large, please re-select")];
                [SVProgressHUD dismissWithDelay:1.3f];
            }
        }];
    }
}

- (void)handleImageWith:(UIImage *)image imageName:(NSString *)imageName imagePath:(NSString *)imagePath uti:(NSString *)uti
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    
    // 原图写入沙盒
    if ([imageData writeToFile:imagePath atomically:YES]) {
        // 获取缩略图
        CGSize thumbSize = [[XOFileManager shareInstance] getScaleImageSize:image];
        UIImage *thumbImage = [[XOFileManager shareInstance] scaleOriginImage:image toSize:thumbSize];
        NSData *thumbImageData = UIImageJPEGRepresentation(thumbImage, 1.0);
        NSString *thumbImageName = [imageName stringByReplacingOccurrencesOfString:@"." withString:@"_thumb."];
        NSString *thumbImagePath = [XOMsgFileDirectory(XOMsgFileTypeImage) stringByAppendingPathComponent:thumbImageName];
        // 缩略图写入沙盒
        [thumbImageData writeToFile:thumbImagePath atomically:YES];
        // 回调代理发送图片消息
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.delegate chatBoxViewController:self sendImage:imagePath imageSize:image.size imageFormat:uti];
        }];
    }
}

#pragma mark ====================== public method =======================

- (void)safeAreaDidChange:(UIEdgeInsets)safeAreaInset
{
    _safeInset = safeAreaInset;
    self.chatBox.safeInset = _safeInset;
}

// 增加了@**
- (void)addAtSomeOne:(NSString *)atString
{
    
}

@end
