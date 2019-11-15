//
//  MemberTableViewCell.m
//  xxoogo
//
//  Created by DZ on 2019/5/23.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "MemberTableViewCell.h"
#import "UIImageView+WebCache.h"
#import "UIImage+XOChatBundle.h"
#import "UIImage+XOChatExtension.h"
#import <XOBaseLib/XOBaseLib.h>

@implementation MemberTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ([super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.selectImage];
        [self.contentView addSubview:self.iconimagev];
        [self.contentView addSubview:self.nameLabel];
    }
    return self;
}

-(UIImageView *)selectImage{
    if (_selectImage == nil) {
        _selectImage = [[UIImageView alloc] init];
        _selectImage.clipsToBounds = YES;
        [_selectImage setImage:[UIImage xo_imageNamedFromChatBundle:@"group_member"]];
    }
    return _selectImage;
}

- (UIImageView *)iconimagev{
    if (_iconimagev == nil) {
        _iconimagev = [[UIImageView alloc]init];
        _iconimagev.clipsToBounds = YES;
        _iconimagev.image = [UIImage xo_imageNamedFromChatBundle:@"default_avatar"];
        
        CGRect bounds = CGRectMake(0, 0, 40, 40);
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:bounds.size];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = bounds;
        maskLayer.path = maskPath.CGPath;
        _iconimagev.layer.mask = maskLayer;
    }
    return _iconimagev;
}

- (UILabel *)nameLabel{
    if (_nameLabel == nil) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _nameLabel;
}

- (void)layoutSubviews
{
    self.selectImage.frame = CGRectMake(10, 23, 14, 14);
    self.selectImage.layer.cornerRadius = 7;
    self.iconimagev.frame = CGRectMake(CGRectGetMaxX(self.selectImage.frame) +10, 10, 40, 40);
    self.iconimagev.layer.cornerRadius = 7;
    self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.iconimagev.frame) +10, 10, 150, 40);
}

- (void)setFriendInfo:(TIMFriend *)friendInfo
{
    _friendInfo = friendInfo;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!XOIsEmptyString(friendInfo.profile.faceURL)) {
            [self.iconimagev sd_setImageWithURL:[NSURL URLWithString:friendInfo.profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
        }else{
           self.iconimagev.image = [UIImage xo_imageNamedFromChatBundle:@"default_avatar"];
        }
        self.nameLabel.text = friendInfo.profile.nickname;
    }];
}

- (void)setGroupInfo:(TIMGroupInfo *)groupInfo
{
    _groupInfo = groupInfo;
    if (!XOIsEmptyString(groupInfo.faceURL)) {
        [UIImage combineGroupImageWithGroupId:groupInfo.group complection:^(UIImage * _Nonnull image) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (image) {
                    self.iconimagev.image = image;
                } else {
                    self.iconimagev.image = [UIImage groupDefaultImageAvatar];
                }
            }];
        }];
    }
    else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.iconimagev.image = [UIImage groupDefaultImageAvatar];
        }];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.nameLabel.text = groupInfo.groupName;
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.selectImage.image = [UIImage xo_imageNamedFromChatBundle:@"group_member_selected"];
    } else {
        self.selectImage.image = [UIImage xo_imageNamedFromChatBundle:@"group_member"];
    }
}



@end
