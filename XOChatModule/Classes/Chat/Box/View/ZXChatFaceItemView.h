//
//  ZXChatFaceItemView.h
//  ZXDNLLTest
//
//  Created by mxsm on 16/5/20.
//  Copyright © 2016年 mxsm. All rights reserved.
//



/**
 *  这个View的 showFaceGroup:(ChatFaceGroup *)group formIndex:(int)fromIndex count:(int)count
 *  是通过组区分来添加表情Button，添加到这个View上。然后这一页的View再添加到 ChatBoxFaceView 上去。。。。
 */


#import <UIKit/UIKit.h>
#import "ChatFace.h"

@class ZXChatFaceItemView;
@protocol ZXChatFaceItemViewDelegate <NSObject>

// 点击了某个表情
- (void)chatFaceItemView:(ZXChatFaceItemView *)itemView didSelectFace:(int)faceIndex faceGroup:(ChatFaceGroup *)faceGroup faceType:(TLFaceType)faceType;
// 点击了删除按钮
- (void)chatFaceItemViewDidClickDelete:(ZXChatFaceItemView *)itemView;

@end



@interface ZXChatFaceItemView : UIView

@property (nonatomic, weak) id <ZXChatFaceItemViewDelegate> delegate;

- (void) showFaceGroup:(ChatFaceGroup *)group formIndex:(int)fromIndex count:(int)count;

@end
