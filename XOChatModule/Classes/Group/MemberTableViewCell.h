//
//  MemberTableViewCell.h
//  xxoogo
//
//  Created by DZ on 2019/5/23.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImSDK/ImSDK.h>

@interface  MemberTableViewCell: UITableViewCell

@property (nonatomic, strong) UIImageView   *selectImage;
@property (nonatomic, strong) UIImageView   *iconimagev;
@property (nonatomic, strong) UILabel       *nameLabel;

@property (nonatomic, strong) TIMFriend     *friendInfo;
@property (nonatomic, strong) TIMGroupInfo  *groupInfo;

@property (nonatomic, copy) void(^addblock)(void);


@end


