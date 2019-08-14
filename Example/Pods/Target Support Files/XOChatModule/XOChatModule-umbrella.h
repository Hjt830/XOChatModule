#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSBundle+ChatModule.h"
#import "UIImage+XOChatBundle.h"
#import "ChatFace.h"
#import "ChatFaceHelper.h"
#import "WXAudioRecorder.h"
#import "ZXChatHelper.h"
#import "ZXChatBoxFaceView.h"
#import "ZXChatBoxItemView.h"
#import "ZXChatBoxMoreView.h"
#import "ZXChatBoxView.h"
#import "ZXChatFaceItemView.h"
#import "ZXChatFaceMenuView.h"
#import "XOChatBoxViewController.h"
#import "XOChatMessageController.h"
#import "XOChatViewController.h"
#import "XOChatClient.h"
#import "XOContactManager.h"
#import "XOConversationManager.h"
#import "XOMessageManager.h"
#import "XOConversationListCell.h"
#import "XOConversationListController.h"
#import "lame.h"
#import "LGAudioKit.h"
#import "LGAudioPlayer.h"
#import "LGSoundRecorder.h"
#import "CommonTool.h"
#import "ConvertWavToMp3.h"
#import "XOChatMarco.h"
#import "XOChatModule.h"

FOUNDATION_EXPORT double XOChatModuleVersionNumber;
FOUNDATION_EXPORT const unsigned char XOChatModuleVersionString[];

