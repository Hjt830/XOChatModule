//
//  XOContactListViewController.m
//  XOChatModule
//
//  Created by kenter on 2019/10/11.
//

#import "XOContactListViewController.h"
#import "XOSearchResultListController.h"
#import "XOChatViewController.h"

#import "XOChatClient.h"
#import "CommonTool.h"
#import "UIImage+XOChatBundle.h"
#import "NSBundle+ChatModule.h"
#import <XOBaseLib/XOBaseLib.h>

static NSString *ContactCellID = @"ContactCellID";

@interface XOContactListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate>

@property (nonatomic, strong) NSMutableArray       <TIMFriend *>*contactList;       // 联系人列表
@property (nonatomic, strong) NSMutableArray    <TIMGroupInfo *>*groupList;         // 群列表
@property (nonatomic, strong) NSArray                           *menuArray;         // 菜单
@property (nonatomic, strong) UITableView                       *tableView;         // 通讯录列表
@property (nonatomic, strong) UIView                            *tableHeaderView;   // 通讯录列表头部试图
@property (nonatomic, strong) UIView                            *contactNumView;
@property (nonatomic, strong) UILabel                           *contactNumLabel;   // 通讯录人数
@property (nonatomic, strong) UISearchController                *searchController;
@property (nonatomic, strong) XOSearchResultListController      *resultController;
@property (nonatomic, copy) NSString                            *remark;   // 备注名

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
    
    [self initialization];
    
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

- (void)initialization
{
    self.title = XOChatLocalizedString(@"contact.addressbook");
    self.menuArray = @[XOChatLocalizedString(@"contact.friend"), XOChatLocalizedString(@"contact.group")];
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
        tableView.separatorColor = RGBA(230, 230, 230, 1);
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.rowHeight = 60.f;
        tableView.sectionHeaderHeight = 30.0f;
        tableView.sectionFooterHeight = 0.0f;
        tableView.multipleTouchEnabled = NO;
        [tableView setSectionIndexColor:[UIColor darkGrayColor]];
        [tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
        _tableView = tableView;
        
        [tableView registerClass:[XOContactListCell class] forCellReuseIdentifier:ContactCellID];
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
        searchBar.barTintColor = [UIColor groupTableViewBackgroundColor];
        searchBar.backgroundImage = nil;
        searchBar.tintColor = AppTinColor;
        UIImage *image = [CommonTool imageWithColor:[UIColor groupTableViewBackgroundColor] size:searchBar.size];
        [searchBar setBackgroundImage:image];
    }
    return _searchController;
}

- (XOSearchResultListController *)resultController
{
    if (!_resultController) {
        _resultController = [[XOSearchResultListController alloc] init];
//        _resultController.delegate = self;
//        _resultController.searchType = XOSearchTypeContact;
    }
    return _resultController;
}

- (NSMutableArray<TIMFriend *> *)contactList
{
    if (!_contactList) {
        _contactList = [NSMutableArray arrayWithCapacity:0];
    }
    return _contactList;
}

- (NSMutableArray<TIMGroupInfo *> *)groupList
{
    if (!_groupList) {
        _groupList = [NSMutableArray arrayWithCapacity:0];
    }
    return _groupList;
}

#pragma mark ====================== 获取通讯录 =======================

- (void)loadLocalContacts
{
    [[XOChatClient shareClient].contactManager getAllContactsList:^(NSArray<TIMFriend *> * _Nullable friendList) {
        
        @synchronized (self) {
            [self.contactList removeAllObjects];
            [self.contactList addObjectsFromArray:friendList];
        }
        [self.tableView reloadData];
        
        self.contactNumLabel.text = [NSString stringWithFormat:@"%lu%@  %lu%@", friendList.count, XOChatLocalizedString(@"contact.contactNum"), self.groupList.count, XOChatLocalizedString(@"contact.groupNum")];
    }];
    
    [[XOChatClient shareClient].contactManager getAllGroupsList:^(NSArray<TIMGroupInfo *> * _Nullable groupList) {
        
        @synchronized (self) {
            [self.groupList removeAllObjects];
            [self.groupList addObjectsFromArray:groupList];
        }
        [self.tableView reloadData];
        
        self.contactNumLabel.text = [NSString stringWithFormat:@"%lu%@  %lu%@", self.contactList.count, XOChatLocalizedString(@"contact.contactNum"), self.groupList.count, XOChatLocalizedString(@"contact.groupNum")];
    }];
}

