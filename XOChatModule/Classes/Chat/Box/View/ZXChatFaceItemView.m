//
//  ZXChatFaceItemView.m
//  ZXDNLLTest
//
//  Created by mxsm on 16/5/20.
//  Copyright © 2016年 mxsm. All rights reserved.
//

#import "ZXChatFaceItemView.h"
#import <XOBaseLib/XOBaseLib.h>
#import "UIImage+XOChatBundle.h"

@interface ZXChatFaceItemView () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) int fromIndex;
@property (nonatomic, strong) ChatFaceGroup *faceGroup;
@property (nonatomic, strong) UIButton *delButton;
@property (nonatomic, strong) NSMutableArray <CALayer *>* faceViewArray;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end
@implementation ZXChatFaceItemView

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self addSubview:self.delButton];
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectEmoji:)];
//        self.tap.delegate = self;
        [self addGestureRecognizer:self.tap];
    }
    return self;
}

- (void)dealloc
{
    [self removeGestureRecognizer:self.tap];
}

#pragma mark - Public Methods
- (void) showFaceGroup:(ChatFaceGroup *)group formIndex:(int)fromIndex count:(int)count
{
    if (self.faceGroup.faceType != group.faceType) {
        [self.faceViewArray enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperlayer];
        }];
        [self.faceViewArray removeAllObjects];
    }
    self.faceGroup = group;
    self.fromIndex = fromIndex;
    
    int index = 0;
    float spaceX = 12;  // 左右间隔距离
    float spaceY = 10;  // 上线间隔距离
    int row = (group.faceType == TLFaceTypeEmoji ? 3 : 2); // 行数
    int col = (group.faceType == TLFaceTypeEmoji ? 7 : 4); // 列数
    float w = (self.width - spaceX * 2) / col;  // 每个表情的可点击宽度
    float h = (self.height - spaceY * (row - 1)) / row; // 每个表情的可点击高度
    float realW = (group.faceType == TLFaceTypeEmoji ? 28 : 50);  // 每个表情的实际宽度
    float realH = realW; // 每个表情的实际高度
    float x = spaceX;
    float y = spaceY;
    for (int i = fromIndex; i < fromIndex + count; i ++) {
        CALayer *layer;
        if (index < self.faceViewArray.count)
        {
            layer = [self.faceViewArray objectAtIndex:index];
        }
        else
        {
            layer = [CALayer layer];
            layer.contentsGravity = kCAGravityResizeAspectFill;
            [self.layer addSublayer:layer];
            [self.faceViewArray addObject:layer];
        }
        
        index ++;
        if (i >= group.facesArray.count || i < 0)
        {
            [layer setHidden:YES];
        }
        else {
            ChatFace  *face = [group.facesArray objectAtIndex:i];
            layer.contents = (__bridge id _Nullable)([UIImage xo_imageNamedFromChatBundle:face.faceName].CGImage);
            layer.frame = CGRectMake(x + (w - realW)/2.0, y + (h - realH)/2.0, realW, realH);
            layer.hidden = NO;
            x = (index % col == 0 ? spaceX: x + w);
            y = (index % col == 0 ? y + h : y);
        }
    }
    
    if (self.faceGroup.faceType == TLFaceTypeEmoji) {
        [_delButton setHidden:fromIndex >= group.facesArray.count];
        [_delButton setFrame:CGRectMake(x, y, w, h)];
    }
    else {
        [_delButton setHidden:YES];
    }
}

#pragma mark =========================== 点击事件 ===========================

