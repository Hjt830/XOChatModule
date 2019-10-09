//
//  WXFileMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/4/23.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXFileMessageCell.h"

static BOOL fileProgressFinish = NO;

@interface WXFileMessageCell ()
{
    CAShapeLayer    *_layer;
    CGFloat         _radius;
}
@property (nonatomic ,strong)UIImageView    *fileIconView;
@property (nonatomic ,strong)UILabel        *fileNameLabel;
@property (nonatomic ,strong)UILabel        *fileSizeLabel;
@property (nonatomic ,strong)NSMutableDictionary   *imageDic;

@end

@implementation WXFileMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _layer = [[CAShapeLayer alloc] init];
        _radius = sqrt(50 * 50 * 2); // fileIconView对角线长度
        [self.messageBackgroundImageView addSubview:self.fileNameLabel];
        [self.messageBackgroundImageView addSubview:self.fileSizeLabel];
        [self.messageBackgroundImageView addSubview:self.fileIconView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize fileSize = [self messageSize];
    float y = self.message.isSelf ? (CGRectGetMaxY(self.avatarImageView.frame) - FileHeight) : self.avatarImageView.y;
    float x = self.avatarImageView.x + (self.message.isSelf ? - FileWidth - 5 : self.avatarImageView.width + 5);
    self.messageBackgroundImageView.frame = CGRectMake(x, y, FileWidth, FileHeight);
    self.messageSendStatusImageView.center = CGPointMake(x - 20, y + fileSize.height/2.0);
    
    self.fileIconView.frame = CGRectMake(self.messageBackgroundImageView.width - 15 - 60, (FileHeight - 60)/2.0, 60, 60);
    self.fileNameLabel.frame = CGRectMake(15, self.fileIconView.y - 5, self.fileIconView.x - 20, 44);
    self.fileSizeLabel.frame = CGRectMake(15, self.fileNameLabel.bottom + 5, self.fileNameLabel.width, 15);
}

- (void)setMessage:(TIMMessage *)message
{
    [super setMessage:message];
    
    TIMFileElem *fileElem = (TIMFileElem *)[message getElem:0];
    if (!XOIsEmptyString(fileElem.filename)) {
        self.fileNameLabel.text = [fileElem.filename URLDecodedString];
    }
    long long fileSize = fileElem.fileSize;
    if (fileSize > 0) {
        self.fileSizeLabel.text = [self caculationFileSizeWith:fileSize];
    }
    
    // 设置上传或者下载进度
    if (message.isSelf && !fileProgressFinish) {
        UIBezierPath *path = [self getPathWithProgress:0.00f];
        self.progressHud.path = path.CGPath;
        [self.fileIconView.layer addSublayer:self.progressHud];
    } else {
        [self.progressHud removeFromSuperlayer];
    }
    
    if (message.isSelf) {
        UIImage *image = self.imageDic[@"image"];
        if (!image) {
            image = [self image:self.messageBackgroundImageView.image ChangeColor:[UIColor whiteColor]];
            [self.imageDic setObject:image forKey:@"image"];
        }
        self.messageBackgroundImageView.image = image;
    }
}

- (UIImageView *)fileIconView
{
    if (!_fileIconView) {
        _fileIconView = [[UIImageView alloc] initWithImage:[UIImage xo_imageNamedFromChatBundle:@"message_file"]];
        [_fileIconView setContentMode:UIViewContentModeScaleAspectFit];
        [_fileIconView setClipsToBounds:YES];
        [_fileIconView setUserInteractionEnabled:YES];
    }
    return _fileIconView;
}

- (UILabel *)fileNameLabel
{
    if (!_fileNameLabel) {
        _fileNameLabel = [[UILabel alloc] init];
        _fileNameLabel.numberOfLines = 2;
        _fileNameLabel.font = [UIFont systemFontOfSize:15];
        _fileNameLabel.textColor = [UIColor darkTextColor];
        _fileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _fileNameLabel;
}

- (UILabel *)fileSizeLabel
{
    if (!_fileSizeLabel) {
        _fileSizeLabel = [[UILabel alloc] init];
        _fileSizeLabel.font = [UIFont systemFontOfSize:13];
        _fileSizeLabel.textColor = [UIColor grayColor];
    }
    return _fileSizeLabel;
}

- (NSMutableDictionary *)imageDic
{
    if (!_imageDic) {
        _imageDic = [NSMutableDictionary dictionary];
    }
    return _imageDic;
}

#pragma mark ====================== help =======================

- (NSString *)caculationFileSizeWith:(long long)size
{
    NSString *sizeText = nil;
    if (size >= pow(10, 9)) { // size >= 1GB
        sizeText = [NSString stringWithFormat:@"%.2fGB", size / pow(10, 9)];
    } else if (size >= pow(10, 6)) { // 1GB > size >= 1MB
        sizeText = [NSString stringWithFormat:@"%.2fMB", size / pow(10, 6)];
    } else if (size >= pow(10, 3)) { // 1MB > size >= 1KB
        sizeText = [NSString stringWithFormat:@"%.2fKB", size / pow(10, 3)];
    } else { // 1KB > size
        sizeText = [NSString stringWithFormat:@"%zdB", (size_t)size];
    }
    return sizeText;
}

#pragma mark ====================== progress =======================

/** @brief 更新进度  由子类实现
 *  @param effect  NO:表示上传或者下载失败  YES:表示上传中或者下载中,此时进度才有意义
 */
- (void)updateProgress:(float)progress effect:(BOOL)effect
{
    [super updateProgress:progress effect:effect];
    self.progressHud.fillColor  = RGBA(178, 178, 178, 0.5).CGColor;
    
    @synchronized (self) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (!effect) {
                [self.progressHud removeFromSuperlayer];
                fileProgressFinish = YES;
            }
            else {
                UIBezierPath *progressPath = [self getPathWithProgress:progress];
                self.progressHud.path = progressPath.CGPath;
                
                if (progress == 1.0) {
                    [self.progressHud removeFromSuperlayer];
                    fileProgressFinish = YES;
                }
                else {
                    fileProgressFinish = NO;
                    
                    if (![self.fileIconView.layer.sublayers containsObject:self.progressHud]) {
                        [self.fileIconView.layer addSublayer:self.progressHud];
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

- (CGSize)messageSize
{
    return CGSizeMake(FileWidth + 16, FileHeight + MsgCellIconMargin * 2.0);
}

@end
