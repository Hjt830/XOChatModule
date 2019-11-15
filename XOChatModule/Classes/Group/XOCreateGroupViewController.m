//
//  XOCreateGroupViewController.m
//  xxoogo
//
//  Created by 鼎一  on 2019/5/22.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "XOCreateGroupViewController.h"
#import "MemberTableViewCell.h"
#import "BMChineseSort.h"
#import "UIImage+XOChatBundle.h"
//#import "NewPersonInfoViewController.h"
//#import "GroupSelectMemberViewController.h"

static int const MaxGroupMemberCount = 500;

static NSString * const MemberTableViewCellID = @"MemberTableViewCellID";
static NSString * const GroupMemberIconCellID = @"GroupMemberIconCellID";

@interface XOCreateGroupViewController () <UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
{
    NSInteger page;
}

@property (nonatomic, strong) UIView            *headView;
@property (nonatomic, strong) UIScrollView      *scrollView;
@property (nonatomic, strong) UISearchBar       *searchbar;
@property (nonatomic, strong) UIButton          *sureBtn;
@property (nonatomic, strong) UIBarButtonItem   *okBBI;
@property (nonatomic, strong) UITableView       *tableView;
@property (nonatomic, strong) UICollectionView  *collectionView;

//排序后的出现过的拼音首字母数组
@property(nonatomic,strong)NSMutableArray <NSString *> * firstLetterArray;
//排序好的结果数组
@property(nonatomic,strong)NSMutableArray <NSMutableArray <TIMFriend *> *> *sortedModelArr;

@property (nonatomic, strong) NSMutableArray    *groupData;         //排序后数据源
@property (nonatomic, strong) NSMutableArray    *groupChatData;     //排序后表头数据源
@property (nonatomic, strong) NSMutableArray    *addData;           //添加成员数据源
@property (nonatomic, strong) NSMutableArray    *selectData;        //用于存储选中的cell上信息，便于刷新cell保存选择状态

@property (nonatomic, strong) NSMutableArray <TIMFriend *>* dataSource; // 存储获取的所有数据

@end

@implementation XOCreateGroupViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _memberType = GroupMemberType_Create;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title =  XOChatLocalizedString(@"group.create");
    
    [self setupSubView];
    
    [self initiliazation];
    
    [self.view setNeedsLayout];
    
    if (GroupMemberType_Remove == self.memberType) {
        [self sortRemoveListWithArray:self.groupMembers];   // 移出群成员时排序
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.addData.count > 0) {
        self.collectionView.frame = CGRectMake(10, 10, self.view.width - 20, 60);
        self.headView.frame = CGRectMake(0, 0, self.view.width, 10 + 60 + 56);
        NSString *title = [NSString stringWithFormat:@"%@(%ld)", XOLocalizedString(@"sure"), (long)self.addData.count];
        [self.sureBtn setTitle:title forState:UIControlStateNormal];
    } else {
        self.collectionView.frame = CGRectZero;
        self.headView.frame = CGRectMake(0, 0, self.view.width, 56);
        [self.sureBtn setTitle:XOLocalizedString(@"sure") forState:UIControlStateNormal];
    }
    self.searchbar.frame = CGRectMake(10, self.collectionView.bottom + 10, self.view.width - 20, 36);
    self.tableView.frame = CGRectMake(0, self.headView.bottom, self.view.width, self.view.height - self.headView.height);
}

- (void)setupSubView
{
    [self. self.headView addSubview:self.collectionView];
    [self. self.headView addSubview:self.searchbar];
    [self.view addSubview:self. self.headView];
    [self.view addSubview:self.tableView];
    self.navigationItem.rightBarButtonItem = self.okBBI;
}

