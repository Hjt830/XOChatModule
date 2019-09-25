//
//  WXLocationMessageCell.m
//  WXMainProject
//
//  Created by 乐派 on 2019/4/23.
//  Copyright © 2019年 乐派. All rights reserved.
//

#import "WXLocationMessageCell.h"

@interface WXLocationMessageCell ()
{
    CAShapeLayer    *_layer;
}
@property (nonatomic ,strong) UIImageView   *positionImageView;
@property (nonatomic ,strong) UILabel       *addressLabel;
@property (nonatomic ,strong) UIImageView   *addressPoi;
@property (nonatomic, strong) MKMapView     *mapView;

@end

@implementation WXLocationMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        _layer = [[CAShapeLayer alloc] init];
        [self.contentView insertSubview:self.positionImageView belowSubview:self.messageBackgroundImageView];
        [self.contentView addSubview:self.addressPoi];
        [self.contentView addSubview:self.addressLabel];
    }
    return self;
}

- (void)setMessage:(TIMMessage *)message
{
    [super setMessage:message];
    
    [self.messageBackgroundImageView setImage:nil];
    // 设置图片
    self.positionImageView.image = [UIImage xo_imageNamedFromChatBundle:@"placeholderImage"];
    TIMLocationElem *locationElem = (TIMLocationElem *)[message getElem:0];
//    if (!XOIsEmptyString(imageElem.path)) {
//        NSString *path = [DocumentPath() stringByAppendingPathComponent:message.body.thumbnailLocalPath];
//        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
//            UIImage *image = [UIImage imageWithContentsOfFile:path];
//            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                self.positionImageView.image = image;
//            }];
//        }];
//    }
//    else if (!XOIsEmptyString(message.path)) {
//        [[WXMsgFileManager shareManager] downloadMessageThumbImage:message result:^(BOOL finish, HTMessage * _Nonnull aMessage, NSError * _Nullable error) {
//            NSString *path = [DocumentPath() stringByAppendingPathComponent:message.body.thumbnailLocalPath];
//            [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
//                UIImage *image = [UIImage imageWithContentsOfFile:path];
//                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    self.positionImageView.image = image;
//                }];
//            }];
//        }];
//    }
    // 设置文字
    NSString *address = locationElem.desc;
    if (!XOIsEmptyString(address)) {
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[UIColor lightGrayColor]];
        [shadow setShadowOffset:CGSizeMake(-0.3, 0.3)];
        NSMutableAttributedString *addressAttr = [[NSMutableAttributedString alloc] initWithString:address];
        [addressAttr addAttribute:NSForegroundColorAttributeName value:[UIColor darkTextColor] range:NSMakeRange(0, addressAttr.length)];
        [addressAttr addAttribute:NSShadowAttributeName value:shadow range:NSMakeRange(0, addressAttr.length)];
        self.addressLabel.attributedText = addressAttr;
        self.addressLabel.hidden = NO;
        self.addressPoi.hidden = NO;
    }
    else {
        self.addressLabel.attributedText = nil;
        self.addressLabel.hidden = YES;
        self.addressPoi.hidden = YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // 显示缩略图
    CGSize imageSize = [self messageSize];
    float y = self.avatarImageView.y;
    float sendY = y + imageSize.height/2.0;
    if (self.message.isSelf) {
        float x = self.avatarImageView.x - imageSize.width - 10;
        [self.messageBackgroundImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.positionImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.messageSendStatusImageView setCenter:CGPointMake(x - 20, sendY)];
        self.progressHud.bounds     = CGRectMake(0, 0, imageSize.width, imageSize.height);
        self.progressHud.position   = CGPointMake(imageSize.width/2.0, imageSize.height/2.0);
    }
    else {
        float x = CGRectGetMaxX(self.avatarImageView.frame) + 10;
        [self.messageBackgroundImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.positionImageView setFrame:CGRectMake(x, y, imageSize.width, imageSize.height)];
        [self.messageSendStatusImageView setCenter:CGPointMake(x + imageSize.width + 20, sendY)];
    }
    
    float width = [self.addressLabel sizeThatFits:CGSizeMake(MAXFLOAT, 18)].width;
    if (width > imageSize.width - 23) width = imageSize.width - 20;
    self.addressPoi.frame = CGRectMake(self.positionImageView.x, self.positionImageView.bottom + 5, 15, 15);
    self.addressLabel.frame = CGRectMake(self.addressPoi.right + 5, self.positionImageView.bottom + 3.5, width, 18);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.positionImageView.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(5.0, 5.0)];
    _layer.path = path.CGPath;
    _layer.frame = self.positionImageView.bounds;
}


- (UIImageView *)positionImageView
{
    if (!_positionImageView) {
        _positionImageView = [[UIImageView alloc] init];
        [_positionImageView setContentMode:UIViewContentModeScaleAspectFill];
        [_positionImageView setClipsToBounds:YES];
        [_positionImageView.layer setMask:_layer];
    }
    return _positionImageView;
}

- (UILabel *)addressLabel
{
    if (!_addressLabel) {
        _addressLabel = [[UILabel alloc] init];
        _addressLabel.font = [UIFont systemFontOfSize:13];
        _addressLabel.textColor = [UIColor darkTextColor];
        _addressLabel.clipsToBounds = YES;
        _addressLabel.layer.cornerRadius = 5.0f;
        _addressLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _addressLabel;
}

- (UIImageView *)addressPoi
{
    if (!_addressPoi) {
        _addressPoi = [[UIImageView alloc] initWithImage:[UIImage xo_imageNamedFromChatBundle:@"message_location_poi"]];
        [_addressPoi setContentMode:UIViewContentModeScaleAspectFit];
    }
    return _addressPoi;
}

/** @brief 更新进度  由子类实现
 *  @param effect  NO:表示上传或者下载失败  YES:表示上传中或者下载中,此时进度才有意义
 */
- (void)updateProgress:(float)progress effect:(BOOL)effect {}

- (CGSize)messageSize
{
    float FileWidth = 220.0f;
    float FileHeight = 80.0f;
    return CGSizeMake(FileWidth + 16, FileHeight + 20);
}


@end