- (void)selectEmoji:(UITapGestureRecognizer *)tap
{
    NSLog(@"state: %ld", (long)tap.state);
    if (UIGestureRecognizerStateEnded == tap.state) {
        
        CGPoint point = [tap locationInView:self];
        
        float spaceX = 12;  // 左右间隔距离
        float spaceY = 10;  // 上下间隔距离
        // 先判断超出边界
        if (point.x < spaceX || point.x > self.width - spaceX || point.y < spaceY || point.y > self.height - spaceY) {
            return;
        }
        // 判断点击的哪个表情
        int row = (self.faceGroup.faceType == TLFaceTypeEmoji ? 3 : 2); // 行数
        int col = (self.faceGroup.faceType == TLFaceTypeEmoji ? 7 : 4); // 列数
        float w = (SCREEN_WIDTH - spaceX * 2) / col;  // 表情的可点击宽度
        float h = (self.height - spaceY * (row - 1)) / row; // 表情的可点击高度
        int wa = ((point.x - spaceX) - (int)((point.x - spaceX)/w) * w) > 0 ? 1 : 0;
        int ha = ((point.y - spaceY) - (int)((point.y - spaceY)/h) * h) > 0 ? 1 : 0;
        int x = (point.x - spaceX)/w + wa; // 列数
        int y = (point.y - spaceY)/h + ha; // 行数
        int faceIndex = self.fromIndex + (y - 1) * (self.faceGroup.faceType == TLFaceTypeEmoji ? 7 : 4) + (x - 1);
        
        // 当前是emoji (点击范围是 可点击宽度和高度)
        if (self.faceGroup.faceType == TLFaceTypeEmoji) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(chatFaceItemView:didSelectFace:faceGroup:faceType:)]) {
                if (faceIndex < self.faceGroup.facesArray.count) {
                    [self.delegate chatFaceItemView:self didSelectFace:faceIndex faceGroup:self.faceGroup faceType:self.faceGroup.faceType];
                }
            }
        }
        // 当前是gif (点击范围是 实际宽度和高度, point在实际宽度高度 与 可点击宽度高度 之间不触发)
        else if (self.faceGroup.faceType == TLFaceTypeGIF) {
            float realWidLeft1 = spaceX + (x - 1) * w; // 间隙左边界1
            float realWidLeft2 = realWidLeft1 + (w - 50)/2.0; // 间隙左边界2
            float realWidRight1 = spaceX + x * w - (w - 50)/2.0; // 间隙右边界1
            float realWidRight2 = spaceX + x * w; // 间隙右边界2
            
            float realHeiTop1 = spaceY + (y - 1) * h; // 间隙上边界1
            float realHeiTop2 = realHeiTop1 + (h - 50)/2.0; // 间隙上边界2
            float realHeiBottom1 = spaceY + y * h - (h - 50)/2.0; // 间隙下边界1
            float realHeiBottom2 = spaceY + y * h; // 间隙下边界2
            
            if ((point.x >= realWidLeft1 && point.x < realWidLeft2) ||
                (point.x > realWidRight1 && point.x <= realWidRight2) ||
                (point.y >= realHeiTop1 && point.y < realHeiTop2) ||
                (point.y > realHeiBottom1 && point.y <= realHeiBottom2)) {
                return;
            }
            else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(chatFaceItemView:didSelectFace:faceGroup:faceType:)]) {
                    if (faceIndex < self.faceGroup.facesArray.count) {
                        [self.delegate chatFaceItemView:self didSelectFace:faceIndex faceGroup:self.faceGroup faceType:self.faceGroup.faceType];
                    }
                }
            }
        }
    }
}

- (void)didClickDelete:(UIButton *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatFaceItemViewDidClickDelete:)]) {
        [self.delegate chatFaceItemViewDidClickDelete:self];
    }
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    if (otherGestureRecognizer != self.tap) {
//        return NO;
//    }
//    return YES;
//}

#pragma mark - Getter
-(NSMutableArray *) faceViewArray
{
    if (_faceViewArray == nil) {
        _faceViewArray = [[NSMutableArray alloc] init];
    }
    return _faceViewArray;
}

-(UIButton *) delButton
{
    if (_delButton == nil) {
        _delButton = [[UIButton alloc] init];
        _delButton.tag = -1;
        [_delButton setImage:[UIImage xo_imageNamedFromChatBundle:@"DeleteEmoticonBtn"] forState:UIControlStateNormal];
        [_delButton addTarget:self action:@selector(didClickDelete:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _delButton;
}

@end
