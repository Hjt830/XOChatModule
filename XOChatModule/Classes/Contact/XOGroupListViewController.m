//
//  XOGroupListViewController.m
//  AFNetworking
//
//  Created by kenter on 2019/11/19.
//

#import "XOGroupListViewController.h"
#import "LCContactListViewController.h"
#import "XOSearchResultListController.h"
#import "XOChatViewController.h"

static NSString *ContactCellID = @"ContactCellID";


@interface XOGroupListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong)NSMutableArray  <EMGroup *> * dataSource; //排序好的结果数组

@property (nonatomic, strong) UISearchBar                       *searchBar;
@property (nonatomic, strong) UITableView                       *tableView;         // 通讯录列表
@property (nonatomic, strong) UIView                            *headerView;        // 通讯录列表头部试图
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
    self.title = @"群聊";
    
    [self setupUI];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.headerView.frame = CGRectMake(0, 0, self.view.width, 50);
    self.searchBar.frame = CGRectMake(20, 9, self.view.width - 40, 32);
    self.tableView.frame = CGRectMake(15, 66, self.view.width - 30, self.view.height - 32);
}

- (void)setupUI
{
    [self.headerView addSubview:self.searchBar];
    [self.view addSubview:self.headerView];
    
    [self.view addSubview:self.tableView];
    [self.contactNumView addSubview:self.contactNumLabel];
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

- (UIView *)headerView
{
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectZero];
        _headerView.backgroundColor = [UIColor XOWhiteColor];
    }
    return _headerView;
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
    [[EMClient sharedClient].groupManager getJoinedGroupsFromServerWithPage:0 pageSize:-1 completion:^(NSArray *aList, EMError *aError) {
        if (aError) {
            NSLog(@"获取群组失败");
        }
        else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                @synchronized (self) {
                    [self.dataSource removeAllObjects];
                    [self.dataSource addObjectsFromArray:aList];
                }
                [self.tableView reloadData];
                self.contactNumLabel.text = [NSString stringWithFormat:@"%lu 个群组", (unsigned long)aList.count];
            }];
        }
    }];
}

#pragma mark ====================== UITableViewDataSource =======================

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XOContactListCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactCellID forIndexPath:indexPath];
    EMGroup *groupInfo = self.dataSource[indexPath.row];
    cell.group = groupInfo;
    [cell refreshGenralSetting];
    return cell;
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

#pragma mark ====================== UITableViewDelegate =======================

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    EMGroup *groupInfo = self.dataSource[indexPath.row];
    EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:groupInfo.groupId type:EMConversationTypeGroupChat createIfNotExist:YES];
    XOChatViewController *chatVC = [[XOChatViewController alloc] init];
    chatVC.chatType = EMChatTypeGroupChat;
    chatVC.conversation = conversation;
    [self.navigationController pushViewController:chatVC animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
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
#pragma mark ====================== 字体改变 =======================

- (void)refreshByGenralSettingChange:(XOGenralChangeType)genralType userInfo:(NSDictionary *_Nonnull)userInfo;
{
    [self.tableView reloadData];
    _contactNumLabel.font = [UIFont systemFontOfSize:[[XOSettingManager defaultManager] fontSize]];
}

- (NSMutableArray<EMGroup *> *)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

@end
