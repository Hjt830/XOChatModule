//
//  GroupInfoEditViewController.m
//  xxoogo
//
//  Created by 黄金柱 on 2019/5/28.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "GroupInfoEditViewController.h"
#import <XOBaseLib/XOBaseLib.h>
#import "NSBundle+ChatModule.h"
#import "UIImage+XOChatBundle.h"
#import "UIImage+XOChatExtension.h"
#import "XOContactManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <FSTextView/FSTextView.h>

@interface GroupInfoEditViewController ()

@property (nonatomic, strong) UIView                  *backgroundView;
@property (nonatomic, strong) FSTextView              *noticeTV;
@property (nonatomic, strong) UILabel                 *limitLabel;

@end

@implementation GroupInfoEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BG_TableColor;
    
    if (GroupEditTypeGroupName == self.editType) {
        self.title = XOChatLocalizedString(@"group.setting.groupname");
    } else if (GroupEditTypeNotification == self.editType) {
        self.title = XOChatLocalizedString(@"group.setting.notification");
    }
    
    [self setupSubViews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.backgroundView.frame = CGRectMake(0, 10, self.view.width, 108);
    self.noticeTV.frame = CGRectMake(10, 10, self.view.width - 20, 88);
    self.limitLabel.frame = CGRectMake(10, self.backgroundView.bottom + 8, self.view.width - 20, 12);
}

- (void)setupSubViews
{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_backgroundView];
    }
    [self.backgroundView addSubview:self.noticeTV];
    
    if (GroupEditTypeGroupName == self.editType) {
        self.noticeTV.placeholder = XOChatLocalizedString(@"group.setting.groupname");
        self.noticeTV.text = self.groupInfo.groupName;
        self.noticeTV.maxLength = 40;
        self.limitLabel.text = XOChatLocalizedString(@"group.setting.groupname.limit");
    }
    else if (GroupEditTypeNotification == self.editType) {
        self.noticeTV.placeholder = XOChatLocalizedString(@"group.setting.notification");
        self.noticeTV.text = self.groupInfo.notification;
        self.noticeTV.maxLength = 50;
        self.limitLabel.text = XOChatLocalizedString(@"group.setting.notification.limit");
    }
    [self.view addSubview:self.limitLabel];
    
    if (!self.isOwner) {
        [self.noticeTV setEditable:NO];
    } else {
        [self.noticeTV setEditable:YES];
    }
    
    if (self.isOwner) {
        UIButton *ringhtBBI = [UIButton buttonWithType:UIButtonTypeCustom];
        ringhtBBI.bounds = CGRectMake(0, 0, 44, 44);
        [ringhtBBI setTitle:XOLocalizedString(@"sure") forState:UIControlStateNormal];
        [ringhtBBI setTitleColor:AppTinColor forState:UIControlStateNormal];
        [ringhtBBI addTarget:self action:@selector(rightBBIClick:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:ringhtBBI];
    }
}

- (FSTextView *)noticeTV
{
    if (!_noticeTV) {
        _noticeTV = [[FSTextView alloc] init];
        _noticeTV.textAlignment = NSTextAlignmentLeft;
        _noticeTV.font = [UIFont systemFontOfSize:15.0];
    }
    return _noticeTV;
}

- (UILabel *)limitLabel
{
    if (!_limitLabel) {
        _limitLabel = [[UILabel alloc] init];
        _limitLabel.textColor = [UIColor redColor];
        _limitLabel.font = [UIFont systemFontOfSize:11.0];
        _limitLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _limitLabel;
}

#pragma mark ========================= Touch event =========================

- (void)rightBBIClick:(UIButton *)sender
{
    if (GroupEditTypeGroupName == self.editType) {
        NSString *groupName = [self.noticeTV.text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        [self modifyGroupName:groupName];
    }
    else if (GroupEditTypeNotification == self.editType) {
        NSString *groupNotification = [self.noticeTV.text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        [self modifyGroupNotification:groupNotification];
    }
}

- (void)goback
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark ========================= api =========================

- (void)modifyGroupName:(NSString *)groupName
{
    if (XOIsEmptyString(groupName)) {
        [SVProgressHUD showWithStatus:XOChatLocalizedString(@"group.setting.groupname.empty")];
        [SVProgressHUD dismissWithDelay:2.0f];
        return;
    }
    
    [SVProgressHUD show];
    [[TIMGroupManager sharedInstance] modifyGroupName:self.groupInfo.group groupName:groupName succ:^{
        
        [SVProgressHUD showWithStatus:XOChatLocalizedString(@"group.setting.modify.success")];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(groupInfoEdit:didEditSuccess:editType:)]) {
            [self.delegate groupInfoEdit:self didEditSuccess:groupName editType:GroupEditTypeGroupName];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self.navigationController popViewControllerAnimated:YES];
        });
        
        // 更新数据库
        self.groupInfo.groupName = groupName;
        [[XOContactManager defaultManager] updateGroup:self.groupInfo handler:^(BOOL result) {
            if(result) NSLog(@"更新本地群名称成功");
            else NSLog(@"更新本地群名称失败");
        }];
        
    } fail:^(int code, NSString *msg) {
        [SVProgressHUD showWithStatus:XOChatLocalizedString(@"group.setting.modify.fail")];
        [SVProgressHUD dismissWithDelay:1.5f];
    }];
}

- (void)modifyGroupNotification:(NSString *)notification
{
    if (XOIsEmptyString(notification)) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"group.setting.notification.empty", nil)];
        [SVProgressHUD dismissWithDelay:2.0f];
        return;
    }
    
    [SVProgressHUD show];
    [[TIMGroupManager sharedInstance] modifyGroupNotification:self.groupInfo.group notification:notification succ:^{
        
        [SVProgressHUD showWithStatus:XOChatLocalizedString(@"group.setting.modify.success")];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(groupInfoEdit:didEditSuccess:editType:)]) {
            [self.delegate groupInfoEdit:self didEditSuccess:notification editType:GroupEditTypeNotification];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self.navigationController popViewControllerAnimated:YES];
        });
        
        // 更新数据库
        self.groupInfo.notification = notification;
        [[XOContactManager defaultManager] updateGroup:self.groupInfo handler:^(BOOL result) {
            if(result) NSLog(@"更新本地群公告成功");
            else NSLog(@"更新本地群公告失败");
        }];
        
    } fail:^(int code, NSString *msg) {
        [SVProgressHUD showWithStatus:XOChatLocalizedString(@"group.setting.modify.fail")];
        [SVProgressHUD dismissWithDelay:1.5f];
    }];
}


@end
