//
//  XOContactListViewController.m
//  XOChatModule
//
//  Created by kenter on 2019/10/11.
//

#import "XOContactListViewController.h"
#import "XOSearchResultListController.h"
#import "XOGroupListViewController.h"
#import "XOChatViewController.h"

#import "XOChatClient.h"
#import "BMChineseSort.h"
#import "UIImage+XOChatBundle.h"
#import "UIImage+XOChatExtension.h"
#import "NSBundle+ChatModule.h"
#import "UIColor+XOExtension.h"
#import <SVProgressHUD/SVProgressHUD.h>

static NSString *TableViewCell = @"TableViewCell";
static NSString *ContactCellID = @"ContactCellID";

@interface XOContactListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UITextFieldDelegate, XOSearchResultDelegate>

@property (nonatomic, strong) UITableView                       *tableView;         // 通讯录列表
@property (nonatomic, strong) UIView                            *tableHeaderView;   // 通讯录列表头部试图
@property (nonatomic, strong) UIView                            *contactNumView;
@property (nonatomic, strong) UILabel                           *contactNumLabel;   // 通讯录人数
@property (nonatomic, strong) UISearchController                *searchController;
@property (nonatomic, strong) XOSearchResultListController      *resultController;
@property (nonatomic, copy) NSString                            *remark;   // 备注名

@property (nonatomic, strong)NSMutableArray <NSString *> * firstLetterArray;  //排序后的出现过的拼音首字母数组
@property (nonatomic, strong)NSMutableArray <NSMutableArray <TIMFriend *> *> *sortedModelArr; //排序好的结果数组

@end

@implementation XOContactListViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadLocalContacts];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = XOChatLocalizedString(@"contact.addressbook");
    
    [self setupUI];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat searBarHeight = self.searchController.searchBar.height;
    self.tableHeaderView.frame = CGRectMake(0, 0, self.view.width, searBarHeight);
    self.tableView.frame = CGRectMake(0, 0, self.view.width, self.view.height);
    self.tableView.tableHeaderView = self.tableHeaderView;
}

- (void)setupUI
{
    [self.view addSubview:self.tableView];
    [self.tableHeaderView addSubview:self.searchController.searchBar];
    [self.contactNumView addSubview:self.contactNumLabel];
    self.tableView.tableHeaderView = self.tableHeaderView;
    self.tableView.tableFooterView = self.contactNumView;
}

#pragma mark ====================== lazy load =======================

- (UITableView *)tableView
{
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        tableView.separatorInset = UIEdgeInsetsMake(0, 10, 0, 20);
        if (@available(iOS 13.0, *)) tableView.separatorColor = [UIColor systemGray4Color];
        else tableView.separatorColor = [UIColor lightGrayColor];
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.rowHeight = 60.f;
        tableView.sectionHeaderHeight = 30.0f;
        tableView.sectionFooterHeight = 0.0f;
        tableView.multipleTouchEnabled = NO;
        [tableView setSectionIndexColor:[UIColor darkGrayColor]];
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

- (UISearchController *)searchController
{
    if (!_searchController) {
        _searchController = [[UISearchController alloc] initWithSearchResultsController:self.resultController];
        _searchController.searchResultsUpdater = self.resultController;
        _searchController.delegate = self;
        _searchController.dimsBackgroundDuringPresentation = YES;
        _searchController.view.backgroundColor = RGBA(220, 220, 220, 0.5);

        UISearchBar *searchBar = _searchController.searchBar;
        searchBar.barStyle = UIBarStyleDefault;
        searchBar.translucent = YES;
        searchBar.delegate = self;
        searchBar.barTintColor = [UIColor groupTableViewColor];
        searchBar.backgroundImage = nil;
        searchBar.tintColor = AppTinColor;
        UIImage *image = [UIImage xo_imageNamedFromChatBundle:@"search_background"];
        [searchBar setBackgroundImage:[image XO_imageWithTintColor:BG_TableColor]];
    }
    return _searchController;
}

- (XOSearchResultListController *)resultController
{
    if (!_resultController) {
        _resultController = [[XOSearchResultListController alloc] init];
        _resultController.delegate = self;
        _resultController.searchType = XOSearchTypeContact;
    }
    return _resultController;
}

#pragma mark ====================== 获取通讯录 =======================

- (void)loadLocalContacts
{
    [[XOChatClient shareClient].contactManager getAllContactsList:^(NSArray<TIMFriend *> * _Nullable friendList) {
        
        // 按照首字母排序
        BMChineseSortSetting.share.sortMode = 1; // 1或2
        [BMChineseSort sortAndGroup:friendList key:@"profile.nickname" finish:^(bool isSuccess, NSMutableArray *unGroupedArr, NSMutableArray *sectionTitleArr, NSMutableArray<NSMutableArray <TIMFriend *> *> *sortedObjArr) {
            if (isSuccess) {
                self.firstLetterArray = sectionTitleArr;
                self.sortedModelArr = sortedObjArr;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView reloadData];
                }];
            }
        }];
        self.contactNumLabel.text = [NSString stringWithFormat:@"%lu%@", (unsigned long)friendList.count, XOChatLocalizedString(@"contact.groupNum")];
    }];
}

