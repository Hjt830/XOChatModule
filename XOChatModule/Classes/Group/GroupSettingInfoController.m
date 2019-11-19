//
//  GroupSettingInfoController.m
//  xxoogo
//
//  Created by 黄金柱 on 2019/5/24.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "GroupSettingInfoController.h"
#import "GroupInfoEditViewController.h"
#import "XOGroupSelectedController.h"

#import "NSBundle+ChatModule.h"
#import "UIImage+XOChatBundle.h"
#import "UIImage+XOChatExtension.h"
#import <XOBaseLib/XOBaseLib.h>

NSString * XOGroupToppingDidChangeNotification     = @"XOGroupToppingDidChangeNotification";
NSString * XOGroupMuteDidChangeNotification        = @"XOGroupMuteDidChangeNotification";

static NSString * const GroupMemberSwitchCellID         = @"GroupMemberSwitchCellID";
static NSString * const GroupMemberSettingCellID        = @"GroupMemberSettingCellID";
static NSString * const GroupMemberSettingTailCellID    = @"GroupMemberSettingTailCellID";
static NSString * const GroupMemberSettingIconCellID    = @"GroupMemberSettingIconCellID";

@interface GroupSettingInfoController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, GroupInfoEditViewControllerProtocol, XOGroupSelectedDelegate>
{
    TIMGroupInfo        *_groupInfo;
}
@property (nonatomic, assign) BOOL                      isHoster; // 是否是群主

@property (nonatomic, strong) UIView                    *tableHeaderView;
@property (nonatomic, strong) UIView                    *tableHeaderBackgroundView;
@property (nonatomic, strong) UIView                    *tableFooterView;
@property (nonatomic, strong) UITableView               *tableView;
@property (nonatomic, strong) UICollectionView          *collectionView;
@property (nonatomic, strong) UIButton                  *allMemberBtn;

@property (nonatomic, strong) NSArray                   *menus;

@property (nonatomic, strong) NSArray  <TIMUserProfile *>           *groupMembers;  // 所有的群成员
@property (nonatomic, strong) NSMutableArray <TIMUserProfile *>     *showMembers;   // 展示的群成员
@property (nonatomic, assign) BOOL                                  isShowAll;      // 是否展示了所有人

@end

@implementation GroupSettingInfoController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BG_TableColor;
    self.title = [NSString stringWithFormat:@"%@(%u)", XOChatLocalizedString(@"group.setting.title"), self.groupInfo.memberNum];
    
    self.isShowAll = NO; // 不显示加号
    
    [self setupSubViews];
    
    [self initilization];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (XOIsEmptyArray(self.showMembers) || self.showMembers.count == 0) {
        self.collectionView.frame = CGRectZero;
        self.allMemberBtn.frame = CGRectZero;
        self.tableHeaderBackgroundView.frame = CGRectZero;
        self.tableHeaderView.frame = CGRectZero;
    }
    else {
        float marign = 10.0f;    // 与边缘的间距
        float space  = 15.0f;    // 行间距
        float iconWith = (self.view.width - 30 - 4 * space)/5;  // 头像的宽度
        float iconHeight = iconWith + 15;  // 头像的宽度
        
        NSUInteger count = self.isHoster ? self.showMembers.count + 2 : self.showMembers.count + 1; // 加上 (+ | -)
        NSUInteger row = (count % 5 == 0) ? count/5 : (count/5 + 1); // 行数
        BOOL showAllmember = (self.isHoster && self.groupMembers.count > 18) || (!self.isHoster && self.groupMembers.count > 19);
        float allowHei = showAllmember ? 30: 0;
        float collectionH = row * (iconHeight + space) - space;
        float BackgroundViewH = marign + collectionH + allowHei + (showAllmember ? 0 : marign);
        float headerHeight = space * 2 + BackgroundViewH;
        
        self.collectionView.frame = CGRectMake(15, space + marign, self.view.width - 30, collectionH);
        if (allowHei > 0) {
            self.allMemberBtn.hidden = NO;
            self.allMemberBtn.frame = CGRectMake(15, headerHeight - allowHei - space, self.view.width - 30, allowHei);
        } else {
            self.allMemberBtn.hidden = YES;
            self.allMemberBtn.frame = CGRectZero;
        }
        
        self.tableHeaderBackgroundView.frame = CGRectMake(0, space, self.view.width, BackgroundViewH);
        self.tableHeaderView.frame = CGRectMake(0, 0, self.view.width, headerHeight);
    }
    
    self.tableView.frame = CGRectMake(0, 0, self.view.width, self.view.height);
    self.tableView.tableHeaderView = self.tableHeaderView;
}