- (void)initiliazation
{
    if (GroupMemberType_Create == self.memberType) {
        [[XOChatClient shareClient].contactManager getAllContactsList:^(NSArray<TIMFriend *> * _Nullable friendList) {
            // 去掉客服
            NSMutableArray *mutFriendList = [friendList mutableCopy];
            [mutFriendList enumerateObjectsUsingBlock:^(TIMFriend * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.identifier isEqualToString:@"user0"]) {
                    [mutFriendList removeObject:obj];
                }
            }];
            
            //选择拼音 转换的 方法
            BMChineseSortSetting.share.sortMode = 2; // 1或2
            //排序 Person对象
            [BMChineseSort sortAndGroup:mutFriendList key:@"profile.nickname" finish:^(bool isSuccess, NSMutableArray *unGroupedArr, NSMutableArray *sectionTitleArr, NSMutableArray<NSMutableArray <TIMFriend *> *> *sortedObjArr) {
                if (isSuccess) {
                    self.firstLetterArray = sectionTitleArr;
                    self.sortedModelArr = sortedObjArr;
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.tableView reloadData];
                    }];
                }
            }];
            [self.tableView reloadData];
        }];
    }
    else if (GroupMemberType_Add == self.memberType) {
        @synchronized (self) {
            [self.groupData removeAllObjects];
            [self.groupData addObjectsFromArray:self.existMemberIds];
        }
        [self.tableView reloadData];
    }
    else if (GroupMemberType_Remove == self.memberType) {
        @synchronized (self) {
            [self.groupData removeAllObjects];
            [self.groupData addObjectsFromArray:self.groupMembers];
        }
        [self.tableView reloadData];
    }
}

#pragma mark ========================= touch event =========================

- (void)sureClick
{
    [self.view endEditing:YES];
    
    self.sureBtn.enabled = NO;
    if (GroupMemberType_Create == self.memberType) {
        [self createGroup];
    }
    else if (GroupMemberType_Add == self.memberType) {
        [self addGroupMember];
    }
    else if (GroupMemberType_Remove == self.memberType) {
        [self removeGroupMember];
    }
}

#pragma mark ========================= help =========================

- (void)refreshRightBBIStatus
{
    if (self.addData.count > 0) {
        self.navigationItem.rightBarButtonItem = self.okBBI;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)sortRemoveListWithArray:(NSArray <NSDictionary *>*)list
{
    if (GroupMemberType_Remove == self.memberType)
    {
        __block NSMutableArray <GroupMemberInfoModel *>*groupMemberList = [NSMutableArray array];
        [list enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            GroupMemberInfoModel *model = [[GroupMemberInfoModel alloc] init];
            [model setValuesForKeysWithDictionary:obj];
            [groupMemberList addObject:model];
        }];
        
//        NSDictionary *dic = [self sortObjectsAccordingToInitialWith:groupMemberList SortKey:@"sortKey"];
//        @synchronized (self) {
//            [self.groupData removeAllObjects];
//            [self.groupChatData removeAllObjects];
//            [self.groupData  addObjectsFromArray:dic[@"Group"]];
//            [self.groupChatData addObjectsFromArray:dic[@"GroupChar"]];
//            [self.tableView reloadData];
//        }
    }
}

#pragma mark ========================= API =========================