#pragma mark ====================== 删除好友 =======================

- (void)deleteFriend:(TIMFriend *)contact indexPath:(NSIndexPath *)indexPath
{
    if (XOIsEmptyString(contact.identifier)) return;
    
    [[TIMFriendshipManager sharedInstance] deleteFriends:@[contact.identifier] delType:TIM_FRIEND_DEL_SINGLE succ:^(NSArray<TIMFriendResult *> *results) {
        
        if (results.count > 0) {
            TIMFriendResult *result = results[0];
            if (ERR_SUCC == result.result_code) {
                NSLog(@"删除好友成功  nickname:%@", contact.profile.nickname);
                
                [[XOContactManager defaultManager] deleteContact:contact.identifier handler:^(BOOL result) {
                    if (result) {
                        [self loadLocalContacts];
                    }
                    else {
                        if (result) NSLog(@"删除数据库好友成功 nickname: %@", contact.profile.nickname);
                        NSLog(@"删除数据库好友失败 nickname: %@", contact.profile.nickname);
                    }
                }];
            }
            else {
                NSLog(@"删除好友成功  nickname:%@", contact.profile.nickname);
            }
        }
        
    } fail:^(int code, NSString *msg) {
        NSLog(@"删除好友失败  nickname:%@ code: %d  msg: %@", contact.profile.nickname, code, msg);
    }];
}

#pragma mark ====================== 备注好友 =======================

- (void)updateContactRemark:(TIMFriend *)contact remark:(NSString *)remark indexPath:(NSIndexPath *)indexPath
{
    if (XOIsEmptyString(remark) || XOIsEmptyString(contact.identifier)) return;
    else if (remark.length > 15) {
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"contact.remark.warning", nil)];
        [SVProgressHUD dismissWithDelay:1.3f];
        return;
    }

    [[TIMFriendshipManager sharedInstance] modifyFriend:contact.identifier values:@{TIMFriendTypeKey_Remark: remark} succ:^{
        
        TIMFriend *newContact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
        newContact.remark = remark;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        
        // 更新数据库
        [[XOContactManager defaultManager] updateContact:newContact handler:^(BOOL result) {
            if (result) NSLog(@"更新数据库备注成功 nickname: %@  remark: %@", newContact.profile.nickname, remark);
            else NSLog(@"更新数据库备注失败 nickname: %@  remark: %@", newContact.profile.nickname, remark);
        }];
        
    } fail:^(int code, NSString *msg) {
        NSLog(@"修改备注名失败 code: %d  msg: %@", code, msg);
    }];
}

#pragma mark ====================== UITableViewDataSource =======================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.firstLetterArray.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (0 == section) {
        return 1;
    }
    return [self.sortedModelArr[section - 1] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TableViewCell forIndexPath:indexPath];
        cell.textLabel.text = XOChatLocalizedString(@"contact.group");
        cell.textLabel.font = XOSystemFont(15.0f);
        cell.textLabel.textColor = [UIColor XOTextColor];
        return cell;
    }
    else {
        XOContactListCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactCellID forIndexPath:indexPath];
        TIMFriend *contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
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
    self.searchController.active = NO;
    [self.searchController.searchBar resignFirstResponder];
    
