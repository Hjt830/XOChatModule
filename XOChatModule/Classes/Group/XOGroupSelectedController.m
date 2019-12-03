//
//  XOGroupSelectedController.m
//  xxoogo
//
//  Created by 鼎一  on 2019/5/22.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "XOGroupSelectedController.h"
#import "BMChineseSort.h"
#import "UIImage+XOChatBundle.h"
#import "UIImage+XOChatExtension.h"
#import "ForwardView.h"
//#import "NewPersonInfoViewController.h"
//#import "GroupSelectMemberViewController.h"

static NSString * const MemberTableViewCellID = @"MemberTableViewCellID";
static NSString * const GroupMemberIconCellID = @"GroupMemberIconCellID";
static NSString * const MemberTableViewHeadFootID = @"MemberTableViewHeadFootID";

@interface XOGroupSelectedController () <UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, ForwardViewDelegate>
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

@property (nonatomic, strong)NSMutableArray <NSString *> * firstLetterArray;  //排序后的出现过的拼音首字母数组
@property (nonatomic, strong)NSMutableArray <NSMutableArray <TIMUserProfile *> *> *sortedModelArr; //排序好的结果数组

@property (nonatomic, strong) NSArray  <NSString *> *existGroupIds;     // 添加|删除 群成员时已经存在的群成员Id列表

@property (nonatomic, strong) NSMutableArray    *addData;               // 选中的成员数据源

@end

@implementation XOGroupSelectedController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _memberType = SelectMemberType_Create;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title =  XOChatLocalizedString(@"group.select.member");
    
    [self setupSubView];
    
    [self initiliazation];
    
    [self.view setNeedsLayout];
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
    // 添加 | 删除 已经在群中的成员的ID集合
    if (SelectMemberType_Remove == self.memberType || SelectMemberType_Add == self.memberType) {
        self.existGroupIds = [self.existGroupMembers valueForKey:@"identifier"];
    }
    
    // 创建群 | 添加群成员
    if (SelectMemberType_Create == self.memberType || SelectMemberType_Add == self.memberType || SelectMemberType_Forward == self.memberType)
    {
        [[XOChatClient shareClient].contactManager getAllContactsList:^(NSArray <TIMFriend *> * _Nullable friendList) {
            
            NSMutableArray *mutFriendList = [NSMutableArray array];
            [friendList enumerateObjectsUsingBlock:^(TIMFriend * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [mutFriendList addObject:obj.profile];
            }];
            
            // 去掉客服
            [mutFriendList enumerateObjectsUsingBlock:^(TIMUserProfile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.identifier isEqualToString:OnlineServerIdentifier]) {
                    [mutFriendList removeObject:obj];
                }
            }];
            
            // 按照首字母排序
            BMChineseSortSetting.share.sortMode = 2; // 1或2
            [BMChineseSort sortAndGroup:mutFriendList key:@"nickname" finish:^(bool isSuccess, NSMutableArray *unGroupedArr, NSMutableArray *sectionTitleArr, NSMutableArray<NSMutableArray <TIMUserProfile *> *> *sortedObjArr) {
                if (isSuccess) {
                    self.firstLetterArray = sectionTitleArr;
                    self.sortedModelArr = sortedObjArr;
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.tableView reloadData];
                    }];
                }
            }];
        }];
    }
    // 删除群成员
    else if (SelectMemberType_Remove == self.memberType)
    {
        // 按照首字母排序
        BMChineseSortSetting.share.sortMode = 2; // 1或2
        [BMChineseSort sortAndGroup:self.existGroupMembers key:@"nickname" finish:^(bool isSuccess, NSMutableArray *unGroupedArr, NSMutableArray *sectionTitleArr, NSMutableArray<NSMutableArray <TIMUserProfile *> *> *sortedObjArr) {
            if (isSuccess) {
                self.firstLetterArray = sectionTitleArr;
                self.sortedModelArr = sortedObjArr;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView reloadData];
                }];
            }
        }];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    }
}

#pragma mark ========================= touch event =========================

- (void)sureClick
{
    [self endEdit];
    if (self.delegate && [self.delegate respondsToSelector:@selector(groupSelectController:selectMemberType:didSelectMember:)]) {
        [self.delegate groupSelectController:self selectMemberType:self.memberType didSelectMember:self.addData];
    }
    
    if (SelectMemberType_Create == self.memberType) {
        [self createGroup];
    }
    else if (SelectMemberType_Add == self.memberType) {
        [self addGroupMember];
    }
    else if (SelectMemberType_Remove == self.memberType) {
        [self removeGroupMember];
    }
    else if (SelectMemberType_Forward == self.memberType) {
        [self forwardMessage];
    }
}