// 创建群
- (void)createGroup
{
    // 创建群最少要3人，也就是除自己外最少要选择2个人
    if (self.addData.count <= 1) {
        [SVProgressHUD showWithStatus:XOChatLocalizedString(@"group.friend.limitMin")];
        [SVProgressHUD dismissWithDelay:1.2f];
        self.sureBtn.enabled = YES;
        return;
    }
    
    NSMutableArray *mutArray = [NSMutableArray arrayWithArray:self.addData];
    // 删除自己
    for (TIMFriend *friend in mutArray) {
        if ([friend.identifier isEqualToString:[XOKeyChainTool getUserName]]) {
            [mutArray removeObject:friend];
            break;
        }
    }
    // 判断不为空
    if (XOIsEmptyArray(mutArray)) {
        [SVProgressHUD showWithStatus:XOChatLocalizedString(@"group.friend.empty")];
        [SVProgressHUD dismissWithDelay:1.2f];
        self.sureBtn.enabled = YES;
        return;
    }
    
    __block NSMutableArray *memberList = [[NSMutableArray alloc] init];
    [memberList addObject:[XOKeyChainTool getUserName]];
    __block NSMutableString *groupname = [[NSMutableString alloc] init];
    NSString *nickname = [[XOUserDefault standraDefault] getCustomData:@"nickname"];
    if (!XOIsEmptyString(nickname)) {
        [groupname appendString:nickname];
        [groupname appendString:@"、"];
    }
    __block NSMutableArray <TIMCreateGroupMemberInfo *>* memberInfoList = [[NSMutableArray alloc] init];
    TIMCreateGroupMemberInfo *memberInfo = [[TIMCreateGroupMemberInfo alloc] init];
    memberInfo.member = [XOKeyChainTool getUserName];
    memberInfo.role = TIM_GROUP_MEMBER_ROLE_SUPER; // 群主
    [memberInfoList addObject:memberInfo];
    
    [self.addData enumerateObjectsUsingBlock:^(TIMFriend * _Nonnull friend, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (!XOIsEmptyString(friend.identifier)) {
            [memberList addObject:friend.identifier];
        }
        if (!XOIsEmptyString(friend.profile.nickname)) {
            [groupname appendString:friend.profile.nickname];
            if (idx != (self.addData.count - 1)) {
                [groupname appendString:@"、"];
            }
        }
        
        TIMCreateGroupMemberInfo *memberInfo = [[TIMCreateGroupMemberInfo alloc] init];
        memberInfo.member = friend.identifier;
        memberInfo.role = TIM_GROUP_MEMBER_ROLE_MEMBER; // 群成员
        [memberInfoList addObject:memberInfo];
    }];
    
    TIMCreateGroupInfo *createOpt = [[TIMCreateGroupInfo alloc] init];
    createOpt.groupName = groupname.length > 25 ? [groupname substringToIndex:25] : groupname;  // 名字太长会导致建群失败
    createOpt.groupType = @"Private";
    createOpt.setAddOpt = false;
    createOpt.addOpt = TIM_GROUP_ADD_ANY;
    createOpt.maxMemberNum = MaxGroupMemberCount;
    createOpt.membersInfo = memberInfoList;
    
    [SVProgressHUD show];
    [[TIMGroupManager sharedInstance] createGroup:createOpt succ:^(NSString *groupId) {
        
        [SVProgressHUD dismiss];
        // 按钮可以点击
        self.sureBtn.enabled = NO;
        
        __block TIMGroupInfo *groupInfo = [[TIMGroupManager sharedInstance] queryGroupInfo:groupId];
        if (groupInfo) {
            [[XOChatClient shareClient].contactManager insertGroup:groupInfo handler:^(BOOL result) {
                if (result) NSLog(@"创建的新群组插入通讯录成功");
                else NSLog(@"创建的新群组插入通讯录失败");
            }];
        }
        else {
            [[TIMGroupManager sharedInstance] getGroupInfo:@[groupId] succ:^(NSArray<TIMGroupInfo *> *arr) {
                
                if (!XOIsEmptyArray(arr)) {
                    [[XOChatClient shareClient].contactManager insertGroup:arr[0] handler:^(BOOL result) {
                        if (result) NSLog(@"创建的新群组插入通讯录成功");
                        else NSLog(@"创建的新群组插入通讯录失败");
                    }];
                }
            } fail:^(int code, NSString *msg) {
                NSLog(@"code: %d  msg: %@", code, msg);
            }];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.sureBtn.enabled = YES;
            XOChatViewController *chatVC = [[XOChatViewController alloc] init];
            chatVC.chatType = TIM_GROUP;
            chatVC.conversation = [[TIMManager sharedInstance] getConversation:TIM_GROUP receiver:groupId];
            [self.navigationController pushViewController:chatVC animated:YES];
        }];
        
        __block BOOL contain = NO;
        __block UIViewController *viewController = nil;
        [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[self class]]) {
                contain = YES;
                viewController = obj;
                *stop = YES;
            }
        }];
        if (contain) {
            __block UINavigationController *nav = self.navigationController;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSMutableArray <UIViewController *> *viewControllers = [self.navigationController.viewControllers mutableCopy];
                [viewControllers removeObject:viewController];
                nav.viewControllers = viewControllers;
            });
        }
    } fail:^(int code, NSString *msg) {
        [SVProgressHUD dismiss];
        
        self.sureBtn.enabled = NO;
    }];
}