#pragma mark ========================= UI =========================

- (void)setupSubViews
{
    [self.view addSubview:self.tableView];
    [self.tableHeaderView addSubview:self.collectionView];
    [self.tableHeaderView addSubview:self.allMemberBtn];
    self.tableView.tableHeaderView = self.tableHeaderView;
    self.tableView.tableFooterView = self.tableFooterView;
}

#pragma mark ========================= 群信息 =========================

- (void)initilization
{
    NSString *groupId = XOIsEmptyString(self.groupId) ? self.groupInfo.group : self.groupId;
    if (XOIsEmptyString(groupId)) {
        return;
    }
    
    // 获取群信息
    [self getGroupInfoWith:groupId complection:^(BOOL finish, TIMGroupInfo *groupInfo) {
        if (finish) {
            self.groupInfo = groupInfo;
            [self layoutGroupSettingView];
        }
        else {
            if (self.groupInfo) {
                [self layoutGroupSettingView];
            }
            else {
                // 查询数据库
                [[XOContactManager defaultManager] getGroupInfo:groupId handler:^(TIMGroupInfo * _Nullable groupInfo) {
                    self.groupInfo = groupInfo;
                    [self layoutGroupSettingView];
                }];
            }
        }
    }];
}

// 布局群信息列表
- (void)layoutGroupSettingView
{
    self.isHoster = [self.groupInfo.owner isEqualToString:[XOKeyChainTool getUserName]];
    if (self.isHoster) {
        self.menus = @[XOChatLocalizedString(@"group.setting.groupname"),
                       XOChatLocalizedString(@"group.setting.notification"),
                       XOChatLocalizedString(@"group.setting.topping"),
                       XOChatLocalizedString(@"group.setting.mute"),
                       XOChatLocalizedString(@"group.setting.exit"),
                       XOChatLocalizedString(@"group.setting.disband")];
    } else {
        self.menus = @[XOChatLocalizedString(@"group.setting.groupname"),
                       XOChatLocalizedString(@"group.setting.notification"),
                       XOChatLocalizedString(@"group.setting.topping"),
                       XOChatLocalizedString(@"group.setting.mute"),
                       XOChatLocalizedString(@"group.setting.exit")];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];

    [self loadGroupMember];
}

// 布局群成员头像
- (void)initilizationMembers
{
    // 未展开时 -- 最多展示5排
    if (!self.isShowAll) {
        // 群主
        if (self.isHoster) {
            // 如果群成员超过18个, 则只展示前18个
            if (self.groupMembers.count > 18) {
                @synchronized (self) {
                    [self.showMembers removeAllObjects];
                    [self.groupMembers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (idx < 18) {
                            [self.showMembers addObject:obj];
                        } else {
                            *stop = YES;
                        }
                    }];
                }
            }
            else {
                @synchronized (self) {
                    [self.showMembers removeAllObjects];
                    [self.showMembers addObjectsFromArray:self.groupMembers];
                }
            }
        }
        // 非群主 -- 如果群成员超过20个
        else {
            if (self.groupMembers.count > 19) {
                @synchronized (self) {
                    [self.showMembers removeAllObjects];
                    [self.groupMembers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (idx < 19) {
                            [self.showMembers addObject:obj];
                        } else {
                            *stop = YES;
                        }
                    }];
                }
            }
            else {
                @synchronized (self) {
                    [self.showMembers removeAllObjects];
                    [self.showMembers addObjectsFromArray:self.groupMembers];
                }
            }
        }
    }
    // 展开时
    else {
        @synchronized (self) {
            [self.showMembers removeAllObjects];
            [self.showMembers addObjectsFromArray:self.groupMembers];
        }
    }
    
    [self.view setNeedsLayout];
    [self.collectionView reloadData];
}

#pragma mark ========================= request =========================

