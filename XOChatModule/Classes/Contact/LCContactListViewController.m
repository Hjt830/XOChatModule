//
//  LCContactListViewController.m
//  XOChatModule
//
//  Created by kenter on 2019/10/11.
//

#import "LCContactListViewController.h"
#import "XOSearchResultListController.h"
#import "XOGroupListViewController.h"
#import "LCContactApplyListController.h"
#import "LCAddNewFriendViewController.h"
#import "LCContactInfoViewController.h"
//#import "XOChatViewController.h"

#import "BMChineseSort.h"
#import "UIColor+XOExtension.h"
#import <SVProgressHUD/SVProgressHUD.h>

static NSString *TableViewCell = @"TableViewCell";
static NSString *ContactCellID = @"ContactCellID";

@interface LCContactListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate, XOSearchResultDelegate, EMContactManagerDelegate>

@property (nonatomic, assign) int                               applyCount;
@property (nonatomic, strong) UITableView                       *tableView;         // 通讯录列表
@property (nonatomic, strong) UIView                            *tableHeaderView;   // 通讯录列表头部试图
@property (nonatomic, strong) UIView                            *contactNumView;
@property (nonatomic, strong) UILabel                           *contactNumLabel;   // 通讯录人数
@property (nonatomic, strong) UISearchBar                       *searchBar;
@property (nonatomic, copy) NSString                            *remark;   // 备注名

@property (nonatomic, strong) NSMutableArray <NSString *> * firstLetterArray;  //排序后的出现过的拼音首字母数组
@property (nonatomic, strong) NSMutableArray <NSMutableArray <XOContact *> *> *sortedModelArr; //排序好的结果数组

@end

@implementation LCContactListViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadLocalContacts) name:XOFriendListUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadLocalContacts) name:XOAsyncFriendListSuccessNotification object:nil];
        self.applyCount = 0;
        
        [[EMClient sharedClient].contactManager addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XOFriendListUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XOAsyncFriendListSuccessNotification object:nil];
    [[EMClient sharedClient].contactManager removeDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = @"好友";
    
    [self setRightBarButtonImage:[UIImage imageNamed:@"Contact_add"]];
    
    [self loadLocalContacts];
    
    // 获取好友申请
    [self loadContactApply];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.tableHeaderView.frame = CGRectMake(0, 0, self.view.width, 50);
    self.searchBar.frame = CGRectMake(20, 9, self.view.width - 40, 32);
    self.tableView.frame = CGRectMake(15, 50 + 15, self.view.width - 30, self.view.height - 50 - 15);
}

- (void)setupUI
{
    [self.view addSubview:self.tableView];
    [self.tableHeaderView addSubview:self.searchBar];
    [self.view addSubview:self.tableHeaderView];
    [self.contactNumView addSubview:self.contactNumLabel];
    self.tableView.tableFooterView = self.contactNumView;
}

#pragma mark ========================= touch event =========================

- (void)rightBBIDidClick:(UIBarButtonItem *)sender
{
    LCAddNewFriendViewController *addVC = [[LCAddNewFriendViewController alloc] initWithNibName:@"LCAddNewFriendViewController" bundle:nil];
    [self.navigationController pushViewController:addVC animated:YES];
}

#pragma mark ====================== lazy load =======================

- (UITableView *)tableView
{
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.separatorInset = UIEdgeInsetsMake(0, 10, 0, 10);
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.rowHeight = 60.f;
        tableView.sectionHeaderHeight = 30.0f;
        tableView.sectionFooterHeight = 0.0f;
        tableView.multipleTouchEnabled = NO;
        [tableView setSectionIndexColor:[UIColor XOTextColor]];
        [tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
        _tableView = tableView;
        
        [tableView registerClass:[XOContactListCell class] forCellReuseIdentifier:ContactCellID];
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCell];
    }
    return _tableView;
}