// 添加群成员
- (void)addGroupMember
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(addGroupMember:selectMember:)]) {
        
        __block NSMutableArray <NSDictionary *>* mutArr = [NSMutableArray array];
        [self.addData enumerateObjectsUsingBlock:^(TIMFriend  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSMutableDictionary *mutdict = [NSMutableDictionary dictionary];
            if (!XOIsEmptyString(obj.identifier)) {
                [mutdict setValue:obj.identifier forKey:@"memId"];
            }
            if (!XOIsEmptyString(obj.profile.nickname)) {
                [mutdict setValue:obj.profile.nickname forKey:@"name"];
            }
            [mutArr addObject:mutdict];
        }];
        [self.delegate addGroupMember:self selectMember:mutArr];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

// 踢出群成员
- (void)removeGroupMember
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(removeGroupMember:selectMember:)]) {
        
        __block NSMutableArray <NSDictionary *>* mutArr = [NSMutableArray array];
        [self.addData enumerateObjectsUsingBlock:^(GroupMemberInfoModel  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            NSDictionary *dict = [obj yy_modelToJSONObject];
//            [mutArr addObject:dict];
        }];
        [self.delegate removeGroupMember:self selectMember:mutArr];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark ========================= UITableViewDataSource & UITableViewDelegate =========================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.firstLetterArray count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sortedModelArr[section] count];
}
//section的titleHeader
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.firstLetterArray objectAtIndex:section];
}
//section右侧index数组
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.firstLetterArray;
}
//点击右侧索引表项时调用 索引与section的对应关系
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    return index;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MemberTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MemberTableViewCellID forIndexPath:indexPath];
    
    // 创建群 | 添加群成员
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType)
    {
        TIMFriend *friend = self.sortedModelArr[indexPath.section][indexPath.row];
        BOOL contain = NO;
        for ( TIMFriend *user  in self.addData) {
            if ([user.identifier isEqualToString:friend.identifier]) {
                contain = YES;
                break;
            }
        }
        if (contain) {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        cell.friendInfo = friend;
    }
    // 踢出群成员
    else if (GroupMemberType_Remove == self.memberType)
    {
        TIMGroupInfo *groupInfo = self.groupData[indexPath.section][indexPath.row];
        BOOL contain = NO;
        for (TIMGroupInfo *info in self.addData) {
            NSString *dictMemId = groupInfo.group;
            NSString *memId = info.group;
            if (!XOIsEmptyString(memId) && !XOIsEmptyString(dictMemId) && [memId isEqualToString:dictMemId]) {
                contain = YES;
                break;
            }
        }
        if (contain) {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        cell.groupInfo = groupInfo;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 创建群 | 添加群成员
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType)
    {
        if (MaxGroupMemberCount <= self.addData.count) {
            [SVProgressHUD showInfoWithStatus:XOChatLocalizedString(@"group.friend.limitMax")];
            [SVProgressHUD dismissWithDelay:2.0f];
            return;
        }
        TIMFriend *friend = self.sortedModelArr[indexPath.section][indexPath.row];
        BOOL contain = NO;
        for (TIMFriend *user  in self.addData) {
            if ([user.identifier isEqualToString:friend.identifier]) {
                contain = YES;
                break;
            }
        }
        if (!contain) {
            [self.addData addObject:friend];
            [self.view setNeedsLayout];
            [self.collectionView reloadData];
            [self refreshRightBBIStatus];
        }
    }
    // 踢出群成员
    else if (GroupMemberType_Remove == self.memberType)
    {
        TIMGroupInfo *groupInfo = self.groupData[indexPath.section][indexPath.row];
        NSString *dictMemId = groupInfo.group;
        BOOL contain = NO;
        for (TIMGroupInfo *info  in self.addData) {
            NSString *memId = info.group;
            if (!XOIsEmptyString(memId) && !XOIsEmptyString(dictMemId) && [memId isEqualToString:dictMemId]) {
                contain = YES;
                break;
            }
        }
        
        if (!contain) {
            [self.addData addObject:groupInfo];
            [self.view setNeedsLayout];
            [self.collectionView reloadData];
            [self refreshRightBBIStatus];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType)
    {
        //取消选择时删除对应数据
        TIMFriend *friend = self.sortedModelArr[indexPath.section][indexPath.row];
        BOOL contain = NO;
        for (TIMFriend *user  in self.addData) {
            if ([friend.identifier isEqualToString:user.identifier]) {
                contain = YES;
                break;
            }
        }
        if (contain) {
            [self.addData removeObject:friend];
            [self.view setNeedsLayout];
            [self.collectionView reloadData];
            [self refreshRightBBIStatus];
            
        }
    }
    else if (GroupMemberType_Remove == self.memberType)
    {
        TIMGroupInfo *groupInfo = self.groupData[indexPath.section][indexPath.row];
        NSString *dictMemId = groupInfo.group;
        BOOL contain = NO;
        for (TIMGroupInfo *info  in self.addData) {
            NSString *memId = info.group;
            if (!XOIsEmptyString(memId) && !XOIsEmptyString(dictMemId) && [memId isEqualToString:dictMemId]) {
                contain = YES;
                break;
            }
        }
        
        if (contain) {
            [self.addData removeObject:groupInfo];
            [self.view setNeedsLayout];
            [self.collectionView reloadData];
            [self refreshRightBBIStatus];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.1;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.searchbar isFirstResponder]) {
        [self.searchbar resignFirstResponder];
    }
}

//当前选中组
- (void)selectedSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if ([self.searchbar isFirstResponder]) {
        [self.searchbar resignFirstResponder];
    }
}

#pragma mark ========================= UICollectionViewDataSource & UICollectionViewDelegate =========================

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.addData.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GroupMemberIconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GroupMemberIconCellID forIndexPath:indexPath];
    
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType) {
        TIMFriend *friend = self.addData[indexPath.item];
        cell.imageUrl = friend.profile.faceURL;
    }
    else if (GroupMemberType_Remove == self.memberType) {
        GroupMemberInfoModel *model = self.addData[indexPath.item];
        cell.imageUrl = model.picture;
    }
    
    return  cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.addData removeObjectAtIndex:indexPath.item];
    [self.collectionView reloadData];
    [self.tableView reloadData];
    [self.view setNeedsLayout];
}

