//
//  HTVoiceConverter.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTVoiceConverter : NSObject

+ (BOOL)wavToAmr:(NSString *)filePath amrSavePath:(NSString *)amrPath;

@end
