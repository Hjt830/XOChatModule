//
//  WXImageMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/4/23.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXImageMessageCell.h"

static BOOL progressFinish = NO;

@interface WXImageMessageCell ()
{
    CAShapeLayer    *_layer;
    float           _radius; // 矩形对角线长度
}
@end

@implementation WXImageMessageCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        _layer = [[CAShapeLayer alloc] init];
        [self.contentView insertSubview:self.messageImageView belowSubview:self.messageBackgroundImageView];
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    // 显示缩略图
    CGSize imageSize = [self messageSize];
    float y = self.avatarImageView.y;
    float sendY = y + imageSize.height/2.0;
    if (self.message.isSelf) {
        float x = self.avatarImageView.x - imageSize.width - 10;
        [self.messageBackgroundImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.messageImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.messageSendStatusImageView setCenter:CGPointMake(x - 20, sendY)];
        self.progressHud.bounds     = CGRectMake(0, 0, imageSize.width, imageSize.height);
        self.progressHud.position   = CGPointMake(imageSize.width/2.0, imageSize.height/2.0);
    }
    else {
        float x = CGRectGetMaxX(self.avatarImageView.frame) + 10;
        [self.messageBackgroundImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.messageImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.messageSendStatusImageView setCenter:CGPointMake(x + imageSize.width + 20, sendY)];
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_messageImageView.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(5.0, 5.0)];
    _layer.path = path.CGPath;
    _layer.frame = _messageImageView.bounds;
}

/** @brief 更新进度  由子类实现
 *  @param effect  NO:表示上传或者下载失败  YES:表示上传中或者下载中,此时进度才有意义
 */
- (void)updateProgress:(float)progress effect:(BOOL)effect
{
    [super updateProgress:progress effect:effect];
    
    @synchronized (self) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (!effect) {
                [self.progressHud removeFromSuperlayer];
                progressFinish = YES;
            }
            else {
                UIBezierPath *progressPath = [self getPathWithProgress:progress];
                self.progressHud.path = progressPath.CGPath;
                
                if (progress == 1.0) {
                    [self.progressHud removeFromSuperlayer];
                    progressFinish = YES;
                    self->_radius = 0.0f;
                }
                else {
                    progressFinish = NO;
                    
                    if (![self.messageImageView.layer.sublayers containsObject:self.progressHud]) {
                        [self.messageImageView.layer addSublayer:self.progressHud];
                    }
                }
            }
        }];
    }
}

- (UIBezierPath *)getPathWithProgress:(float)progress
{
    CGSize imageSize = [self messageSize];
    if (_radius <= 0) {
        // 求矩形对角线长度
        _radius = sqrt(imageSize.width * imageSize.width + imageSize.height * imageSize.height);
    }
    UIBezierPath * interP  = [UIBezierPath bezierPathWithArcCenter:CGPointMake(imageSize.width/2.0, imageSize.height/2.0)
                                                            radius:(_radius/2.0)
                                                        startAngle:0.0 * 2 * M_PI
                                                          endAngle:progress * 2 * M_PI  // 2π
                                                         clockwise:NO];
    [interP addLineToPoint:CGPointMake(imageSize.width/2.0, imageSize.height/2.0)];
    [interP closePath];
    
    return interP;
}

