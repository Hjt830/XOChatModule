//
//  JTBaseTableViewController.h
//  JTMainProject
//
//  Created by kenter on 2019/6/29.
//  Copyright © 2019 KENTER. All rights reserved.
//

#import "JTBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface JTBaseTableViewController : JTBaseViewController <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithStyle:(UITableViewStyle)style;

@property (nonatomic, strong, null_resettable) UITableView  *tableView;

@property (nonatomic, assign) BOOL                      showBackgroundView; // 默认是NO, 设置为YES后添加backgroundView
@property (nonatomic, strong, nullable) UIImage         *backgroundImage;   // 设置backgroundView的图片
@property (nonatomic, strong, nullable) NSString        *backgroundTitle;   // 设置backgroundView的标题

@end

NS_ASSUME_NONNULL_END
