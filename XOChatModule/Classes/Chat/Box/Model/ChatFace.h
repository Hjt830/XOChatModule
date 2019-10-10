//
//  ChatFace.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 *  定义一个表情的类型枚举
 */
typedef NS_ENUM(NSInteger, TLFaceType) {
    /**
     *  表情
     */
    TLFaceTypeEmoji,
    /**
     *  GIF表情
     */
    TLFaceTypeGIF,
};


@interface ChatFace : NSObject

@property (nonatomic, copy) NSString *faceID;
@property (nonatomic, copy) NSString *faceName;

@end

/**
 *  类拓展
 */
@interface ChatFaceGroup : NSObject

@property (nonatomic, assign) TLFaceType faceType;
@property (nonatomic, copy) NSString *groupID;
@property (nonatomic, copy) NSString *groupImageName;
@property (nonatomic, strong) NSArray *facesArray;

@end