#pragma mark ====================== 删除好友 =======================

- (void)deleteFriend:(TIMFriend *)contact
{
//    NSMutableDictionary *loginDic = [[NSMutableDictionary alloc] init];
//    loginDic[@"userId"] = contact.userId;
//
//    [SVProgressHUD show];
//    [[WXHttpTools shareTool] POST:API_RemoveFriend parameters:loginDic success:^(NSDictionary * _Nullable responseDictionary, NSData * _Nullable data) {
//        [SVProgressHUD dismiss];
//
//        NSInteger code = [responseDictionary[@"code"] integerValue];
//        if (1 == code) {
//            // 发送消息, 让对方也删掉自己
//            [self sendDeleteCmdMessage:contact.userId];
//            // 删除数据库好友数据
//            [[WXContactCoreDataStorage getInstance] deleteContact:contact.userId result:^(BOOL finish) {
//                if (finish) NSLog(@"删除好友 %@ 成功", contact.nick);
//                else NSLog(@"删除好友 %@ 失败", contact.nick);
//            }];
//            // 同时删掉与该好友的聊天记录
////            [WXMsgCoreDataManager shareManager]
//        }
//        else {
//            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"deleteFriend.failed", @"Delete friend failed")];
//        }
//        [SVProgressHUD dismissWithDelay:1.3f];
//
//    } fail:^(NSError * _Nullable error) {
//
//        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"deleteFriend.failed", @"Delete friend failed")];
//        [SVProgressHUD dismissWithDelay:1.3f];
//    }];
}

// 发送删除好友的透传消息
- (void)sendDeleteCmdMessage:(NSString *)userId
{
//    WXContact *myUser = [[WXContactCoreDataStorage getInstance] getCurrentUser];
//    NSMutableDictionary * userInfoDic = @{}.mutableCopy;
//    if (!WXIsEmptyString(myUser.userId))    [userInfoDic setObject:myUser.userId forKey:@"userId"];
//    if (!WXIsEmptyString(myUser.nick))      [userInfoDic setObject:myUser.nick   forKey:@"nick"];
//    if (!WXIsEmptyString(myUser.avatar))    [userInfoDic setObject:myUser.avatar forKey:@"avatar"];
//    if (!WXIsEmptyString(myUser.myTeam))    [userInfoDic setObject:myUser.myTeam forKey:@"teamId"];
//    if (!WXIsEmptyString(myUser.role))      [userInfoDic setObject:myUser.role   forKey:@"role"];
//    NSDictionary * bodyDic = @{@"action":@"1003",@"data":userInfoDic};
//    HTCmdMessage * cmdMessage = [WXMsgCreatTool createSendCmdMessage:userId body:bodyDic chatType:HTChatTypeSingle];
//    [[HTClient sharedInstance] sendCMDMessage:cmdMessage commondType:HTCommondTypeContact completion:nil];
}

#pragma mark ====================== 备注好友 =======================

- (void)updateContactRemark:(TIMFriend *)contact remark:(NSString *)remark
{
//    if (WXIsEmptyString(remark)) remark = @"";
//    if (remark.length > 10) {
//        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"contact.remark.warning", nil)];
//        [SVProgressHUD dismissWithDelay:1.3f];
//        return;
//    }
//
//    [SVProgressHUD show];
//    NSDictionary *parameters = @{@"friend_uid" : contact.userId, @"remark": remark};
//    [[WXHttpTools shareTool] POST:API_RemarkFriend parameters:parameters success:^(NSDictionary * _Nullable responseDictionary, NSData * _Nullable data) {
//        [SVProgressHUD dismiss];
//
//        NSInteger code = [responseDictionary[@"code"] integerValue];
//        if (1 == code) {
//            [SVProgressHUD showSuccessWithStatus:@"修改成功"];
//            // 本地更新备注名
//            [[WXContactCoreDataStorage getInstance] updateContact:contact.userId remark:remark result:^(BOOL finish, NSManagedObject * _Nonnull newContact) {
//                self.remark = nil;
//            }];
//        }
//        else {
//            NSString *message = responseDictionary[@"message"];
//            if (WXIsEmptyString(message)) {
//                [SVProgressHUD showErrorWithStatus:@"修改失败"];
//            } else {
//                [SVProgressHUD showErrorWithStatus:message];
//            }
//        }
//        [SVProgressHUD dismissWithDelay:1.3f];
//
//    } fail:^(NSError * _Nullable error) {
//        [SVProgressHUD showErrorWithStatus:@"修改失败"];
//        [SVProgressHUD dismissWithDelay:1.3f];
//    }];
}

