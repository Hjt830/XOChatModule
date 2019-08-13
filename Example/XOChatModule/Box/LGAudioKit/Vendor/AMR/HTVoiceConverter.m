//
//  HTVoiceConverter.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/29.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "HTVoiceConverter.h"
#import "amrFileCodec.h"

@implementation HTVoiceConverter

+ (BOOL)wavToAmr:(NSString *)filePath amrSavePath:(NSString *)amrPath {
    NSData *wavData = [NSData dataWithContentsOfFile:filePath];
    NSData *amrData = EncodeWAVEToAMR(wavData, 1, 16);
    BOOL res = [[NSFileManager defaultManager] createFileAtPath:amrPath
                                    contents:amrData
                                  attributes:nil];
    return res;
}

@end
