//
//  ForwardView.m
//  xxoogo
//
//  Created by kenter on 2019/6/12.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "ForwardView.h"
#import "UIImage+XOChatBundle.h"
#import "UIImage+XOChatExtension.h"
#import "NSBundle+ChatModule.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ForwardView ()

@property (nonatomic, strong) NSArray                   *receivers;
@property (nonatomic, strong) TIMMessage                *message;

@property (nonatomic, strong) UIView                    *maskView;
@property (nonatomic, strong) ForwardContentView        *contentView;
@property (nonatomic, strong) UILabel       *sendLabel;
@property (nonatomic, strong) UILabel       *sendNameLabel;
@property (nonatomic, strong) UILabel       *contentLabel;
@property (nonatomic, strong) UIImageView   *contentImageView;
@property (nonatomic, strong) UIButton      *cancelBtn;
@property (nonatomic, strong) UIButton      *sureBtn;

@property (nonatomic, strong) NSMutableArray  <UIImageView *>*reveiverIconArr;

@property (nonatomic, copy) NSString        *name;

@end

@implementation ForwardView

- (void)showInView:(UIView *)view withReceivers:(NSArray <TIMUserProfile *>*)receivers message:(TIMMessage *)message delegate:(id <ForwardViewDelegate>)delegate
{
    [self setDelegate:delegate];
    [self showInView:view];
    [self setReceivers:receivers];
    [self setMessage:message];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.maskView];
        [self addSubview:self.contentView];
        [self.contentView addSubview:self.sendLabel];
        [self.contentView addSubview:self.sendNameLabel];
        [self.contentView addSubview:self.cancelBtn];
        [self.contentView addSubview:self.sureBtn];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.maskView.frame = CGRectMake(0, 0, self.width, self.height);
    TIMElem *elem = [self.message getElem:0];
    
    CGFloat contentW = self.width - 60;
    int count = (contentW - 40)/50; // 一排最多放几个头像
    CGFloat receiverHeight = self.reveiverIconArr.count < count ? 95.0f : 140.0f;
    BOOL isText = [elem isKindOfClass:[TIMTextElem class]];
    CGFloat contentsHeight = isText ? 64 : 140; // 消息内容的高度
    CGFloat contentH = receiverHeight + contentsHeight + 50;
    self.contentView.frame = CGRectMake(30, (self.height - contentH)/2.0, contentW, contentH);
    self.contentView.layer.cornerRadius = 8.0f;
    [self.contentView setNeedsDisplay];

    self.sendLabel.frame = CGRectMake(20, 15, contentH - 40, 20);
    if (self.reveiverIconArr.count == 1) {
        UIImageView *imageView = self.reveiverIconArr[0];
        imageView.frame = CGRectMake(20, 45, 40, 40);
        imageView.layer.cornerRadius = 3.0f;
        self.sendNameLabel.hidden = NO;
        self.sendNameLabel.frame = CGRectMake(70, 50, contentW - imageView.right - 30, 30);
    } else {
        [self.reveiverIconArr enumerateObjectsUsingBlock:^(UIImageView * _Nonnull imageView, NSUInteger idx, BOOL * _Nonnull stop) {
            int row = idx < count ? 0 : 1; // 行数
            int col = idx % count; // 列数
            imageView.frame = CGRectMake(20 + col * 50, 45 + row * 45, 40, 40);
            imageView.layer.cornerRadius = 3.0f;
        }];
        self.sendNameLabel.hidden = YES;
        self.sendNameLabel.frame = CGRectZero;
    }
    
    if (isText) {
        self.contentLabel.frame = CGRectMake(20, receiverHeight + 10, contentW - 40, 44);
    }
    else if ([elem isKindOfClass:[TIMImageElem class]] ||
             [elem isKindOfClass:[TIMVideoElem class]])
    {
        if ([elem isKindOfClass:[TIMImageElem class]]) {
            TIMImage *timImage = [((TIMImageElem *)elem).imageList firstObject];
            CGFloat imageW = 120 * (timImage.width * 1.0/timImage.height * 1.0);
            self.contentImageView.frame = CGRectMake((contentW - imageW)/2.0, receiverHeight + 10, imageW, 120);
        } else {
            UIImage *image = self.contentImageView.image;
            if (image) {
                CGFloat imageW = 120 * (image.size.width/image.size.height);
                self.contentImageView.frame = CGRectMake((contentW - imageW)/2.0, receiverHeight + 10, imageW, 120);
            }
        }
        self.contentImageView.layer.cornerRadius = 3.0f;
    }

    self.cancelBtn.frame = CGRectMake(0, contentH - 50, contentW/2.0 - 0.25, 50);
    self.sureBtn.frame = CGRectMake(contentW/2.0 + 0.25, contentH - 50, contentW/2.0 - 0.25, 50);
}

#pragma mark ========================= assist =========================