- (UIView *)tableHeaderView
{
    if (!_tableHeaderView) {
        _tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableHeaderView.backgroundColor = [UIColor XOWhiteColor];
    }
    return _tableHeaderView;
}

- (UIView *)contactNumView
{
    if (_contactNumView == nil) {
        _contactNumView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
        [_contactNumView addSubview:self.contactNumLabel];
    }
    return _contactNumView;
}

- (UILabel *)contactNumLabel
{
    if (_contactNumLabel == nil) {
        _contactNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
        _contactNumLabel.font = [UIFont systemFontOfSize:[[XOSettingManager defaultManager] fontSize]];
        _contactNumLabel.textAlignment = NSTextAlignmentCenter;
        _contactNumLabel.textColor = RGBOF(0x999999);
    }
    return _contactNumLabel;
}

- (UISearchBar *)searchBar
{
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] init];
        _searchBar.delegate = self;
        _searchBar.barStyle = UIBarStyleDefault;
        _searchBar.translucent = YES;
        _searchBar.delegate = self;
        _searchBar.barTintColor = [UIColor groupTableViewColor];
        _searchBar.backgroundImage = [[UIImage alloc] init];
        _searchBar.tintColor = AppTintColor;
        _searchBar.placeholder = @"Search";
        UIImage *image = [[UIImage imageNamed:@"search_background"] XO_imageWithTintColor:RGBOF(0xF5F5F7)];
        [_searchBar setSearchFieldBackgroundImage:image forState:UIControlStateNormal];
    }
    return _searchBar;
}

#pragma mark ====================== 获取通讯录 =======================

- (void)loadLocalContacts
{
    [[XOContactManager defaultManager] getAllContactsList:^(NSArray<XOContact *> * _Nullable friendList) {
        
        __block NSMutableArray <XOContact *>* contactList = [NSMutableArray arrayWithCapacity:1];
        [friendList enumerateObjectsUsingBlock:^(XOContact * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.blackFlag != 2) { // 是否拉黑对方(1:正常,2:拉黑)
                [contactList addObject:obj];
            }
        }];
        // 按照首字母排序
        BMChineseSortSetting.share.sortMode = 1; // 1或2
        [BMChineseSort sortAndGroup:contactList key:@"netName" finish:^(bool isSuccess, NSMutableArray *unGroupedArr, NSMutableArray *sectionTitleArr, NSMutableArray<NSMutableArray <XOContact *> *> *sortedObjArr) {
            if (isSuccess) {
                self.firstLetterArray = sectionTitleArr;
                self.sortedModelArr = sortedObjArr;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView reloadData];
                }];
            }
        }];
        self.contactNumLabel.text = [NSString stringWithFormat:@"%lu 个联系人", (unsigned long)friendList.count];
    }];
}

#pragma mark ========================= 获取好友申请 =========================

- (void)loadContactApply
{
    NSDictionary *dict = @{@"page": @(1), @"pageSize": @(500), @"sortColumn": @"createTm", @"sortOrder": @"desc"};
    [[XOHttpTool shareTool] POST:Member_ApplyList parameters:dict success:^(NSDictionary * _Nullable responseObject, ResponseBean * _Nonnull response) {
        
        if (XOHttpSuccessCode == response.code) {
            NSArray <LCContactApplyModel *>* applyList = [NSArray yy_modelArrayWithClass:[LCContactApplyModel class] json:response.data[@"records"]];
            
            __block int num = 0;
            [applyList enumerateObjectsUsingBlock:^(LCContactApplyModel * _Nonnull apply, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if (LCApplyStatusWaitHandle == apply.status) {
                    num++;
                }
            }];
            self.applyCount = num;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                if (self.applyCount > 0) {
                    [self.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%d", self.applyCount]];
                } else {
                    [self.tabBarItem setBadgeValue:nil];
                }
            });
        }
        
    } fail:^(NSError * _Nullable error) {
        
        NSLog(@"网络请求失败: %@", error);
    }];
}