//    WXContactDetailViewController * otherDetail = [[WXContactDetailViewController alloc] init];
//    otherDetail.kUser = [self.fetchedResultController objectAtIndexPath:indexPath];
//    [self.navigationController pushViewController:otherDetail animated:YES];
    if (0 == indexPath.section) {
        XOGroupListViewController *groupListVC = [[XOGroupListViewController alloc] init];
        [self.navigationController pushViewController:groupListVC animated:YES];
    }
    else {
        XOChatViewController *chatVC = [[XOChatViewController alloc] init];
        TIMFriend *contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
        chatVC.chatType = TIM_C2C;
        chatVC.conversation = [[TIMManager sharedInstance] getConversation:TIM_C2C receiver:contact.identifier];
        [self.navigationController pushViewController:chatVC animated:YES];
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
        TIMFriend *contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
        if ([contact.identifier isEqualToString:[XOKeyChainTool getUserName]]) { // 不能删除自己
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
    UITableViewRowAction *deleteRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:XOChatLocalizedString(@"contact.delete.title") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        @XOStrongify(self);
        NSString *message = XOChatLocalizedString(@"contact.delete.alertMsg");
        [self showSheetWithTitle:nil message:message actions:@[XOChatLocalizedString(@"sure")] redIndex:nil complection:^(int index, NSString * _Nullable title) {
            if (0 == indexPath.section) {
                TIMFriend *contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
                [self deleteFriend:contact indexPath:indexPath];
            }
        } cancelComplection:nil];
    }];
    UITableViewRowAction *editRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:XOChatLocalizedString(@"contact.remark.title") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        TIMFriend *contact = self.sortedModelArr[indexPath.section - 1][indexPath.row];
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:XOChatLocalizedString(@"contact.remark.title") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.delegate = self;
            if (XOIsEmptyString(contact.remark)) {
                textField.placeholder = XOChatLocalizedString(@"contact.remark.placeholder");
            } else {
                textField.placeholder = contact.remark;
            }
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:XOChatLocalizedString(@"chat.cancel") style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *sure = [UIAlertAction actionWithTitle:XOChatLocalizedString(@"chat.sure") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
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

#pragma mark ====================== UISearchBarDelegate =======================

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.tabBarController.tabBar setHidden:YES];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.tabBarController.tabBar setHidden:NO];
}

#pragma mark ====================== WXSearchResultDelegate =======================

- (void)XOSearchList:(XOSearchResultListController *)search didSelectContact:(id)object
{
    if ([object isKindOfClass:[TIMFriend class]]) {
//        XOContactDetailViewController * otherDetail = [[XOContactDetailViewController alloc] init];
//        otherDetail.kUser = (TIMFriend *)object;
//        [self.navigationController pushViewController:otherDetail animated:YES];
    }
}

- (void)WXSearchListDidScrollTable:(XOSearchResultListController *)search
{
    [self.searchController.searchBar resignFirstResponder];
    [self.searchController resignFirstResponder];
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

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
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
    [self.contentView addSubview:_iconImageView];
    
    CGRect bounds = CGRectMake(0, 0, 44, 44);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:bounds.size];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    _iconImageView.layer.mask = maskLayer;
    
    _nameLabel = [UILabel new];
    _nameLabel.textColor = [UIColor XOBlackColor];
    [self.contentView addSubview:_nameLabel];
}

// 通用设置发生改变
- (void)refreshGenralSetting
{
    _nameLabel.font = [UIFont systemFontOfSize:[[XOSettingManager defaultManager] fontSize]];
}

- (void)setContact:(TIMFriend *)contact
{
    _contact = contact;
    if (contact) {
        NSString *name = contact.profile.nickname;
        if (!XOIsEmptyString(contact.remark)) name = [NSString stringWithFormat:@"%@ (%@)", name, contact.remark];

        _nameLabel.text = name;
        [_iconImageView sd_setImageWithURL:[NSURL URLWithString:contact.profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
    }
    else {
        _nameLabel.text = @"";
        _iconImageView.image = [UIImage xo_imageNamedFromChatBundle:@"default_avatar"];
    }
}

- (void)setGroup:(TIMGroupInfo *)group
{
    _group = group;
    if (group) {
        
        _nameLabel.text = !XOIsEmptyString(group.groupName) ? group.groupName : @"";
        if (!XOIsEmptyString(group.faceURL)) {
            @XOWeakify(self);
            [_iconImageView sd_setImageWithURL:[NSURL URLWithString:group.faceURL] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                @XOStrongify(self);
                if (image) {
                    [UIImage combineGroupImageWithGroupId:group.group complection:^(UIImage * _Nonnull image) {
                        self->_iconImageView.image = image;
                    }];
                }
                else {
                    self->_iconImageView.image = [UIImage groupDefaultImageAvatar];
                }
            }];
        } else {
            _iconImageView.image = [UIImage groupDefaultImageAvatar];
        }
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
