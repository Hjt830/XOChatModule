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
#import "TIMElem+XOExtension.h"
#import "TIMMessage+XOChatExtenstion.h"
#import "UIImage+XOChatBundle.h"
#import "UIImage+XOChatExtension.h"
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
#import "XODocumentPickerViewController.h"
#import "XOLocationViewController.h"
#import "ForwardView.h"
#import "WXFaceMessageCell.h"
#import "WXFileMessageCell.h"
#import "WXImageMessageCell.h"
#import "WXLocationMessageCell.h"
#import "WXMessageCell.h"
#import "WXPromptMessageCell.h"
#import "WXSoundMessageCell.h"
#import "WXTextMessageCell.h"
#import "WXVideoMessageCell.h"
#import "XOChatBoxViewController.h"
#import "XOChatMessageController.h"
#import "XOChatViewController.h"
#import "XOChatClient.h"
#import "XOContactManager.h"
#import "XOConversationManager.h"
#import "XOMessageManager.h"
#import "LCContactListViewController.h"
#import "XOGroupListViewController.h"
#import "XOSearchResultListController.h"
#import "XOConversationListCell.h"
#import "XOConversationListController.h"
#import "GroupInfoEditViewController.h"
#import "GroupSettingInfoController.h"
#import "XOGroupSelectedController.h"
#import "BMChineseSort.h"
#import "lame.h"
#import "LGAudioKit.h"
#import "LGAudioPlayer.h"
#import "LGSoundRecorder.h"
#import "ConvertWavToMp3.h"
#import "XOChatMarco.h"
#import "XOChatModule.h"

FOUNDATION_EXPORT double XOChatModuleVersionNumber;
FOUNDATION_EXPORT const unsigned char XOChatModuleVersionString[];