#pragma mark - Getter and Setter
- (void)setMessage:(TIMMessage *)message
{
    [super setMessage:message];
    
    [self.messageBackgroundImageView setImage:nil];
    // 设置上传或者下载进度
    if (message.isSelf && !progressFinish) {
        UIBezierPath *path = [self getPathWithProgress:0.00f];
        self.progressHud.path = path.CGPath;
        [self.messageImageView.layer addSublayer:self.progressHud];
    } else {
        [self.progressHud removeFromSuperlayer];
    }
    
    // 设置图片
    self.messageImageView.image = [UIImage imageNamed:@"placeholderImage"];
    
    /*
    if (!XOIsEmptyString(message.body.thumbnailLocalPath)) {
        NSString *path = [DocumentPath() stringByAppendingPathComponent:message.body.thumbnailLocalPath];
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.messageImageView.image = image;
            }];
        }];
    }
    else if (!WXIsEmptyString(message.body.thumbnailRemotePath)) {
        [[WXMsgFileManager shareManager] downloadMessageThumbImage:message result:^(BOOL finish, HTMessage * _Nonnull aMessage, NSError * _Nullable error) {
            NSString *path = [DocumentPath() stringByAppendingPathComponent:message.body.thumbnailLocalPath];
            [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                UIImage *image = [UIImage imageWithContentsOfFile:path];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    self.messageImageView.image = image;
                }];
            }];
        }];
    }
    else {
        // 如果高清图已经下载完毕，则使用高清图获取缩略图
        NSString *localPath = [DocumentPath() stringByAppendingPathComponent:message.body.localPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                UIImage *image = [UIImage imageWithContentsOfFile:localPath];
                // 获得缩略图
                CGSize maxSize = [[WXMsgFileManager shareManager] getScaleImageSize:image.size maxFloat:240];
                NSData *thumbImageData = [[WXMsgFileManager shareManager] scaleImage:image maxSize:maxSize compressionQuality:0.5];
                UIImage *thumbImage = [UIImage imageWithData:thumbImageData];
                // 存储路径
                NSArray *arr = [message.body.fileName componentsSeparatedByString:@"."];
                NSString *thumbImageName = nil;
                if (!WXIsEmptyArray(arr) && arr.count >= 1) thumbImageName = [NSString stringWithFormat:@"%@_thumb.png", arr[0]];
                else thumbImageName = [NSString stringWithFormat:@"%@_thumb.png", message.body.fileName];
                NSString *thumbPath = [WXMsgFileDirectory(message.msgType) stringByAppendingPathComponent:thumbImageName];
                NSString *thumbDerctory = [DocumentPath() stringByAppendingPathComponent:thumbPath];
                // 写入缩略图存储路径
                if ([thumbImageData writeToFile:thumbDerctory atomically:YES]) {
                    message.body.thumbnailLocalPath = thumbPath;
                    [[WXMsgCoreDataManager shareManager].mainMOC MR_saveOnlySelfAndWait];
                }
                
                if (image && [image isKindOfClass:[UIImage class]]) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        self.messageImageView.image = thumbImage;
                    }];
                }
            }];
        }
    }
     */
}

- (UIImageView *) messageImageView
{
    if (_messageImageView == nil) {
        _messageImageView = [[UIImageView alloc] init];
        [_messageImageView setContentMode:UIViewContentModeScaleAspectFill];
        [_messageImageView setClipsToBounds:YES];
        [_messageImageView.layer setMask:_layer];
    }
    return _messageImageView;
}

- (CGSize)messageSize
{
    float ImageWidth = 1080.0f;    // 图片的宽度
    float ImageHeight = 1920.0;    // 图片的高度
    
    TIMImageElem *imageElem = (TIMImageElem *)[self.message getElem:0];
    CGSize size = CGSizeMake(ImageWidth, ImageHeight);
    float sizew = ImageWidth;
    float sizeh = ImageHeight;
    if (imageElem.imageList.count > 0) {
        TIMImage *image = [imageElem.imageList objectAtIndex:0];
        sizew = image.width;
        sizeh = image.height;
    }
    
    float maxWid = KWIDTH * 0.5;
    if (sizew <= maxWid) {
        size = CGSizeMake(sizew, sizeh);
    } else {
        if (sizew > sizeh) {
            float resizeh = (maxWid/sizew) * sizeh;
            size = CGSizeMake(maxWid, resizeh);
        } else {
            float resizeW = (maxWid/sizeh) * sizew;
            size = CGSizeMake(resizeW, maxWid);
        }
    }
    
    return size;
}

@end