#pragma mark ====================== 删除好友 =======================

- (void)deleteFriend:(XOContact *)contact indexPath:(NSIndexPath *)indexPath
{
    if (XOIsEmptyString(contact.friendMemberId)) return;
    
    [[XOHttpTool shareTool] POST:Member_DelFriend parameters:@{@"id": contact.friendMemberId} success:^(NSDictionary * _Nullable responseObject, ResponseBean * _Nonnull response) {
        
        if (XOHttpSuccessCode == response.code) {
            BOOL result = [response.data boolValue];
            if (result) {
                @synchronized (self) {
                    if (self.sortedModelArr[indexPath.section - 1].count == 1) {
                        [self.firstLetterArray removeObjectAtIndex:indexPath.section - 1];
                        [self.sortedModelArr removeObjectAtIndex:(indexPath.section - 1)];
                    } else {
                        [self.sortedModelArr[indexPath.section - 1] removeObjectAtIndex:indexPath.row];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                    });
                }
                // 删除数据库好友信息
                [[XOContactManager defaultManager] deleteContact:contact.friendMemberId handler:^(BOOL result) {
                    if (result) {
                        NSLog(@"删除好友成功");
                    } else {
                        NSLog(@"删除好友失败");
                    }
                }];
            }
            else {
                if (!XOIsEmptyString(response.message)) {
                    [self.view makeToast:response.message];
                } else {
                    [self.view makeToast:@"删除好友失败"];
                }
            }
        }
        else {
            if (XOIsEmptyString(response.message)) {
                [self.view makeToast:response.message];
            } else {
                [self.view makeToast:@"删除好友失败"];
            }
        }
        
    } fail:^(NSError * _Nullable error) {
        
        [self.view makeToast:@"网络开小差了哟~"];
    }];
}

#pragma mark ====================== 备注好友 =======================

- (void)updateContactRemark:(XOContact *)contact remark:(NSString *)remark indexPath:(NSIndexPath *)indexPath
{
    if (XOIsEmptyString(remark) || XOIsEmptyString(contact.friendMemberId)) return;
    else if (remark.length > 15) {
        [self.view makeToast:@"备注名长度不能超过15"];
        return;
    }
    
    NSDictionary *parameters = @{@"id": contact.friendMemberId, @"remark": remark};
    [[XOHttpTool shareTool] POST:Member_ModifyRemark parameters:parameters success:^(NSDictionary * _Nullable responseObject, ResponseBean * _Nonnull response) {
        
        if (XOHttpSuccessCode == response.code) {
            BOOL result = [response.data boolValue];
            if (result) {
                contact.remark = remark;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
                // 更新数据库好友信息
                [[XOContactManager defaultManager] updateContact:contact handler:^(BOOL result) {
                    if (result) {
                        NSLog(@"更新好友备注名成功");
                        [self loadLocalContacts];
                    } else {
                        NSLog(@"更新好友备注名失败");
                    }
                }];
            }
            else {
                if (XOIsEmptyString(response.message)) {
                    [self.view makeToast:response.message];
                } else {
                    [self.view makeToast:@"备注失败!"];
                }
            }
        }
        else {
            if (XOIsEmptyString(response.message)) {
                [self.view makeToast:response.message];
            } else {
                [self.view makeToast:@"备注失败!"];
            }
        }
        
    } fail:^(NSError * _Nullable error) {
        
        NSLog(@"网络请求失败: %@", error);
    }];
}