- (void)getGroupInfoWith:(NSString *)groupId complection:(void(^)(BOOL finish, TIMGroupInfo *groupInfo))complectionHandler
{
    if (!XOIsEmptyString(groupId)) {

        [[TIMGroupManager sharedInstance] getGroupInfo:@[groupId] succ:^(NSArray<TIMGroupInfo *> *arr) {
            
            if (arr.count > 0) {
                if (complectionHandler) {
                    complectionHandler (YES, arr[0]);
                }
            } else {
                if (complectionHandler) {
                    complectionHandler (NO, nil);
                }
            }
        } fail:^(int code, NSString *msg) {
            if (complectionHandler) {
                complectionHandler (NO, nil);
            }
        }];
    }
    else {
        if (complectionHandler) {
            complectionHandler (NO, nil);
        }
    }
}

- (void)loadGroupMember
{
    if (!XOIsEmptyString(self.groupInfo.group)) {
        [[TIMGroupManager sharedInstance] getGroupMembers:self.groupInfo.group succ:^(NSArray <TIMGroupMemberInfo *>* members) {
            
            // 按照加入时间排序
            NSMutableArray <TIMGroupMemberInfo *>*sortArray = [members sortedArrayUsingComparator:^NSComparisonResult(TIMGroupMemberInfo *  _Nonnull obj1, TIMGroupMemberInfo *  _Nonnull obj2) {
                return obj1.joinTime < obj2.joinTime;
            }].mutableCopy;
            // 将群主排到第一个
            [sortArray enumerateObjectsUsingBlock:^(TIMGroupMemberInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (TIM_GROUP_MEMBER_ROLE_SUPER == obj.role) {
                    [sortArray removeObject:obj];
                    [sortArray insertObject:obj atIndex:0];
                    *stop = YES;
                }
            }];
            
            NSArray <NSString *>*memberIds = [sortArray valueForKey:@"member"];
            [[TIMFriendshipManager sharedInstance] getUsersProfile:memberIds forceUpdate:YES succ:^(NSArray<TIMUserProfile *> *profiles) {
                
                self.groupMembers = profiles;
                
                [self initilizationMembers];
                
            } fail:^(int code, NSString *msg) {
                
                NSLog(@"查询群成员资料失败 code: %d,  msg: %@", code, msg);
            }];
            
            self.title = [NSString stringWithFormat:@"%@(%lu)", XOChatLocalizedString(@"group.setting.title"), (unsigned long)members.count];
            
        } fail:^(int code, NSString *msg) {
            NSLog(@"获取群成员失败: %d  错误信息: %@", code, msg);
        }];
    }
}

#pragma mark ========================= lazy load =========================

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.allowsMultipleSelection = YES;
        _tableView.sectionHeaderHeight = 15.0f;
        _tableView.sectionFooterHeight = 0.0f;
        _tableView.rowHeight = 60.0f;
        _tableView.backgroundColor = BG_TableColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:GroupMemberSettingCellID];
        [_tableView registerClass:[GroupMemberSwitchCell class] forCellReuseIdentifier:GroupMemberSwitchCellID];
        [_tableView registerClass:[GroupMemberSettingTailCell class] forCellReuseIdentifier:GroupMemberSettingTailCellID];
    }
    return _tableView;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 10;
        layout.minimumInteritemSpacing = 10;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        
        [_collectionView registerClass:[GroupMemberSettingIconCell class] forCellWithReuseIdentifier:GroupMemberSettingIconCellID];
    }
    return _collectionView;
}

- (UIView *)tableHeaderView
{
    if (!_tableHeaderView) {
        _tableHeaderView = [[UIView alloc] init];
        _tableHeaderView.backgroundColor = BG_TableColor;
        
        _tableHeaderBackgroundView = [[UIView alloc] init];
        _tableHeaderBackgroundView.backgroundColor = [UIColor whiteColor];
        [_tableHeaderView addSubview:_tableHeaderBackgroundView];
    }
    return _tableHeaderView;
}