- (void)showInView:(UIView *)view
{
    [view addSubview:self];
    self.frame = CGRectMake(0, -self.height, view.width, view.height);
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = CGRectMake(0, 0, view.width, view.height);
    }];
}

- (void)dismissAnimation
{
    self.sendNameLabel.text = nil;
    self.contentLabel.text = nil;
    self.contentImageView.image = nil;

    __block CGRect rect = self.frame;
    rect.origin.y = self.height;
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = rect;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark ========================= setter =========================

- (void)setReceivers:(NSArray *)receivers
{
    _receivers = receivers;
    
    [receivers enumerateObjectsUsingBlock:^(id _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([user isKindOfClass:[TIMUserProfile class]]) {
            TIMUserProfile *contact = (TIMUserProfile *)user;
            [self setName:contact.nickname];
            NSURL *url = [NSURL URLWithString:contact.faceURL];
            [[SDWebImageManager sharedManager] loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self setImage:image];
                }];
            }];
        }
        else if ([user isKindOfClass:[TIMGroupInfo class]]) {
            TIMGroupInfo *group = (TIMGroupInfo *)user;
            [self setName:group.groupName];
            [UIImage combineGroupImageWithGroupId:group.group complection:^(UIImage * _Nonnull image) {
                [self setImage:image];
            }];
        }
    }];
    
    if (_receivers.count <= 5) {
        self.contentView.lineHeight = 95.0f;
    } else {
        self.contentView.lineHeight = 140.0f;
    }
}

- (void)setName:(NSString *)name
{
    _name = [name copy];
    _sendNameLabel.text = _name;
}

- (void)setImage:(UIImage *)image
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.backgroundColor = [UIColor lightGrayColor];
    if (image) {
        imageView.image = image;
    } else {
        imageView.image = [UIImage xo_imageNamedFromChatBundle:@"default_avatar"];
    }
    [self.contentView addSubview:imageView];
    @synchronized (self) {
        [self.reveiverIconArr addObject:imageView];
    }
    [self setNeedsLayout];
}

- (void)setMessage:(TIMMessage *)message
{
    _message = message;
    
    TIMElem *elem = [self.message getElem:0];
    
    if ([elem isKindOfClass:[TIMTextElem class]]) {
        self.contentView.isImage = NO;
        self.contentImageView.hidden = YES;
        self.contentLabel.hidden = NO;
        [self.contentView addSubview:self.contentLabel];
        
        if ([message elemCount] > 0) {
            TIMTextElem *textElem = (TIMTextElem *)[message getElem:0];
            self.contentLabel.text = textElem.text;
        }
    }
    else if ([elem isKindOfClass:[TIMImageElem class]]) {
        self.contentView.isImage = YES;
        self.contentImageView.hidden = NO;
        self.contentLabel.hidden = YES;
        [self.contentView addSubview:self.contentImageView];
        
        if ([message elemCount] > 0) {
            TIMImageElem *imageElem = (TIMImageElem *)[message getElem:0];
            if (imageElem.imageList.count > 0) {
                TIMImage *timImage = imageElem.imageList[0];
                [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:timImage.url] options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                    if (!error && image) {
                        self.contentImageView.image = image;
                    }
                }];
            }
        }
    }
    else if ([elem isKindOfClass:[TIMVideoElem class]]) {
        self.contentView.isImage = YES;
        self.contentImageView.hidden = NO;
        self.contentLabel.hidden = YES;
        [self.contentView addSubview:self.contentImageView];
        
        if ([message elemCount] > 0) {
            TIMVideoElem *videoElem = (TIMVideoElem *)[message getElem:0];
            __block NSString *path = nil;
            if (!XOIsEmptyString(videoElem.snapshotPath)) {
                path = [NSTemporaryDirectory() stringByAppendingPathComponent:videoElem.snapshotPath.lastPathComponent];
            } else {
                path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", videoElem.snapshot.uuid]];
            }
            UIImage *image = [UIImage imageNamed:path];
            if (image) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    self.contentImageView.image = image;
                    [self setNeedsDisplay];
                }];
            } else {
                [videoElem.snapshot getImage:path succ:^{
                    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                        UIImage *image = [UIImage imageNamed:path];
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            self.contentImageView.image = image;
                            [self setNeedsDisplay];
                        }];
                    }];
                } fail:nil];
            }
        }
    }
}

#pragma mark ========================= event =========================

- (void)sure:(UIButton *)sender
{
    [self dismissAnimation];

    if (self.delegate && [self.delegate respondsToSelector:@selector(forwardView:forwardMessage:toReceivers:)]) {
        [self.delegate forwardView:self forwardMessage:self.message toReceivers:self.receivers];
    }
}

- (void)cancel:(id)sender
{
    [self dismissAnimation];

    if (self.delegate && [self.delegate respondsToSelector:@selector(forwardViewDidCancelForward:)]) {
        [self.delegate forwardViewDidCancelForward:self];
    }
}