#pragma mark ========================= EMContactManagerDelegate =========================
// 用户B同意用户A的加好友请求后，用户A会收到这个回调
- (void)friendRequestDidApproveByUser:(NSString *)aUsername
{
    [[XOContactManager defaultManager] asyncFriendList];
}
// 用户B删除与用户A的好友关系后，用户A，B会收到这个回调
- (void)friendshipDidRemoveByUser:(NSString *)aUsername
{
    NSString *memberId = [XOUserInfoManager shareManager].memberId;
    // 用户B
    if (![memberId isEqualToString:aUsername]) {
        [[XOContactManager defaultManager] getContactProfile:aUsername handler:^(XOContact * _Nullable contact) {
            if (contact) {
                contact.deleteFlag = 2;
                [[XOContactManager defaultManager] updateContact:contact handler:^(BOOL result) {
                    if (result) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.tableView reloadData];
                        });
                    }
                }];
            }
        }];
    }
    // 用户A
    else {
        // 删除好友
        [[XOContactManager defaultManager] deleteContact:aUsername handler:^(BOOL result) {
            if (result) {
                NSLog(@"删除好友成功");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            } else {
                NSLog(@"删除好友失败");
            }
        }];
    }
}

#pragma mark ====================== UITableViewDataSource =======================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.firstLetterArray.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (0 == section) {
        return 2;
    }
    return [self.sortedModelArr[section - 1] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TableViewCell forIndexPath:indexPath];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        cell.textLabel.textColor = [UIColor XOTextColor];
        if (0 == indexPath.row) {
            cell.imageView.image = [UIImage imageNamed:@"contact_new"];
            cell.textLabel.text = @"新朋友";
            
            UILabel *unreadLabel = [cell.contentView viewWithTag:100];
            if (!unreadLabel) {
                unreadLabel = [[UILabel alloc] init];
                unreadLabel.backgroundColor = [UIColor redColor];
                unreadLabel.font = [UIFont systemFontOfSize:12];
                unreadLabel.textColor = [UIColor whiteColor];
                unreadLabel.textAlignment = NSTextAlignmentCenter;
                unreadLabel.clipsToBounds = YES;
                unreadLabel.layer.cornerRadius = 9.0f;
                unreadLabel.frame = CGRectMake(SCREEN_WIDTH - 45 - 18, 21, 18, 18);
                [cell.contentView addSubview:unreadLabel];
            }
            if (self.applyCount == 0) {
                unreadLabel.hidden = YES;
                unreadLabel.bounds = CGRectZero;
            } else {
                unreadLabel.hidden = NO;
                unreadLabel.bounds = CGRectMake(0, 0, 18, 18);
                unreadLabel.text = [NSString stringWithFormat:@"%d", self.applyCount];
            }
        }
        else {
            cell.imageView.image = [UIImage imageNamed:@"contact_group"];
            cell.textLabel.text = @"群聊";
        }
        return cell;
    }
    else {
        XOContactListCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactCellID forIndexPath:indexPath];
        XOContact *contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
        cell.contact = contact;
        [cell refreshGenralSetting];
        return cell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (0 == section) {
        return nil;
    }
    return self.firstLetterArray[section - 1];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.firstLetterArray;
}

#pragma mark ====================== UITableViewDelegate =======================

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (0 == indexPath.section) {
        if (0 == indexPath.row) {
            LCContactApplyListController *applyVC = [[LCContactApplyListController alloc] init];
            [self.navigationController pushViewController:applyVC animated:YES];
            
            self.applyCount = 0;
            [tableView reloadData];
            [self.tabBarItem setBadgeValue:nil];
        } else {
            XOGroupListViewController *groupListVC = [[XOGroupListViewController alloc] init];
            [self.navigationController pushViewController:groupListVC animated:YES];
        }
    }
    else {
        LCContactInfoViewController *contactInfoVC = [[LCContactInfoViewController alloc] initWithNibName:@"LCContactInfoViewController" bundle:nil];
        contactInfoVC.contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
        [self.navigationController pushViewController:contactInfoVC animated:YES];
    }
}

//实现cell的左滑效果
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > 0) {
        XOContact *contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
        if ([contact.friendMemberId isEqualToString:[XOKeyChainTool getUserName]]) { // 不能删除自己
            return NO;
        }
        return YES;
    }
    return NO;
}

