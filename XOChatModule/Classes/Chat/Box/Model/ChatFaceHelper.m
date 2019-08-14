//
//  ChatFaceHelper.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "ChatFaceHelper.h"
#import "ChatFace.h"
#import <XOBaseLib/XOBaseLib.h>

static ChatFaceHelper * faceHeleper = nil;

@interface ChatFaceHelper ()

// 表情组集合
@property (nonatomic, strong) NSMutableDictionary         *faceGroupsSet;

@end

@implementation ChatFaceHelper

+ (ChatFaceHelper * )sharedFaceHelper
{
    if (!faceHeleper) {
        faceHeleper = [[ChatFaceHelper alloc]init];
    }
    return  faceHeleper;
}

- (void)initilizationEmoji
{
    self.faceGroupsSet = [[NSMutableDictionary alloc] init];
    // 加载常规表情组
    [self getFaceArrayByGroupID:@"face_emoji" complection:nil];
    // 加载兔斯基gif表情
    [self getFaceArrayByGroupID:@"face_tusiji" complection:nil];
}

/**
 *   通过这个方法，从plist文件中取出来表情
 */
- (void)getFaceArrayByGroupID:(NSString *_Nonnull)groupID
                  complection:(void(^ _Nullable)(NSArray <ChatFace *> * _Nullable chatFaceArray))handler
{
    NSArray *faceArray = [self.faceGroupsSet objectForKey:groupID];
    if (XOIsEmptyArray(faceArray)) {
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            NSArray *array = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:groupID ofType:@"plist"]];
            __block NSMutableArray *chatFaceArray = [[NSMutableArray alloc] initWithCapacity:array.count];
            for (NSDictionary *dic in array) {
                if ([dic isKindOfClass:[NSDictionary class]]) {
                    ChatFace *face = [[ChatFace alloc] init];
                    face.faceID = [dic objectForKey:@"face_id"];
                    face.faceName = [dic objectForKey:@"face_name"];
                    [chatFaceArray addObject:face];
                }
            }
            // 将表情组加到集合中
            [self.faceGroupsSet removeObjectForKey:groupID];
            [self.faceGroupsSet setObject:chatFaceArray forKey:groupID];
            
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler (chatFaceArray);
                }];
            }
        }];
    }
    else {
        if (handler) {
            handler (faceArray);
        }
    }
}

- (NSMutableArray *)faceGroupArray
{
    if (_faceGroupArray == nil) {
        _faceGroupArray = [[NSMutableArray alloc] init];
        
        // 增加常规表情组
        ChatFaceGroup *group = [[ChatFaceGroup alloc] init];
        group.faceType = TLFaceTypeEmoji;
        group.groupID = @"face_emoji";
        group.groupImageName = @"EmotionsEmojiHL";
        group.facesArray = self.faceGroupsSet[group.groupID];
        [_faceGroupArray addObject:group];
        
        // 增加兔斯基表情组
        ChatFaceGroup *group_tsj = [[ChatFaceGroup alloc] init];
        group_tsj.faceType = TLFaceTypeGIF;
        group_tsj.groupID = @"face_tusiji";
        group_tsj.groupImageName = @"EmotionsTuSiJiHL";
        group.facesArray = self.faceGroupsSet[group.groupID];
        group_tsj.facesArray = nil;
        [_faceGroupArray addObject:group_tsj];
    }
    return _faceGroupArray;
}


@end
