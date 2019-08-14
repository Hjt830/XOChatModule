//
//  ZXChatBoxMoreView.h
//  ZXDNLLTest
//
//  Created by mxsm on 16/5/19.
//  Copyright © 2016年 mxsm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZXChatBoxItemView.h"

@class ZXChatBoxMoreView;
@protocol ZXChatBoxMoreViewDelegate <NSObject>

- (void)chatBoxMoreView:(ZXChatBoxMoreView *)chatBoxMoreView didSelectItem:(NSUInteger)itemIndex;

@end

@interface ZXChatBoxMoreView : UIView


@property (nonatomic, strong) id<ZXChatBoxMoreViewDelegate>delegate;
@property (nonatomic, strong) NSMutableArray *items;

@end
