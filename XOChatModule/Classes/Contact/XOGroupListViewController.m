//
//  XOGroupListViewController.m
//  AFNetworking
//
//  Created by kenter on 2019/11/19.
//

#import "XOGroupListViewController.h"
#import "XOContactListViewController.h"
#import "XOSearchResultListController.h"
#import "XOChatViewController.h"

#import "XOChatClient.h"
#import "BMChineseSort.h"
#import "UIImage+XOChatBundle.h"
#import "UIImage+XOChatExtension.h"
#import "NSBundle+ChatModule.h"
#import "UIColor+XOExtension.h"

static NSString *ContactCellID = @"ContactCellID";


@interface XOGroupListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, XOSearchResultDelegate>

@property (nonatomic, strong)NSMutableArray <NSString *> * firstLetterArray;  //排序后的出现过的拼音首字母数组
@property (nonatomic, strong)NSMutableArray <NSMutableArray <TIMGroupInfo *> *> *sortedModelArr; //排序好的结果数组


@property (nonatomic, strong) UISearchController                *searchController;
@property (nonatomic, strong) XOSearchResultListController      *resultController;
@property (nonatomic, strong) UITableView                       *tableView;         // 通讯录列表
@property (nonatomic, strong) UIView                            *tableHeaderView;   // 通讯录列表头部试图
@property (nonatomic, strong) UIView                            *contactNumView;
@property (nonatomic, strong) UILabel                           *contactNumLabel;   // 通讯录人数

@end

@implementation XOGroupListViewController


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadLocalContacts];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = XOChatLocalizedString(@"contact.group");
    
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
    [[XOChatClient shareClient].contactManager getAllGroupsList:^(NSArray<TIMGroupInfo *> * _Nullable groupList) {
        
        // 按照首字母排序
        BMChineseSortSetting.share.sortMode = 1; // 1或2
        [BMChineseSort sortAndGroup:groupList key:@"groupName" finish:^(bool isSuccess, NSMutableArray *unGroupedArr, NSMutableArray *sectionTitleArr, NSMutableArray<NSMutableArray <TIMGroupInfo *> *> *sortedObjArr) {
            if (isSuccess) {
                self.firstLetterArray = sectionTitleArr;
                self.sortedModelArr = sortedObjArr;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView reloadData];
                }];
            }
        }];
        self.contactNumLabel.text = [NSString stringWithFormat:@"%lu%@", (unsigned long)groupList.count, XOChatLocalizedString(@"contact.contactNum")];
    }];
}

#pragma mark ====================== UITableViewDataSource =======================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.firstLetterArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sortedModelArr[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XOContactListCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactCellID forIndexPath:indexPath];
    TIMGroupInfo *groupInfo = self.sortedModelArr[indexPath.section][indexPath.row];
    cell.group = groupInfo;
    [cell refreshGenralSetting];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.firstLetterArray[section];
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
    
    XOChatViewController *chatVC = [[XOChatViewController alloc] init];
    TIMGroupInfo *groupInfo = self.sortedModelArr[indexPath.section][indexPath.row];
    chatVC.chatType = TIM_GROUP;
    chatVC.conversation = [[TIMManager sharedInstance] getConversation:TIM_GROUP receiver:groupInfo.group];
    [self.navigationController pushViewController:chatVC animated:YES];
}

//实现cell的左滑效果
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

// 点击索引
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
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
    if ([object isKindOfClass:[TIMGroupInfo class]]) {
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
}

@end