#pragma mark ========================= UISearchBarDelegate =========================

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // 创建群 | 添加群成员
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType) {
        __weak XOCreateGroupViewController *wself = self;
        self.tableView.mj_header = [MJRefreshHeader headerWithRefreshingBlock:^{
            __strong XOCreateGroupViewController *sself = wself;
            sself->page = 1;
            [sself.tableView.mj_footer resetNoMoreData];
        }];
        [self.tableView.mj_header beginRefreshing];
        self.tableView.mj_footer = [MJRefreshAutoFooter footerWithRefreshingBlock:^{
            __strong XOCreateGroupViewController *sself = wself;
            sself->page += 1;
        }];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSString *keyword = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!XOIsEmptyString(keyword)) {
        if (GroupMemberType_Remove == self.memberType) {
            __block NSMutableArray <NSDictionary *>* copyArr = @[].mutableCopy;
            [self.groupMembers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *realName = obj[@"realName"];
                if ([realName containsString:keyword]) {
                    [copyArr addObject:obj];
                }
            }];
            
            [self sortRemoveListWithArray:copyArr];
        }
    }
    else {
        [self sortRemoveListWithArray:self.groupMembers];
    }
}

#pragma mark ========================= lazy load =========================

- (UIBarButtonItem *)okBBI
{
    if (!_okBBI) {
        _sureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _sureBtn.bounds = CGRectMake(0, 0, 64, 44);
        [_sureBtn setTitle:NSLocalizedString(@"live.ok", nil) forState:UIControlStateNormal];
        [_sureBtn setTitleColor:AppTinColor forState:UIControlStateNormal];
        [_sureBtn addTarget:self action:@selector(sureClick) forControlEvents:UIControlEventTouchUpInside];
        _okBBI = [[UIBarButtonItem alloc]initWithCustomView:_sureBtn];
    }
    return _okBBI;
}

- (UITableView *)tableView
{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.allowsMultipleSelection = YES;
        _tableView.tableFooterView = [[UIView alloc] init];
        _tableView.sectionIndexColor = [UIColor lightTextColor]; //设置默认时索引值颜色
        _tableView.sectionIndexTrackingBackgroundColor = AppTinColor; //设置选中时，索引背景颜色
        _tableView.backgroundColor = [UIColor clearColor];
        
        [_tableView registerClass:[MemberTableViewCell class] forCellReuseIdentifier:MemberTableViewCellID];
    }
    return _tableView;
}

- (UICollectionView *)collectionView
{
    if (_collectionView == nil) {
        //自动网格布局
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[GroupMemberIconCell class] forCellWithReuseIdentifier:GroupMemberIconCellID];
    }
    return _collectionView;
}

- (UIView *)headView
{
    if (!_headView) {
        _headView = [[UIView alloc] init]; //CGRectMake(0, NavHFit, SCREENW, 54);
        _headView.backgroundColor = [UIColor whiteColor];
    }
    return _headView;
}

