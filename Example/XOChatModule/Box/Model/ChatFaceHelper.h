//
//  ChatFaceHelper.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChatFace;
@interface ChatFaceHelper : NSObject

// 常规表情组
@property (nonatomic, strong) NSMutableArray * _Nullable faceGroupArray;

+ (ChatFaceHelper *_Nonnull) sharedFaceHelper;

// 初始化常规表情
- (void)initilizationEmoji;

// 根据groupID获取表情集合
- (void)getFaceArrayByGroupID:(NSString *_Nonnull)groupID
                  complection:(void(^ _Nullable)(NSArray <ChatFace *> * _Nullable chatFaceArray))handler;


@end
