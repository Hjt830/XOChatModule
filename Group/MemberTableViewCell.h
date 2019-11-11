//
//  MemberTableViewCell.h
//  xxoogo
//
//  Created by DZ on 2019/5/23.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FansBean.h"
#import "CreateGroupViewController.h"

@interface  MemberTableViewCell: UITableViewCell

@property (nonatomic, strong) UIImageView   *selectImage;
@property (nonatomic, strong) UIImageView   *iconimagev;
@property (nonatomic, strong) UILabel       *nameLabel;

@property (nonatomic, strong) GroupMemberInfoModel         *memberInfo;

@property (nonatomic, copy) void(^addblock)(void);


-(void)giveSubviewValueWithData:(FansBean *)bean;


@end


