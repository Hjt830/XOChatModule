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

#pragma mark ========================= setter =========================

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
    
    // 加载图片
    TIMElem *elem = [message getElem:0];
    if ([elem isKindOfClass:[TIMImageElem class]])
    {
        __block NSString *thumbImagePath = [message getThumbImagePath];
        if (![XOFM fileExistsAtPath:thumbImagePath]) {
            if (![[XOChatClient shareClient] isOnDownloading:message]) {
                [self loadImageWith:message formCache:NO];
            }
        }
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            NSData *thumbImageData = [[NSData alloc] initWithContentsOfFile:thumbImagePath];
            __block UIImage *thumbImage = [UIImage imageWithData:thumbImageData];
            // 缓存中有图片
            if (thumbImage != nil) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    self.messageImageView.image = thumbImage;
                }];
            }
            // 缓存中没有图片
            else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.messageImageView setImage:[UIImage XO_imageWithColor:[UIColor lightGrayColor] size:CGSizeMake(100, 150)]];
                }];
            }
        }];
    }
    else if ([elem isKindOfClass:[TIMVideoElem class]])
    {
        __block NSString *snapshotPath = [message getThumbImagePath];
        
        if (![XOFM fileExistsAtPath:snapshotPath]) {
            if (![[XOChatClient shareClient] isOnDownloading:message]) {
                [self loadImageWith:message formCache:NO];
            }
        }
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            NSData *snapshotImageData = [[NSData alloc] initWithContentsOfFile:snapshotPath];
            __block UIImage *snapshotImage = [UIImage imageWithData:snapshotImageData];
            // 缓存中有图片
            if (snapshotImage != nil) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    self.messageImageView.image = snapshotImage;
                }];
            }
            // 缓存中没有图片
            else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.messageImageView setImage:[UIImage xo_imageNamedFromChatBundle:@"placeholderImage"]];
                }];
            }
        }];
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    // 显示缩略图
    CGSize imageSize = [self messageSize];
    if (self.message.isSelf) {
        float x = self.avatarImageView.x - imageSize.width - 10;
        float y = CGRectGetMaxY(self.avatarImageView.frame) - imageSize.height;
        float sendY = y + imageSize.height/2.0;
        [self.messageImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.messageBackgroundImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.messageSendStatusImageView setCenter:CGPointMake(x - 30, sendY)];
        self.progressHud.bounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
        self.progressHud.position = CGPointMake(imageSize.width/2.0, imageSize.height/2.0);
    }
    else {
        float x = CGRectGetMaxX(self.avatarImageView.frame) + 10;
        float y = self.avatarImageView.y;
        float sendY = y + imageSize.height/2.0;
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
    
    NSLog(@"msgId: %@ progress: %f", self.message.msgId, progress);
    
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

- (UIImageView *) messageImageView
{
    if (_messageImageView == nil) {
        _messageImageView = [[UIImageView alloc] init];
        [_messageImageView setUserInteractionEnabled:YES];
        [_messageImageView setContentMode:UIViewContentModeScaleAspectFill];
        [_messageImageView setImage:[UIImage XO_imageWithColor:[UIColor lightGrayColor] size:CGSizeMake(100, 150)]];
        [_messageImageView setClipsToBounds:YES];
        [_messageImageView.layer setMask:_layer];
    }
    return _messageImageView;
}

#pragma mark ========================= help =========================

// 加载图片 useCache 是否从缓存中获取图片
- (void)loadImageWith:(TIMMessage *)message formCache:(BOOL)useCache
{
    TIMElem *elem = [message getElem:0];
    if ([elem isKindOfClass:[TIMImageElem class]]) {
        
        __block NSString *thumbImagePath = [message getThumbImagePath];
        // 从缓存获取缩略图片
        if (useCache && [[NSFileManager defaultManager] fileExistsAtPath:thumbImagePath]) {
            [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                NSData *thumbImageData = [[NSData alloc] initWithContentsOfFile:thumbImagePath];
                __block UIImage *thumbImage = [UIImage imageWithData:thumbImageData];
                // 缓存中有图片
                if (thumbImage != nil) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        self.messageImageView.image = thumbImage;
                    }];
                }
                // 缓存中没有图片
                else {
                    [self loadImageWith:message formCache:NO];
                }
            }];
        }
        // 从网络获取图片
        else {
            TIMImageElem *imageElem = (TIMImageElem *)elem;
            if (imageElem.imageList.count > 0)
            {
                __block NSString *imagePath = [message getImagePath];
                __block BOOL isOrigin = [XOFM fileExistsAtPath:imagePath]; // 原图是否存在
                
                TIMImage *timImage = nil;
                if (isOrigin) {
                    timImage = imageElem.imageList[0];
                } else {
                    if (imageElem.imageList.count >= 3) timImage = imageElem.imageList[2];
                    else if (imageElem.imageList.count >= 2) timImage = imageElem.imageList[1];
                }
                
                [timImage getImage:imagePath progress:^(NSInteger curSize, NSInteger totalSize) {
                    float progress = curSize * 0.1/totalSize;
                    [self updateProgress:progress effect:YES];
                } succ:^{
                    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                        // 没有原图, 则下载的是原图 --- 根据原图获取缩略图
                        if (!isOrigin) {
                            NSData *imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
                            __block UIImage *image = [UIImage imageWithData:imageData];
                            // 根据原图获取缩略图
                            CGSize thumbSize = [[XOFileManager shareInstance] getScaleImageSize:image];
                            UIImage *thumbImage = [[XOFileManager shareInstance] scaleOriginImage:image toSize:thumbSize];
                            // 显示图片
                            if (thumbImage) {
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    self.messageImageView.image = thumbImage;
                                }];
                                
                                // 将缩略图写入沙盒
                                NSData *thumbImageData = UIImageJPEGRepresentation(thumbImage, 1.0);
                                if ([thumbImageData writeToFile:thumbImagePath atomically:YES]) {
                                    NSLog(@"缓存缩略图成功");
                                }
                            }
                        }
                    }];
                    
                } fail:^(int code, NSString *msg) {
                    NSLog(@"下载网络图片失败 ---- code: %d  msg: %@", code, msg);
                }];
            }
        }
    }
    else if ([elem isKindOfClass:[TIMVideoElem class]])
    {
        TIMVideoElem *videoElem = (TIMVideoElem *)elem;
        __block NSString *snapshotPath = [message getThumbImagePath];
        
        // 从缓存获取缩略图片
        if (useCache && [[NSFileManager defaultManager] fileExistsAtPath:snapshotPath]) {
            [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                NSData *thumbImageData = [[NSData alloc] initWithContentsOfFile:snapshotPath];
                __block UIImage *thumbImage = [UIImage imageWithData:thumbImageData];
                // 缓存中有图片
                if (thumbImage != nil) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        self.messageImageView.image = thumbImage;
                    }];
                }
                // 缓存中没有图片
                else {
                    [self loadImageWith:message formCache:NO];
                }
            }];
        }
        else {
            if (videoElem.snapshot) {
                TIMSnapshot *snapshot = videoElem.snapshot;
                [snapshot getImage:snapshotPath succ:^{
                    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                        
                        NSData *snapshotData = [[NSData alloc] initWithContentsOfFile:snapshotPath];
                        __block UIImage *snapshotImage = [UIImage imageWithData:snapshotData];
                        // 显示图片
                        if (snapshotImage) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                self.messageImageView.image = snapshotImage;
                            }];
                        }
                    }];
                    
                } fail:^(int code, NSString *msg) {
                    NSLog(@"下载网络图片失败 ---- code: %d  msg: %@", code, msg);
                }];
            }
        }
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

