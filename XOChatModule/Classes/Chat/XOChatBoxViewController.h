//
//  XOChatBoxViewController.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <XOBaseLib/XOBaseLib.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XOChatBoxViewControllerDelegate;

@interface XOChatBoxViewController : XOBaseViewController

@property (nonatomic, assign) TIMConversationType           chatType; // 聊天类型 单聊|群聊

@property(nonatomic, weak) id <XOChatBoxViewControllerDelegate> delegate;

- (void)safeAreaDidChange:(UIEdgeInsets)safeAreaInset;

- (void)addAtSomeOne:(NSString *)atString;

@end




@protocol XOChatBoxViewControllerDelegate <NSObject>

// chatBoxView 高度改变
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController didChangeChatBoxHeight:(CGFloat)height duration:(float)duration;
- (void)chatBoxViewControllerInputAtSymbol:(XOChatBoxViewController *)chatboxViewController;
// 发送消息
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendMessage:(NSString *)content;
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendImage:(NSString *)imagePath imageSize:(CGSize)size imageFormat:(NSString *)format;
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendVideo:(NSString *)videoPath snapshotImage:(NSString *)snapshotPath snapshotSize:(CGSize)size videoDuration:(float)duration;
- (void)chatBoxViewController:(XOChatBoxViewController *)chatboxViewController sendMp3Audio:(NSString *)mp3Path soundSize:(long)soundSize audioDuration:(NSTimeInterval)duration;
- (void)chatBoxViewControllerSendFile:(XOChatBoxViewController *)chatboxViewController sendFile:(NSString *)filePath filename:(NSString *)filename fileSize:(int)fileSize;
- (void)chatBoxViewControllerSendPosition:(XOChatBoxViewController *)chatboxViewController;
- (void)chatBoxViewControllerSendCall:(XOChatBoxViewController *)chatboxViewController;
- (void)chatBoxViewControllerSendRedPacket:(XOChatBoxViewController *)chatboxViewController;
- (void)chatBoxViewControllerSendTransfer:(XOChatBoxViewController *)chatboxViewController;
- (void)chatBoxViewControllerSendCarte:(XOChatBoxViewController *)chatboxViewController;

@end

NS_ASSUME_NONNULL_END