#pragma mark ========================= help =========================

- (void)refreshRightBBIStatus
{
    if (self.addData.count > 0) {
        self.sureBtn.enabled = YES;
    } else {
        self.sureBtn.enabled = NO;
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
    for (TIMUserProfile *profile in mutArray) {
        if ([profile.identifier isEqualToString:[XOKeyChainTool getUserName]]) {
            [mutArray removeObject:profile];
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
    
    [self.addData enumerateObjectsUsingBlock:^(TIMUserProfile * _Nonnull profile, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (!XOIsEmptyString(profile.identifier)) {
            [memberList addObject:profile.identifier];
        }
        if (!XOIsEmptyString(profile.nickname)) {
            [groupname appendString:profile.nickname];
            if (idx != (self.addData.count - 1)) {
                [groupname appendString:@"、"];
            }
        }
        
        TIMCreateGroupMemberInfo *memberInfo = [[TIMCreateGroupMemberInfo alloc] init];
        memberInfo.member = profile.identifier;
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
    NSArray *selectedIds = [self.addData valueForKey:@"identifier"];
    [[TIMGroupManager sharedInstance] inviteGroupMember:self.groupInfo.group members:selectedIds succ:^(NSArray *members) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
    } fail:^(int code, NSString *msg) {
        
    }];
}

// 删除群成员
- (void)removeGroupMember
{
    NSArray *selectedIds = [self.addData valueForKey:@"identifier"];
    [[TIMGroupManager sharedInstance] deleteGroupMemberWithReason:self.groupInfo.group reason:@"" members:selectedIds succ:^(NSArray <TIMGroupMemberResult *>* members) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
    } fail:^(int code, NSString *msg) {
        
    }];
}

// 转发消息
- (void)forwardMessage
{
    if (!XOIsEmptyArray(self.addData)) {
        ForwardView *forwardView = [[ForwardView alloc] init];
        forwardView.delegate = self;
        [forwardView showInView:self.view withReceivers:self.addData message:self.forwardMsg delegate:self];
    }
}

#pragma mark ========================= ForwardViewDelegate =========================

- (void)forwardView:(ForwardView *)forwardView forwardMessage:(TIMMessage *)message toReceivers:(NSArray *)receivers
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(groupSelectController:forwardMessage:toReceivers:)]) {
        [self.delegate groupSelectController:self forwardMessage:message toReceivers:receivers];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void)forwardViewDidCancelForward:(ForwardView *)forwardView {}

#pragma mark ========================= UITableViewDataSource & UITableViewDelegate =========================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.firstLetterArray count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sortedModelArr[section] count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MemberTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MemberTableViewCellID forIndexPath:indexPath];
    TIMUserProfile *friend = self.sortedModelArr[indexPath.section][indexPath.row];
    cell.profile = friend;
    
    // 添加群成员时，已经在群里面的默认勾选
    if (SelectMemberType_Add == self.memberType)
    {
        if ([self.existGroupIds containsObject:friend.identifier]) {
            cell.isLock = YES;
        } else {
            cell.isLock = NO;
        }
    }
    // 删除群成员时，群主默认勾选
    else if (SelectMemberType_Remove == self.memberType) {
        if ([friend.identifier isEqualToString:self.groupInfo.owner]) {
            cell.isLock = YES;
        } else {
            cell.isLock = NO;
        }
    }
    
    NSArray * selectedIds = [self.addData valueForKey:@"identifier"];
    BOOL contain = [selectedIds containsObject:friend.identifier];
    if (contain) {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    return cell;
}
// 选中
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TIMUserProfile *profile = self.sortedModelArr[indexPath.section][indexPath.row];
    // 创建群
    if (SelectMemberType_Create == self.memberType)
    {
        if (self.addData.count >= MaxGroupMemberCount) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            [SVProgressHUD showInfoWithStatus:XOChatLocalizedString(@"group.friend.limitMax")];
            [SVProgressHUD dismissWithDelay:2.0f];
            return;
        }
    }
    // 添加群成员时
    else if (SelectMemberType_Add == self.memberType)
    {
        // 已存在群成员不可选择
        if ([self.existGroupIds containsObject:profile.identifier]) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        // 选择人数不可超过最大限制
        if ((self.addData.count + self.existGroupMembers.count) > MaxGroupMemberCount) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            [SVProgressHUD showInfoWithStatus:XOChatLocalizedString(@"group.friend.limitMax")];
            [SVProgressHUD dismissWithDelay:2.0f];
            return;
        }
    }
    // 删除群成员时
    else if (SelectMemberType_Remove == self.memberType) {
        // 群主不可选择
        if ([profile.identifier isEqualToString:self.groupInfo.owner]) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
    }
    // 转发消息时
    else if (SelectMemberType_Forward == self.memberType) {
        if (self.addData.count >= MaxMsgForwardCount) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            [SVProgressHUD showInfoWithStatus:XOChatLocalizedString(@"chat.message.forward.limit")];
            [SVProgressHUD dismissWithDelay:2.0f];
            return;
        }
    }
    
    // 选中
    NSArray * selectedIds = [self.addData valueForKey:@"identifier"];
    BOOL contain = [selectedIds containsObject:profile.identifier];
    if (!contain) {
        @synchronized (self) {
            [self.addData addObject:profile];
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.collectionView reloadData];
            [self.view setNeedsLayout];
            [self refreshRightBBIStatus];
        }];
    }
    
    [self endEdit];
}
// 反选
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TIMUserProfile *profile = self.sortedModelArr[indexPath.section][indexPath.row];
    // 添加群成员时
    if (SelectMemberType_Add == self.memberType)
    {
        // 已经在群中的成员不可反选
        if ([self.existGroupIds containsObject:profile.identifier]) {
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            return;
        }
    }
    // 删除群成员时
    else if (SelectMemberType_Remove == self.memberType)
    {
        // 群主不可反选
        if ([profile.identifier isEqualToString:self.groupInfo.owner]) {
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            return;
        }
    }
    
    // 反选
    NSArray * selectedIds = [self.addData valueForKey:@"identifier"];
    BOOL contain = [selectedIds containsObject:profile.identifier];
    if (contain) {
        @synchronized (self) {
            [self.addData removeObject:profile];
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.collectionView reloadData];
            [self.view setNeedsLayout];
            [self refreshRightBBIStatus];
        }];
    }
    
    [self endEdit];
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
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:MemberTableViewHeadFootID];
}
// 索引表
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.firstLetterArray;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.firstLetterArray objectAtIndex:section];
}
// 点击右侧索引表项时调用 索引与section的对应关系
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}
//当前选中组
- (void)selectedSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
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
    TIMUserProfile *profile = self.addData[indexPath.item];
    cell.imageUrl = profile.faceURL;
    
    return  cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized (self) {
        [self.addData removeObjectAtIndex:indexPath.item];
    }
    [self.collectionView reloadData];
    [self.tableView reloadData];
    [self.view setNeedsLayout];
    
    [self endEdit];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self endEdit];
}