- (UIView *)tableFooterView
{
    if (!_tableFooterView) {
        _tableFooterView = [[UIView alloc] init];
        _tableFooterView.backgroundColor = BG_TableColor;
        
        NSArray *array = self.isHoster ? @[NSLocalizedString(@"live.deletele", nil), NSLocalizedString(@"live.Disband", nil)] : @[NSLocalizedString(@"live.deletele", nil)];
        for (int i = 0; i < array.count; i++) {
            NSString *title = array[i];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setTitle:title forState:UIControlStateNormal];
            [button setTitleColor:RGBOF(0xFF4081) forState:UIControlStateNormal];
            button.tag = 100 + i;
            button.frame = CGRectMake(0, 15 + 75 * i, self.view.width, 60);
            
            [button addTarget:self action:@selector(groupOperation:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    return _tableFooterView;
}

- (UIButton *)allMemberBtn
{
    if (!_allMemberBtn) {
        _allMemberBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_allMemberBtn setTitle:@"All members" forState:UIControlStateNormal];
        [_allMemberBtn.titleLabel setFont:[UIFont systemFontOfSize:13]];
        [_allMemberBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [_allMemberBtn addTarget:self action:@selector(showAllMember:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _allMemberBtn;
}

- (NSMutableArray <TIMUserProfile *>*)showMembers
{
    if (!_showMembers) {
        _showMembers = [NSMutableArray array];
    }
    return _showMembers;
}

#pragma mark ========================= Touch event =========================

// 显示|隐藏 所有成员
- (void)showAllMember:(UIButton *)sender
{
    self.isShowAll = !self.isShowAll;
    
    [self initilizationMembers];
}

// 退群或者解散群
- (void)groupOperation:(UIButton *)sender
{
    // 退群
    if (100 == sender.tag) {
        [self exitGroup:^(BOOL finish) {
            if (finish) NSLog(@"退群成功");
            else NSLog(@"退群失败");
        }];
    }
    // 解散群
    else {
        [self disbandGroup:^(BOOL finish) {
            if (finish) NSLog(@"解散群成功");
            else NSLog(@"解散群失败");
        }];
    }
}

#pragma mark ========================= UITableViewDataSource、UITableViewDelegate =========================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.menus.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = self.menus[indexPath.section];
    
    if (2 == indexPath.section || 3 == indexPath.section) {
        GroupMemberSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:GroupMemberSwitchCellID forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = title;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        
        if (2 == indexPath.section) {
            if ([[XOContactManager defaultManager] isToppingReceiver:self.groupInfo.group]) {
                [cell setOn:YES];
            } else {
                [cell setOn:NO];
            }
        } else {
            if ([[XOContactManager defaultManager] isMuteGroup:self.groupInfo.group]) {
                [cell setOn:YES];
            } else {
                [cell setOn:NO];
            }
        }
        
        __weak GroupSettingInfoController *wself = self;
        __weak GroupMemberSwitchCell *wCell = cell;
        cell.switchClick = ^(BOOL on) {
            __strong GroupSettingInfoController *sself = wself;
            __strong GroupMemberSwitchCell *sCell = wCell;

            // 置顶 | 取消置顶
            if (2 == indexPath.section)
            {
                BOOL result = NO;
                [sCell setIsLocked:YES];
                if (on) { // 置顶
                    result = [[XOContactManager defaultManager] addToppingListWithReceiverId:sself.groupInfo.group];
                } else { // 取消置顶
                    result = [[XOContactManager defaultManager] removeToppingListWithReceiverId:sself.groupInfo.group];
                }
                [sCell setIsLocked:NO];

                // 操作失败, 回退状态
                if (!result) {
                    [sCell setOn:!on];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:XOGroupToppingDidChangeNotification object:nil userInfo:@{@"groupId": self.groupInfo.group, @"on": @(on)}];
                }
            }
            // 免打扰 | 取消免打扰
            else if (3 == indexPath.section)
            {
                BOOL result = NO;
                [sCell setIsLocked:YES];
                if (on) { // 置顶
                    result = [[XOContactManager defaultManager] addMuteListWithGroupId:sself.groupInfo.group];
                } else { // 取消置顶
                    result = [[XOContactManager defaultManager] removeMuteListWithGroupId:sself.groupInfo.group];
                }
                [sCell setIsLocked:NO];
                
                // 操作失败, 回退状态
                if (!result) {
                    [sCell setOn:!on];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:XOGroupMuteDidChangeNotification object:@(on)];
                }
            }
        };
        
        return cell;
    }
    else if (4 == indexPath.section || 5 == indexPath.section) {
        GroupMemberSettingTailCell *cell = [tableView dequeueReusableCellWithIdentifier:GroupMemberSettingTailCellID forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (indexPath.section < self.menus.count) {
            cell.title = self.menus[indexPath.section];
        }
        return cell;
    }
    else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:GroupMemberSettingCellID];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        
        if (indexPath.section == 0) {
            if (!XOIsEmptyString(self.groupInfo.groupName)) {
                cell.detailTextLabel.text = self.groupInfo.groupName;
            }
        }
        else {
            cell.detailTextLabel.numberOfLines = 2;
            if (!XOIsEmptyString(self.groupInfo.notification)) {
                cell.detailTextLabel.text = self.groupInfo.notification;
            }
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.textLabel.text = title;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        case 1:
        {
            GroupInfoEditViewController *editVC = [[GroupInfoEditViewController alloc] init];
            if (0 == indexPath.section) {
                editVC.editType = GroupEditTypeGroupName;
            } else {
                editVC.editType = GroupEditTypeNotification;
            }
            editVC.groupId = self.groupInfo.group;
            editVC.groupInfo = self.groupInfo;
            editVC.delegate = self;
            editVC.isOwner = self.isHoster;
            [self.navigationController pushViewController:editVC animated:YES];
        }
            break;
        case 4:{  // 退群
            // 如果是群主
            if (self.isHoster && !XOIsEmptyArray(self.groupMembers)) {
                // 如果群成员个数只有两个, 则直接解散群
                if (self.groupMembers.count <= 2) {
                    [self disbandGroup:^(BOOL finish) {
                        if (finish) NSLog(@"解散群成功: %@", self.groupInfo.groupName);
                        else NSLog(@"解散群失败: %@", self.groupInfo.groupName);
                    }];
                }
                // 否则先转让群, 再退群
                else {
                    __block NSString *newOwnerId = nil;
                    [self.groupMembers enumerateObjectsUsingBlock:^(TIMUserProfile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj.identifier isEqualToString:[XOKeyChainTool getUserName]]) {
                            newOwnerId = obj.identifier;
                            *stop = YES;
                        }
                    }];
                    
                    if (!XOIsEmptyString(newOwnerId)) {
                        // 转让群
                        [self changeGroupToNewOwner:newOwnerId complection:^(BOOL finish) {
                            if (finish) {
                                NSLog(@"转让群成功: %@", self.groupInfo.groupName);
                                
                                // 退群
                                [self exitGroup:^(BOOL finish) {
                                    if (finish) NSLog(@"退出群成功: %@", self.groupInfo.groupName);
                                    else NSLog(@"退出群失败: %@", self.groupInfo.groupName);
                                }];
                            }
                            else {
                                NSLog(@"转让群失败: %@", self.groupInfo.groupName);
                            }
                        }];
                    }
                    else {
                        // 解散群
                        [self disbandGroup:^(BOOL finish) {
                            if (finish) NSLog(@"解散群成功: %@", self.groupInfo.groupName);
                            else NSLog(@"解散群失败: %@", self.groupInfo.groupName);
                        }];
                    }
                }
            }
            // 不是群主, 直接退群
            else {
                [self exitGroup:^(BOOL finish) {
                    if (finish) NSLog(@"退出群成功: %@", self.groupInfo.groupName);
                    else NSLog(@"退出群失败: %@", self.groupInfo.groupName);
                }];
            }
        }
            break;
            
        case 5:  // 群主解散群
        {
            [self disbandGroup:^(BOOL finish) {
                if (finish) NSLog(@"解散群成功: %@", self.groupInfo.groupName);
                else NSLog(@"解散群失败: %@", self.groupInfo.groupName);
            }];
        }
            break;
        default:
            break;
    }
}

#pragma mark ========================= UICollectionViewDataSource、UICollectionViewDelegate =========================

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // 群主   -- (加上  + -)
    if (self.isHoster) {
        return self.showMembers.count + 2;
    }
    return self.showMembers.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GroupMemberSettingIconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GroupMemberSettingIconCellID forIndexPath:indexPath];
    if (indexPath.item == self.showMembers.count) {
        cell.showAdd = YES;
    } else if (indexPath.item > self.showMembers.count) {
        cell.showDel = YES;
    } else {
        cell.showAdd = NO;
        cell.showDel = NO;
        // 设置头像
        if (indexPath.item < self.showMembers.count) {
            TIMUserProfile *info = self.showMembers[indexPath.item];
            cell.profile = info;
        }
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    float itemW = (collectionView.width - 60)/5.0;
    return CGSizeMake(itemW, itemW + 15);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item >= self.showMembers.count) {
        XOGroupSelectedController *selectVC = [[XOGroupSelectedController alloc] init];
        if (indexPath.item == self.showMembers.count) {// 添加群成员
            selectVC.memberType = GroupMemberType_Add;
        }
        else if (indexPath.item > self.showMembers.count) { // 剔除群成员
            selectVC.memberType = GroupMemberType_Remove;
        }
        selectVC.existGroupMembers = self.groupMembers;
        selectVC.groupInfo = self.groupInfo;
        selectVC.delegate = self;
        [self.navigationController pushViewController:selectVC animated:YES];
    }
}