//自定义左滑效果
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    @XOWeakify(self);
    UITableViewRowAction *deleteRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        @XOStrongify(self);
        NSString *message = @"确定删除该联系人吗?";
        [self showSheetWithTitle:nil message:message actions:@[@"确定"] redIndex:nil complection:^(int index, NSString * _Nullable title) {
            if (0 == index) {
                XOContact *contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
                [self deleteFriend:contact indexPath:indexPath];
            }
        } cancelComplection:nil];
    }];
    UITableViewRowAction *editRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"备注名" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        XOContact *contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"备注名" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.delegate = self;
            if (XOIsEmptyString(contact.remark)) {
                textField.placeholder = @"添加备注名";
            } else {
                textField.placeholder = contact.remark;
            }
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [alertVC.view endEditing:YES];
            [self updateContactRemark:contact remark:self.remark indexPath:indexPath];
        }];
        [alertVC addAction:cancel];
        [alertVC addAction:sure];
        [self presentViewController:alertVC animated:YES completion:nil];
    }];
    
    return @[deleteRowAction, editRowAction];
}
// 点击索引
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index - 1;
}

//当前选中组
- (void)selectedSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (0 == section) {
        return 0.01;
    }
    return 30.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([cell respondsToSelector:@selector(tintColor)]) {
        
        CGFloat cornerRadius = 10.f;
        cell.backgroundColor = UIColor.clearColor;
        CAShapeLayer *layer = [[CAShapeLayer alloc] init];
        CGMutablePathRef pathRef = CGPathCreateMutable();
        CGRect bounds = CGRectInset(cell.bounds, 0, 0);
        BOOL addLine = NO;
        if (indexPath.row == 0 && indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
            CGPathAddRoundedRect(pathRef, nil, bounds, cornerRadius, cornerRadius);
        } else if (indexPath.row == 0) {
            
            CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
            CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
            addLine = YES;
            
        } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
            CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius);
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
            CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
        } else {
            CGPathAddRect(pathRef, nil, bounds);
            addLine = YES;
        }
        layer.path = pathRef;
        CFRelease(pathRef);
        //颜色修改
        layer.fillColor = [UIColor XOWhiteColor].CGColor;
        layer.strokeColor = RGBOF(0xeeeeee).CGColor;
        if (addLine == YES) {
            CALayer *lineLayer = [[CALayer alloc] init];
            CGFloat lineHeight = (1.f / [UIScreen mainScreen].scale);
            lineLayer.frame = CGRectMake(CGRectGetMinX(bounds)+10, bounds.size.height-lineHeight, bounds.size.width-20, lineHeight);
            lineLayer.backgroundColor = tableView.separatorColor.CGColor;
            [layer addSublayer:lineLayer];
        }
        UIView *testView = [[UIView alloc] initWithFrame:bounds];
        [testView.layer insertSublayer:layer atIndex:0];
        testView.backgroundColor = UIColor.clearColor;
        cell.backgroundView = testView;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark ========================= UISearchControllerDelegate =========================

- (void)didPresentSearchController:(UISearchController *)searchController
{
    [self.tabBarController.tabBar setHidden:YES];
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    [self.tabBarController.tabBar setHidden:NO];
}

#pragma mark ====================== UISearchBarDelegate =======================

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    
}

#pragma mark ====================== WXSearchResultDelegate =======================