#pragma mark ========================= UISearchBarDelegate =========================

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // 创建群 | 添加群成员
    if (SelectMemberType_Create == self.memberType || SelectMemberType_Add == self.memberType) {
        __weak XOGroupSelectedController *wself = self;
        self.tableView.mj_header = [MJRefreshHeader headerWithRefreshingBlock:^{
            __strong XOGroupSelectedController *sself = wself;
            sself->page = 1;
            [sself.tableView.mj_footer resetNoMoreData];
        }];
        [self.tableView.mj_header beginRefreshing];
        self.tableView.mj_footer = [MJRefreshAutoFooter footerWithRefreshingBlock:^{
            __strong XOGroupSelectedController *sself = wself;
            sself->page += 1;
        }];
    }
}

//- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//{
//    NSString *keyword = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//    if (!XOIsEmptyString(keyword)) {
//        if (SelectMemberType_Remove == self.memberType) {
//            __block NSMutableArray <NSDictionary *>* copyArr = @[].mutableCopy;
//            [self.groupMembers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                NSString *realName = obj[@"realName"];
//                if ([realName containsString:keyword]) {
//                    [copyArr addObject:obj];
//                }
//            }];
//
//            [self sortRemoveListWithArray:copyArr];
//        }
//    }
//    else {
//        [self sortRemoveListWithArray:self.groupMembers];
//    }
//}

#pragma mark ========================= help =========================

- (void)endEdit
{
    if ([self.searchbar isFirstResponder]) {
        [self.searchbar resignFirstResponder];
    }
}

#pragma mark ========================= lazy load =========================

- (UIBarButtonItem *)okBBI
{
    if (!_okBBI) {
        _sureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _sureBtn.bounds = CGRectMake(0, 0, 64, 44);
        _sureBtn.enabled = NO;
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
        _tableView.sectionIndexColor = [UIColor darkTextColor]; //设置默认时索引值颜色
        _tableView.backgroundColor = BG_TableColor;
        
        [_tableView registerClass:[MemberTableViewCell class] forCellReuseIdentifier:MemberTableViewCellID];
        [_tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:MemberTableViewHeadFootID];
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
        _collectionView.backgroundColor = [UIColor XOWhiteColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[GroupMemberIconCell class] forCellWithReuseIdentifier:GroupMemberIconCellID];
    }
    return _collectionView;
}