#pragma mark ========================= GroupInfoEditViewControllerProtocol =========================

- (void)groupInfoEdit:(GroupInfoEditViewController *)editVC didEditSuccess:(NSString *)modifyText editType:(GroupEditType)type
{
    if (GroupEditTypeGroupName == type) {
        self.groupInfo.groupName = modifyText;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    }
    else if (GroupEditTypeNotification == type) {
        self.groupInfo.notification = modifyText;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    }
}

#pragma mark ========================= XOGroupSelectedDelegate =========================

// 选中成员的回调
- (void)groupSelectController:(XOGroupSelectedController *)selectController selectMemberType:(GroupMemberType)memberType didSelectMember:(NSArray <TIMUserProfile *> *)selectMember
{
    [self loadGroupMember];
    
    // 删除缓存中的群头像, 在需要的地方会自动生成
    [[SDImageCache sharedImageCache] removeImageFromDiskForKey:self.groupInfo.group];
}

#pragma mark ========================= API =========================

// 解散群
- (void)disbandGroup:(void(^)(BOOL finish))complectionHandler
{
    if (XOIsEmptyString(self.groupInfo.group)) {
        NSLog(@"修改群信息的groupId不能为空");
        return;
    }
    
    [[TIMGroupManager sharedInstance] deleteGroup:self.groupInfo.group succ:^{
        
        [[XOContactManager defaultManager] deleteGroup:self.groupInfo.group handler:^(BOOL result) {
            if (result) {
                NSLog(@"删除本地群成功");
            } else {
                NSLog(@"删除本地群失败");
            }
        }];
        
        if (complectionHandler) {
            complectionHandler (YES);
        }
    } fail:^(int code, NSString *msg) {
        if (complectionHandler) {
            complectionHandler (NO);
        }
    }];
}

