//
//  WXAudioMessageCell.h
//  WXMainProject
//
//  Created by 乐派 on 2019/4/23.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXMessageCell.h"
#import "LGAudioKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface WXSoundMessageCell : WXMessageCell

@property (nonatomic, assign) LGAudioPlayerState         playState;

@end

NS_ASSUME_NONNULL_END
