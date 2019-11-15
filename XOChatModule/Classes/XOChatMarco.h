//
//  XOChatMarco.h
//  XOChatModule
//
//  Created by kenter on 2019/8/14.
//

#ifndef XOChatMarco_h
#define XOChatMarco_h


//#ifndef XOChatMarco_h
//#define XOChatMarco_h
//#endif

#define XOChatGetImage(name) ([UIImage xo_imageNamedFromChatBundle:name])

static float const MsgCellIconMargin = 6.0f;    // 消息头像的上下边距(自己的头像下边距、他人的头像的上边距)
static float const ImageWidth = 375.0f;         // 图片的宽度
static float const ImageHeight = 750.0;         // 图片的高度
static float const FileWidth = 220.0f;          // 文件的宽度
static float const FileHeight = 80.0f;          // 文件的高度

// 在线客服ID
static NSString * const OnlineServerIdentifier = @"user0";


#endif /* XOChatMarco_h */