// 获取图片的格式
- (NSString *)getImageFormat:(TIM_IMAGE_FORMAT)imageFormat
{
    NSString *format = nil;
    
    switch (imageFormat) {
        case TIM_IMAGE_FORMAT_PNG:
            format = @"png";
            break;
        case TIM_IMAGE_FORMAT_GIF:
            format = @"gif";
            break;
        case TIM_IMAGE_FORMAT_BMP:
            format = @"bmp";
            break;
        default:
            format = @"jpg";
            break;
    }
    return format;
}

- (CGSize)messageSize
{
    CGFloat standradW = (SCREEN_WIDTH < SCREEN_HEIGHT) ? SCREEN_WIDTH : SCREEN_HEIGHT;
    float sizew = ImageWidth;   // 图片的宽度
    float sizeh = ImageHeight;  // 图片的高度
    CGSize size = CGSizeZero;
    
    TIMElem *elem = [self.message getElem:0];
    if ([elem isKindOfClass:[TIMImageElem class]]) {
        TIMImageElem *imageElem = (TIMImageElem *)elem;
        if (imageElem.imageList.count > 0) {
            TIMImage *image = [imageElem.imageList objectAtIndex:0];
            sizew = image.width;
            sizeh = image.height;
        }
    }
    else if ([elem isKindOfClass:[TIMVideoElem class]]) {
        TIMVideoElem *videoElem = (TIMVideoElem *)elem;
        if (videoElem.snapshot) {
            sizew = videoElem.snapshot.width;
            sizeh = videoElem.snapshot.height;
        }
    }
    
    float maxWid = standradW * 0.3;
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
