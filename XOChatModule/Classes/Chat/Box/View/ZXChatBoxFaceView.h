//
//  ZXChatBoxFaceView.h
//  ZXDNLLTest
//
//  Created by mxsm on 16/5/19.
//  Copyright © 2016年 mxsm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatFace.h"
@protocol ZXChatBoxFaceViewDelegate <NSObject>

- (void) chatBoxFaceViewDidSelectedFace:(int)faceIndex faceGroup:(ChatFaceGroup *)faceGroup type:(TLFaceType)type;
- (void) chatBoxFaceViewDeleteButtonDown;
- (void) chatBoxFaceViewSendButtonDown;

@end

@interface ZXChatBoxFaceView : UIView

@property (nonatomic, weak) id <ZXChatBoxFaceViewDelegate> delegate;


@end