- (UISearchBar *)searchbar
{
    if (!_searchbar) {
        _searchbar = [[UISearchBar alloc] init];
        _searchbar.placeholder = XOChatLocalizedString(@"group.search.placeholder");
        _searchbar.tintColor = [UIColor groupTableViewBackgroundColor];
        _searchbar.barTintColor = [UIColor whiteColor];
        for (UIView *subView in _searchbar.subviews) {  //更改UISearchBar的背景为透明
            for (UIView *backView in subView.subviews){
                if ([backView isKindOfClass:NSClassFromString(@"UISearchBarBackground")]) {
                    backView.alpha = 0.0f;
                }
            }
        }
        [_searchbar setSearchFieldBackgroundImage:[UIImage xo_imageNamedFromChatBundle:@"search_background"] forState:UIControlStateNormal];
        _searchbar.delegate = self;
    }
    return _searchbar;
}

- (NSMutableArray *)groupData
{
    if (!_groupData) {
        _groupData = [[NSMutableArray alloc]init];
    }
    return _groupData;
}

- (NSMutableArray *)groupChatData
{
    if (!_groupChatData) {
        _groupChatData = [[NSMutableArray alloc]init];
    }
    return _groupChatData;
}

- (NSMutableArray *)addData
{
    if (!_addData) {
        _addData = [[NSMutableArray alloc]init];
    }
    return _addData;
}

- (NSMutableArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc]init];
    }
    return _dataSource;
}


@end


















#pragma mark ========================= GroupMemberInfoModel =========================

@implementation GroupMemberInfoModel

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

- (void)setNilValueForKey:(NSString *)key
{
    
}

- (id)valueForKey:(NSString *)key
{
    if ([key isEqualToString:@"sortKey"]) {
        if ([self.realName isChinese]) {
            return [self.realName pinyinString];
        }
        return self.realName;
    }
    return [super valueForKey:key];
}

- (NSString *)sortKey
{
    if (!XOIsEmptyString(_sortKey)) {
        return _sortKey;
    } else {
        if ([_realName includeChinese]) {
            _sortKey = [_realName pinyinString];
        } else {
            _sortKey = _realName;
        }
        return _sortKey;
    }
}

@end








#pragma mark ========================= GroupMemberSelectCell =========================

@interface GroupMemberSelectCell ()

@property (nonatomic, strong) UIImageView             *statusImageView;
@property (nonatomic, strong) UIImageView             *iconImageView;
@property (nonatomic, strong) UILabel                 *nameLabel;

@end

@implementation GroupMemberSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self.contentView addSubview:_statusImageView];
        [self.contentView addSubview:_iconImageView];
        [self.contentView addSubview:_nameLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (selected) {
        [_statusImageView setImage:[UIImage imageNamed:@"group_member_selected"]];
    }
    else {
        [_statusImageView setImage:[UIImage imageNamed:@"group_member"]];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    float margin = 10;
    self.statusImageView.frame = CGRectMake(margin, (self.height - 20)/2.0, 20, 20);
    self.iconImageView.frame = CGRectMake(margin, (self.height - 20)/2.0, 44.0, 44.0);
    self.iconImageView.layer.cornerRadius = 22.0;
    self.statusImageView.frame = CGRectMake(margin, (self.height - 20)/2.0, 20, 20);
}

- (UIImageView *)statusImageView
{
    if (!_statusImageView) {
        _statusImageView = [[UIImageView alloc] init];
        _statusImageView.contentMode = UIViewContentModeScaleAspectFit;
        _statusImageView.clipsToBounds = YES;
        [_statusImageView setImage:[UIImage imageNamed:@"group_member"]];
    }
    
    return _statusImageView;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        _iconImageView.clipsToBounds = YES;
        [_iconImageView setImage:[UIImage imageNamed:@"default_avatar"]];
    }
    
    return _iconImageView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:15];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _nameLabel;
}


@end




#pragma mark ========================= GroupMemberIconCell =========================

@interface GroupMemberIconCell ()

@property (nonatomic, strong) UIImageView             *iconImageView;

@end

@implementation GroupMemberIconCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.iconImageView];
    }
    return self;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        _iconImageView.clipsToBounds = YES;
        [_iconImageView setImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
    }
    
    return _iconImageView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.iconImageView.frame = CGRectMake(0, 0, self.width , self.height);
    self.iconImageView.layer.cornerRadius = self.iconImageView.width/2.0;
}

-(void)setImageUrl:(NSString *)imageUrl{
    [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
}

- (void)setAvatar:(UIImage *)avatar
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.iconImageView.image = avatar;
    }];
}

@end