- (void)XOSearchList:(XOSearchResultListController *)search didSelectContact:(id)object
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.26 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        if ([object isKindOfClass:[XOContact class]]) {
//            XOChatViewController *chatVC = [[XOChatViewController alloc] init];
//            XOContact *contact = (XOContact *)object;
//            chatVC.chatType = TIM_C2C;
//            chatVC.conversation = [[TIMManager sharedInstance] getConversation:TIM_C2C receiver:contact.friendMemberId];
//            [self.navigationController pushViewController:chatVC animated:YES];
//        }
//        else if ([object isKindOfClass:[EMGroup class]]) {
//            XOChatViewController *chatVC = [[XOChatViewController alloc] init];
//            EMGroup *group = (EMGroup *)object;
//            chatVC.chatType = TIM_GROUP;
//            chatVC.conversation = [[TIMManager sharedInstance] getConversation:TIM_GROUP receiver:group.group];
//            [self.navigationController pushViewController:chatVC animated:YES];
//        }
    });
}

- (void)XOSearchListDidScrollTable:(XOSearchResultListController *)search
{
    
}

#pragma mark ====================== 字体改变 =======================

- (void)refreshByGenralSettingChange:(XOGenralChangeType)genralType userInfo:(NSDictionary *_Nonnull)userInfo;
{
    [self.tableView reloadData];
    _contactNumLabel.font = [UIFont systemFontOfSize:[[XOSettingManager defaultManager] fontSize]];
}

#pragma mark ====================== UITextFieldDelegate =======================

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.remark = [textField.text copy];
}

@end







@interface XOContactListCell ()
{
    UIImageView *_iconImageView;
    UILabel *_nameLabel;
}
@end

@implementation XOContactListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.separatorInset = UIEdgeInsetsMake(0, 60, 0, 10);
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    _iconImageView = [UIImageView new];
    _iconImageView.clipsToBounds = YES;
    _iconImageView.userInteractionEnabled = YES;
    _iconImageView.backgroundColor = RGBA(221, 222, 224, 1);
    [self.contentView addSubview:_iconImageView];
    
    CGRect bounds = CGRectMake(0, 0, 44, 44);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:bounds.size];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    _iconImageView.layer.mask = maskLayer;
    
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.textColor = [UIColor XOTextColor];
    _nameLabel.font = [UIFont systemFontOfSize:16.0];
    [self.contentView addSubview:_nameLabel];
}

// 通用设置发生改变
- (void)refreshGenralSetting
{
    _nameLabel.font = [UIFont systemFontOfSize:[[XOSettingManager defaultManager] fontSize]];
}

- (void)setContact:(XOContact *)contact
{
    _contact = contact;
    if (contact) {
        _nameLabel.text = contact.netName;
        if (!XOIsEmptyString(contact.remark)) {
            _nameLabel.text = [NSString stringWithFormat:@"%@（%@）", contact.netName, contact.remark];
        }
        if (XOIsEmptyString(contact.headPortrait)) {
            _iconImageView.image = [UIImage imageNamed:@"contact_default"];
        } else {
            [_iconImageView sd_setImageWithURL:[NSURL URLWithString:contact.headPortrait] placeholderImage:[UIImage imageNamed:@"contact_default"]];
        }
    }
    else {
        _nameLabel.text = @"";
        _iconImageView.image = [UIImage imageNamed:@"contact_default"];
    }
}

- (void)setGroup:(EMGroup *)group
{
    _group = group;
    if (group) {
        _nameLabel.text = !XOIsEmptyString(group.subject) ? group.subject : @"";
        UIImage *placeholder = [UIImage groupDefaultImageAvatar];
        _iconImageView.image = placeholder;
        
        [UIImage combineGroupImageWithGroupId:group.groupId complection:^(UIImage * _Nonnull image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_iconImageView.image = image;
            });
        }];
    }
    else {
        _nameLabel.text = @"";
        _iconImageView.image = [UIImage groupDefaultImageAvatar];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat margin = 10;
    _iconImageView.frame = CGRectMake(margin * 2, (self.height - 44)/2.0, 44, 44);
    _iconImageView.layer.cornerRadius = 6.0f;
    _nameLabel.frame = CGRectMake(_iconImageView.right + margin, (self.height - 30)/2.0, self.width - margin - (_iconImageView.right + margin), 30);
    
}

@end