#pragma mark ========================= lazy load =========================

- (NSMutableArray *)reveiverIconArr
{
    if (!_reveiverIconArr) {
        _reveiverIconArr = [NSMutableArray array];
    }
    return _reveiverIconArr;
}

- (UIView *)maskView
{
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        _maskView.backgroundColor = RGBA(78 , 78, 78, 0.6);

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancel:)];
        [_maskView addGestureRecognizer:tap];
    }
    return _maskView;
}

- (ForwardContentView *)contentView
{
    if (!_contentView) {
        _contentView = [[ForwardContentView alloc] init];
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.clipsToBounds = YES;
    }
    return _contentView;
}

- (UILabel *)sendLabel
{
    if (!_sendLabel) {
        _sendLabel = [[UILabel alloc] init];
        _sendLabel.textColor = [UIColor blackColor];
        _sendLabel.textAlignment = NSTextAlignmentLeft;
        _sendLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _sendLabel.text = XOChatLocalizedString(@"chat.message.forward.send");
    }
    return _sendLabel;
}

- (UILabel *)sendNameLabel
{
    if (!_sendNameLabel) {
        _sendNameLabel = [[UILabel alloc] init];
        _sendNameLabel.textColor = [UIColor blackColor];
        _sendNameLabel.textAlignment = NSTextAlignmentLeft;
        _sendNameLabel.font = [UIFont boldSystemFontOfSize:13.0];
    }
    return _sendNameLabel;
}

- (UILabel *)contentLabel
{
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.textColor = [UIColor grayColor];
        _contentLabel.textAlignment = NSTextAlignmentLeft;
        _contentLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _contentLabel.numberOfLines = 3;
    }
    return _contentLabel;
}

- (UIImageView *)contentImageView
{
    if (!_contentImageView) {
        _contentImageView = [[UIImageView alloc] init];
        _contentImageView.contentMode = UIViewContentModeScaleAspectFill;
        _contentImageView.clipsToBounds = YES;
        _contentImageView.image = [UIImage xo_imageNamedFromChatBundle:@"default_image"];
    }
    return _contentImageView;
}

- (UIButton *)cancelBtn
{
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setTitle:XOLocalizedString(@"cancel") forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        [_cancelBtn setBackgroundImage:[UIImage XO_imageWithColor:[UIColor whiteColor] size:CGSizeMake(20, 20)] forState:UIControlStateNormal];
        [_cancelBtn setBackgroundImage:[UIImage XO_imageWithColor:RGB(220, 220, 220) size:CGSizeMake(20, 20)] forState:UIControlStateHighlighted];
        [_cancelBtn addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)sureBtn
{
    if (!_sureBtn) {
        _sureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sureBtn setTitle:XOLocalizedString(@"sure") forState:UIControlStateNormal];
        [_sureBtn setTitleColor:AppTinColor forState:UIControlStateNormal];
        [_sureBtn setBackgroundImage:[UIImage XO_imageWithColor:[UIColor whiteColor] size:CGSizeMake(20, 20)] forState:UIControlStateNormal];
        [_sureBtn setBackgroundImage:[UIImage XO_imageWithColor:RGB(220, 220, 220) size:CGSizeMake(20, 20)] forState:UIControlStateHighlighted];
        [_sureBtn addTarget:self action:@selector(sure:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sureBtn;
}

@end





@implementation ForwardContentView

- (void)drawRect:(CGRect)rect
{
    //获得处理的上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    //设置线的颜色
    CGContextSetStrokeColorWithColor(context, RGBA(220, 220, 220, 1.0).CGColor);
    //设置线的宽度
    CGContextSetLineWidth(context, 0.3);

    //起始点设置为(0,0):注意这是上下文对应区域中的相对坐标，
    CGContextMoveToPoint(context, 20, self.lineHeight);
    //设置下一个坐标点
    CGContextAddLineToPoint(context, self.width - 20, self.lineHeight);
    //连接上面定义的坐标点，也就是开始绘图
    CGContextStrokePath(context);

    //起始点设置为(0,0):注意这是上下文对应区域中的相对坐标，
    CGContextMoveToPoint(context, 0, self.height - 50.3);
    //设置下一个坐标点
    CGContextAddLineToPoint(context, self.width, self.height - 50.3);
    //连接上面定义的坐标点，也就是开始绘图
    CGContextStrokePath(context);

    //起始点设置为(0,0):注意这是上下文对应区域中的相对坐标，
    CGContextMoveToPoint(context, self.width/2.0, self.height - 50);
    //设置下一个坐标点
    CGContextAddLineToPoint(context, self.width/2.0, self.height);
    //连接上面定义的坐标点，也就是开始绘图
    CGContextStrokePath(context);
}

@end
