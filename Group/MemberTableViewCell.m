//
//  MemberTableViewCell.m
//  xxoogo
//
//  Created by DZ on 2019/5/23.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "MemberTableViewCell.h"
#import "UIImageView+WebCache.h"

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
        [_selectImage setImage:[UIImage imageNamed:@"group_member"]];
    }
    return _selectImage;
}

- (UIImageView *)iconimagev{
    if (_iconimagev == nil) {
        _iconimagev = [[UIImageView alloc]init];
        _iconimagev.clipsToBounds = YES;
    }
    return _iconimagev;
}

- (UILabel *)nameLabel{
    if (_nameLabel == nil) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textColor = kBlackColor;
        _nameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _nameLabel;
}

-(void)layoutSubviews{
    self.selectImage.frame = CGRectMake(10, 23, 14, 14);
    self.selectImage.layer.cornerRadius = 7;
    self.iconimagev.frame = CGRectMake(CGRectGetMaxX(self.selectImage.frame) +10, 10, 40, 40);
    self.iconimagev.layer.cornerRadius = 7;
    self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.iconimagev.frame) +10, 10, 150, 40);
}

-(void)giveSubviewValueWithData:(FansBean *)bean{
    if (bean.picture.length > 0) {
        [self.iconimagev sd_setImageWithURL:[NSURL URLWithString:bean.picture] placeholderImage:[UIImage imageNamed:@"default_avatar"]];
    }else{
       self.iconimagev.image = [UIImage imageNamed:@"default_avatar"];
    }
    self.nameLabel.text = bean.realName;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.selectImage.image = [UIImage imageNamed:@"group_member_selected"];
    }
    else {
        self.selectImage.image = [UIImage imageNamed:@"group_member"];
    }
}

- (void)setMemberInfo:(GroupMemberInfoModel *)memberInfo
{
    _memberInfo = memberInfo;
    
    if (!XOIsEmptyString(memberInfo.picture)) {
        [self.iconimagev sd_setImageWithURL:[NSURL URLWithString:memberInfo.picture] placeholderImage:[UIImage imageNamed:@"default_avatar"]];
    }else{
        self.iconimagev.image = [UIImage imageNamed:@"default_avatar"];
    }
    
    self.nameLabel.text = memberInfo.realName;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}



@end