// 退群
- (void)exitGroup:(void(^)(BOOL finish))complectionHandler
{
    if (XOIsEmptyString(self.groupInfo.group)) {
        NSLog(@"修改群信息的groupId不能为空");
        return;
    }
    
    [[TIMGroupManager sharedInstance] quitGroup:self.groupInfo.group succ:^{
        
        [[XOContactManager defaultManager] deleteGroup:self.groupInfo.group handler:^(BOOL result) {
            if (result) {
                NSLog(@"删除本地群成功");
            } else {
                NSLog(@"删除本地群失败");
            }
        }];
        
        if (complectionHandler) {
            complectionHandler (YES);
        }
    } fail:^(int code, NSString *msg) {
        if (complectionHandler) {
            complectionHandler (NO);
        }
    }];
}

// 转让群主
- (void)changeGroupToNewOwner:(NSString *)ownerId complection:(void(^)(BOOL finish))complectionHandler
{
    if (XOIsEmptyString(self.groupInfo.group)) {
        NSLog(@"转让群主的groupId不能为空");
        return;
    }
    if (XOIsEmptyString(ownerId)) {
        NSLog(@"转让群主的oldGroupOwner不能为空");
        return;
    }
    
    [[TIMGroupManager sharedInstance] modifyGroupOwner:self.groupInfo.group user:ownerId succ:^{
        if (complectionHandler) {
            complectionHandler (YES);
        }
    } fail:^(int code, NSString *msg) {
        if (complectionHandler) {
            complectionHandler (NO);
        }
    }];
}


@end







@interface GroupMemberSwitchCell ()

@property (nonatomic, strong) UISwitch           * switchBtn;

@end

@implementation GroupMemberSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        _isLocked = NO;
        
        if (!_switchBtn) {
            _switchBtn = [[UISwitch alloc] init];
            [_switchBtn addTarget:self action:@selector(switchOn:) forControlEvents:UIControlEventValueChanged];
            _switchBtn.onTintColor = AppTinColor;
            [self.contentView addSubview:_switchBtn];
        }
    }
    return self;
}

- (void)setOn:(BOOL)on
{
    [self.switchBtn setOn:on animated:NO];
}