- (UIView *)headView
{
    if (!_headView) {
        _headView = [[UIView alloc] init];
        _headView.backgroundColor = [UIColor XOWhiteColor];
    }
    return _headView;
}

- (UISearchBar *)searchbar
{
    if (!_searchbar) {
        _searchbar = [[UISearchBar alloc] init];
        _searchbar.barStyle = UIBarStyleDefault;
        _searchbar.translucent = YES;
        _searchbar.delegate = self;
        _searchbar.barTintColor = [UIColor groupTableViewColor];
        _searchbar.backgroundImage = nil;
        _searchbar.tintColor = AppTinColor;
        _searchbar.placeholder = XOChatLocalizedString(@"group.search.placeholder");
        UIImage *image = [UIImage xo_imageNamedFromChatBundle:@"search_background"];
        [_searchbar setSearchFieldBackgroundImage:[image XO_imageWithTintColor:BG_TableColor] forState:UIControlStateNormal];
    }
    return _searchbar;
}

- (NSMutableArray <TIMUserProfile *>*)addData
{
    if (!_addData) {
        _addData = [[NSMutableArray alloc]init];
    }
    return _addData;
}


@end
















#pragma mark ========================= GroupMemberSelectCell =========================

@interface MemberTableViewCell ()

@property (nonatomic, strong) UIImageView   *selectImage;
@property (nonatomic, strong) UIImageView   *iconimagev;
@property (nonatomic, strong) UILabel       *nameLabel;

@end

@implementation MemberTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ([super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.selectImage];
        [self.contentView addSubview:self.iconimagev];
        [self.contentView addSubview:self.nameLabel];
        _isLock = NO;
    }
    return self;
}

- (void)setUser:(TIMFriend *)user
{
    _user = user;
    self.profile = _user.profile;
}

- (void)setProfile:(TIMUserProfile *)profile
{
    _profile = profile;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!XOIsEmptyString(profile.faceURL)) {
            [self.iconimagev sd_setImageWithURL:[NSURL URLWithString:profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
        } else {
           self.iconimagev.image = [UIImage xo_imageNamedFromChatBundle:@"default_avatar"];
        }
        self.nameLabel.text = profile.nickname;
    }];
}

- (void)setIsLock:(BOOL)isLock
{
    _isLock = isLock;
    
    if (isLock) {
        self.selectImage.image = [[UIImage xo_imageNamedFromChatBundle:@"group_member_selected"] XO_imageWithTintColor:[UIColor grayColor]];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (!self.isLock) {
        [super setSelected:selected animated:animated];
        
        if (selected) {
            self.selectImage.image = [UIImage xo_imageNamedFromChatBundle:@"group_member_selected"];
        } else {
            self.selectImage.image = [UIImage xo_imageNamedFromChatBundle:@"group_member"];
        }
    }
}

- (void)setNameAndIcon:(TIMUserProfile *)profile
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (profile) {
            [self.iconimagev sd_setImageWithURL:[NSURL URLWithString:profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
            self.nameLabel.text = profile.nickname;
        }
        else {
            self.nameLabel.text = @"";
            self.iconimagev.image = [UIImage xo_imageNamedFromChatBundle:@"default_avatar"];
        }
    }];
}

#pragma mark ========================= layout =========================

- (void)layoutSubviews
{
    self.selectImage.frame = CGRectMake(15, (self.height - 18.0)/2.0, 18.0, 18.0);
    self.iconimagev.frame = CGRectMake(CGRectGetMaxX(self.selectImage.frame) + 15, (self.height - 40.0)/2.0, 40.0, 40.0);
    self.iconimagev.layer.cornerRadius = 7;
    self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.iconimagev.frame) + 10, 10, self.width - self.iconimagev.right - 30, 40);
}

#pragma mark ========================= lazy load =========================

- (UIImageView *)selectImage
{
    if (_selectImage == nil) {
        _selectImage = [[UIImageView alloc] init];
        [_selectImage setImage:[UIImage xo_imageNamedFromChatBundle:@"group_member"]];
    }
    return _selectImage;
}

- (UIImageView *)iconimagev
{
    if (_iconimagev == nil) {
        _iconimagev = [[UIImageView alloc]init];
        _iconimagev.clipsToBounds = YES;
        _iconimagev.image = [UIImage xo_imageNamedFromChatBundle:@"default_avatar"];
        
        CGRect bounds = CGRectMake(0, 0, 40, 40);
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:bounds.size];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = bounds;
        maskLayer.path = maskPath.CGPath;
        _iconimagev.layer.mask = maskLayer;
    }
    return _iconimagev;
}

- (UILabel *)nameLabel
{
    if (_nameLabel == nil) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textColor = [UIColor XOTextColor];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
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
