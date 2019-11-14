//
//  GroupInfoEditViewController.m
//  xxoogo
//
//  Created by 黄金柱 on 2019/5/28.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "GroupInfoEditViewController.h"

@interface GroupInfoEditViewController ()

@property (nonatomic, strong) UIView                  *backgroundView;
@property (nonatomic, strong) UITextField             *nameTF;
@property (nonatomic, strong) UITextView              *noticeTV;

@end

@implementation GroupInfoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RGBOF(0xF5F5F7);
    
    if (GroupEditTypeName == self.editType) {
        self.title = NSLocalizedString(@"live.groupnm", nil);
    } else if (GroupEditTypeNotice == self.editType) {
        self.title = NSLocalizedString(@"live.groupnt", nil);
    }
    
    [self setupSubViews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (GroupEditTypeName == self.editType) {
        self.backgroundView.frame = CGRectMake(0, 10, self.view.width, 44);
        self.nameTF.frame = CGRectMake(10, 2, self.view.width - 20, 40);
    }
    else if (GroupEditTypeNotice == self.editType) {
        self.backgroundView.frame = CGRectMake(0, 10, self.view.width, 273);
        self.noticeTV.frame = CGRectMake(10, 2, self.view.width - 20, 269);
    }
}

- (void)setupSubViews
{
    UIButton *leftbut = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftbut setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [leftbut addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftbut];
        
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_backgroundView];
    }
    
    if (GroupEditTypeName == self.editType) {
        [self.backgroundView addSubview:self.nameTF];
        
        if (XOIsEmptyString(self.xoGroupModel.name)) {
            self.nameTF.placeholder = @"Your group name";
        } else {
            self.nameTF.text = self.xoGroupModel.name;
        }
    }
    else if (GroupEditTypeNotice == self.editType) {
        [self.backgroundView addSubview:self.noticeTV];
        
        if (!self.isOwner) {
            [self.noticeTV setEditable:NO];
        }
        
        if (XOIsEmptyString(self.xoGroupModel.notice)) {
            self.noticeTV.text = @"";
        } else {
            self.noticeTV.text = self.xoGroupModel.notice;
        }
    }

    if (self.isOwner) {
        UIButton *ringhtBBI = [UIButton buttonWithType:UIButtonTypeCustom];
        ringhtBBI.bounds = CGRectMake(0, 0, 44, 44);
        [ringhtBBI setTitle:NSLocalizedString(@"live.ok", nil) forState:UIControlStateNormal];
        [ringhtBBI setTitleColor:mainPurpleColor forState:UIControlStateNormal];
        [ringhtBBI addTarget:self action:@selector(rightBBIClick:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:ringhtBBI];
    }
}

- (UITextField *)nameTF
{
    if (!_nameTF) {
        _nameTF = [[UITextField alloc] init];
        _nameTF.textAlignment = NSTextAlignmentLeft;
        _nameTF.font = [UIFont systemFontOfSize:15];
        _nameTF.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    return _nameTF;
}

- (UITextView *)noticeTV
{
    if (!_noticeTV) {
        _noticeTV = [[UITextView alloc] init];
        _noticeTV.textAlignment = NSTextAlignmentLeft;
        _noticeTV.font = [UIFont systemFontOfSize:15];
    }
    return _noticeTV;
}

#pragma mark ========================= Touch event =========================

- (void)rightBBIClick:(UIButton *)sender
{
    if (GroupEditTypeName == self.editType) {
        NSString *groupName = [self.nameTF.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self modifyGroupName:groupName];
    }
    else if (GroupEditTypeNotice == self.editType) {
        NSString *groupNotice = [self.noticeTV.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self modifyGroupNotice:groupNotice];
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
        [UIDialogView showDialgWithText:NSLocalizedString(@"msg.modify.groupname.tip", nil) okClick:nil];
        return;
    }
    
    // type  1 -- 修改群名称   2 -- 修改群公告
    [SVProgressHUD show];
    HttpPost *http = [HttpPost modifyGroupInfo:self.groupId type:1 groupName:groupName groupNotice:nil];
    [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
    
        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:request.responseObject];
        if (XOHttpSuccessCode == reponse.code) {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"msg.modify.success", nil)];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self.navigationController popViewControllerAnimated:YES];
            });
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(groupInfoEdit:didEditSuccess:)]) {
                [self.delegate groupInfoEdit:self didEditSuccess:groupName];
            }
            
            [[GroupManager shareManager] modifyGroupName:groupName withGroupId:self.groupId];
        }
        else {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"msg.modify.fail", nil)];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
        
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        
        [SVProgressHUD showWithStatus:NSLocalizedString(@"msg.modify.fail", nil)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
}

- (void)modifyGroupNotice:(NSString *)groupNotice
{
    if (XOIsEmptyString(groupNotice)) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"msg.modify.groupnotice.tip", nil)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
        return;
    }
    
    // type  1 -- 修改群名称   2 -- 修改群公告
    [SVProgressHUD show];
    HttpPost *http = [HttpPost modifyGroupInfo:self.groupId type:2 groupName:nil groupNotice:groupNotice];
    [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        
        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:request.responseObject];
        if (XOHttpSuccessCode == reponse.code) {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"msg.modify.success", nil)];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self.navigationController popViewControllerAnimated:YES];
            });
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(groupInfoEdit:didEditSuccess:)]) {
                [self.delegate groupInfoEdit:self didEditSuccess:groupNotice];
            }
            
            [[GroupManager shareManager] modifyGroupNotice:groupNotice withGroupId:self.groupId];
        }
        else {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"msg.modify.fail", nil)];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
        
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        
        [SVProgressHUD showWithStatus:NSLocalizedString(@"msg.modify.fail", nil)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
}


@end