- (void)switchOn:(UISwitch *)sender
{
    if (self.switchClick) {
        self.switchClick(sender.on);
    }
    
    if (sender.isOn) {
        _switchBtn.tintColor = AppTinColor;
    } else {
        _switchBtn.tintColor = [UIColor lightGrayColor];
    }
}

- (void)setIsLocked:(BOOL)isLocked
{
    _isLocked = isLocked;
    
    if (isLocked) {
        self.switchBtn.enabled = NO;
    } else {
        self.switchBtn.enabled = YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.switchBtn.center = CGPointMake(self.width - self.switchBtn.width/2 - 10, self.height/2);
    [self.contentView bringSubviewToFront:self.switchBtn];
}


@end






@interface GroupMemberSettingTailCell ()

@property (nonatomic, strong) UILabel             *titleLabel;

@end

@implementation GroupMemberSettingTailCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        [self.contentView addSubview:self.titleLabel];
    }
    return self;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _titleLabel.textColor = RGBOF(0xFF4081);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    _titleLabel.text = title;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _titleLabel.frame = CGRectMake(20, (self.contentView.height - 20)/2, self.contentView.width - 20, 20);
}


@end






#import <SDWebImage/UIImageView+WebCache.h>

@interface GroupMemberSettingIconCell ()

@property (nonatomic, strong) UIImageView             *iconImageView;
@property (nonatomic, strong) UIImageView             *operationImageView;
@property (nonatomic, strong) UILabel                 *nameLabel;

@end

@implementation GroupMemberSettingIconCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _showAdd = NO;
        _showDel = NO;
        [self.contentView addSubview:self.iconImageView];
        [self.contentView addSubview:self.operationImageView];
        [self.contentView addSubview:self.nameLabel];
    }
    return self;
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        _iconImageView.clipsToBounds = YES;
        [_iconImageView setImage:[UIImage imageNamed:@"default_avatar"]];
    }
    return _iconImageView;
}

- (UIImageView *)operationImageView
{
    if (!_operationImageView) {
        _operationImageView = [[UIImageView alloc] init];
        _operationImageView.contentMode = UIViewContentModeScaleAspectFit;
        _operationImageView.hidden = YES;
        _operationImageView.clipsToBounds = YES;
    }
    return _operationImageView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:10];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nameLabel;
}

- (void)setProfile:(TIMUserProfile *)profile
{
    _profile = profile;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (profile) {
            [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:profile.faceURL] placeholderImage:[UIImage xo_imageNamedFromChatBundle:@"default_avatar"]];
            self.nameLabel.text = profile.nickname;
        }
        else {
            self.nameLabel.text = @"";
            self.iconImageView.image = [UIImage xo_imageNamedFromChatBundle:@"default_avatar"];
        }
    }];
}

- (void)setShowAdd:(BOOL)showAdd
{
    _showAdd = showAdd;
    if (showAdd) {
        self.operationImageView.hidden = NO;
        self.iconImageView.hidden = YES;
        self.nameLabel.hidden = YES;
        [self.operationImageView setImage:[UIImage xo_imageNamedFromChatBundle:@"groupMember_add"]];
    } else {
        self.operationImageView.hidden = YES;
        self.iconImageView.hidden = NO;
        self.nameLabel.hidden = NO;
        [self.operationImageView setImage:nil];
    }
}

- (void)setShowDel:(BOOL)showDel
{
    _showDel = showDel;
    if (showDel) {
        self.operationImageView.hidden = NO;
        self.iconImageView.hidden = YES;
        self.nameLabel.hidden = YES;
        [self.operationImageView setImage:[UIImage xo_imageNamedFromChatBundle:@"groupMember_remove"]];
    } else {
        self.operationImageView.hidden = YES;
        self.iconImageView.hidden = NO;
        self.nameLabel.hidden = NO;
        [self.operationImageView setImage:nil];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.iconImageView.frame = CGRectMake(0, 0, self.width, self.width);
    self.iconImageView.layer.cornerRadius = 6.0f;
    self.operationImageView.frame = CGRectMake(0, 0, self.width, self.width);
    self.operationImageView.layer.cornerRadius = 5.0f;
    self.operationImageView.layer.borderColor = [UIColor grayColor].CGColor;
    self.operationImageView.layer.borderWidth = 1.0f;
    self.operationImageView.layer.cornerRadius = 5.0f;
    self.nameLabel.frame = CGRectMake(0, self.width + 5, self.width, self.height - self.width - 5);
}

@end