#pragma mark ====================== UITableViewDataSource =======================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (0 == section) return self.contactList.count;
    return self.groupList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView) {
        XOContactListCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactCellID forIndexPath:indexPath];
        if (indexPath.row < self.contactList.count) {
            TIMFriend *contact = [self.contactList objectAtIndex:indexPath.row];
            cell.contact = contact;
        }
        [cell refreshGenralSetting];
        return cell;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.menuArray[section];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    __block NSMutableArray <NSString *> *indexTitles = @[].mutableCopy;
    [self.contactList enumerateObjectsUsingBlock:^(TIMFriend * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!XOIsEmptyString(obj.remark)) {
            [indexTitles addObject:obj.remark];
        } else if (!XOIsEmptyString(obj.profile.nickname)) {
            [indexTitles addObject:obj.profile.nickname];
        } else {
            [indexTitles addObject:@"#"];
        }
    }];
    return indexTitles;
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
}

//实现cell的左滑效果
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) {
        TIMFriend *contact = [self.contactList objectAtIndex:indexPath.row];
        if ([contact.identifier isEqualToString:[XOKeyChainTool getUserName]]) { // 不能删除自己
            return NO;
        }
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    editingStyle = UITableViewCellEditingStyleDelete;
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
                TIMFriend * contact = [self.contactList objectAtIndex:indexPath.row];
                [self deleteFriend:contact];
            }
        } cancelComplection:nil];
    }];
    UITableViewRowAction *editRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:XOChatLocalizedString(@"contact.remark.title") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        TIMFriend *contact = [self.contactList objectAtIndex:indexPath.row];
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:XOChatLocalizedString(@"contact.remark.title") message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            
            if (XOIsEmptyString(contact.remark)) {
                textField.placeholder = XOChatLocalizedString(@"contact.remark.placeholder");
            } else {
                textField.placeholder = contact.remark;
            }
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:textField];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:XOChatLocalizedString(@"chat.cancel") style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *sure = [UIAlertAction actionWithTitle:XOChatLocalizedString(@"chat.sure") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
//            [self updateContactRemark:contact remark:self.remark];
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
    if (self.tableView == tableView) {
        [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        return self.contactList.count;
    }
    return 0;
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
    else if ([object isKindOfClass:[TIMGroupInfo class]]) {
//        TIMGroupInfo *group = (TIMGroupInfo *)object;
//        XOChatViewController *chatVC = [[XOChatViewController alloc] init];
//        chatVC.chatType = HTChatTypeGroup;
//        chatVC.chatterId = group.groupId;
//        [self.navigationController pushViewController:chatVC animated:YES];
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
    self.contactNumLabel.text = [NSString stringWithFormat:@"%lu%@  %lu%@", self.contactList.count, XOChatLocalizedString(@"contact.contactNum"), self.groupList.count, XOChatLocalizedString(@"contact.groupNum")];
}

#pragma mark ====================== noti =======================

- (void)textFieldDidChange:(NSNotification *)noti
{
    UITextField *textField = (UITextField *)noti.object;
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
    
    _nameLabel = [UILabel new];
    _nameLabel.textColor = [UIColor blackColor];
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
        NSString *name = nil;
        if (!XOIsEmptyString(contact.remark)) name = contact.remark;
        else if (!XOIsEmptyString(contact.profile.nickname)) name = contact.profile.nickname;

        _nameLabel.text = name;
        [_iconImageView sd_setImageWithURL:[NSURL URLWithString:contact.profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
    }
    else {
        _nameLabel.text = @"";
        _iconImageView.image = [UIImage xo_imageNamedFromChatBundle:@"default_avatar"];
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
