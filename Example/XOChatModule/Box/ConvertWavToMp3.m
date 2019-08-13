//
//  ConvertWavToMp3.m
//  HTMessage
//
//  Created by 乐派 on 2019/1/28.
//  Copyright © 2019年 LePai ShenZhen Technology Co., Ltd. All rights reserved.
//

#import "ConvertWavToMp3.h"
#import "lame.h"

@implementation ConvertWavToMp3

+ (BOOL)convertToMp3WithSavePath:(NSString*)mp3Path sourcePath:(NSString *)cafPath
{
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafPath cStringUsingEncoding:1], "rb");  // source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                  // skip file header
        FILE *mp3 = fopen([mp3Path cStringUsingEncoding:1], "wb");     // output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        //设置声道1单声道，2双声道
        lame_set_num_channels(lame,1);
        lame_set_in_samplerate(lame, 8000.0);
        lame_set_VBR(lame, vbr_off);
        lame_init_params(lame);
        
        do {
            read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame,pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
        
        // 删除录音原文件
        NSError *rmError = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:cafPath error:&rmError]) {
            XOLog(@"删除录音原文件失败, %@", rmError);
        }
        
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        
    }
    
    return NO;
}

@end
