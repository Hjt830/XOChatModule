//
//  GroupSettingInfoController.m
//  xxoogo
//
//  Created by 黄金柱 on 2019/5/24.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "GroupSettingInfoController.h"
#import "GroupInfoEditViewController.h"
#import "CreateGroupViewController.h"
#import "GroupManager.h"

#define BackgroundColor RGBA(240, 240, 240, 1.0)

static NSString * const GroupMemberSwitchCellID         = @"GroupMemberSwitchCellID";
static NSString * const GroupMemberSettingCellID        = @"GroupMemberSettingCellID";
static NSString * const GroupMemberSettingTailCellID    = @"GroupMemberSettingTailCellID";
static NSString * const GroupMemberSettingIconCellID    = @"GroupMemberSettingIconCellID";

@interface GroupSettingInfoController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, GroupInfoEditViewControllerProtocol, CreateGroupViewControllerDelegate>
{
    XOGroupInfoModel        *_groupInfoModel;
}
@property (nonatomic, assign) BOOL                      isHoster; // 是否是群主
@property (nonatomic, strong) NSArray                   *groupMembers;

@property (nonatomic, strong) UIView                    *tableHeaderView;
@property (nonatomic, strong) UIView                    *tableHeaderBackgroundView;
@property (nonatomic, strong) UIView                    *tableFooterView;
@property (nonatomic, strong) UITableView               *tableView;
@property (nonatomic, strong) UICollectionView          *collectionView;
@property (nonatomic, strong) UIButton                  *allMemberBtn;

@property (nonatomic, strong) NSArray                   *menus;

@property (nonatomic, assign) BOOL                      isShowAll;   // 是否展示了所有人
@property (nonatomic, strong) NSMutableArray            *showMembers;// 展示的群成员


@end

@implementation GroupSettingInfoController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupListInfoUpdate:) name:GroupListInfoDidUpdateNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GroupListInfoDidUpdateNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = BackgroundColor;
    self.title = [NSString stringWithFormat:NSLocalizedString(@"live.chatinfo", nil)];
    self.isShowAll = NO;
    
    [self setupSubViews];
    
    [self loadGroupMember];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self layoutSubViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)layoutSubViews
{
    UIButton *leftbut = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftbut setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [leftbut addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftbut];
    
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
    
    [self layoutSubViews];
    [self.collectionView reloadData];
}

- (void)setupSubViews
{
    [self.view addSubview:self.tableView];
    [self.tableHeaderView addSubview:self.collectionView];
    [self.tableHeaderView addSubview:self.allMemberBtn];
    self.tableView.tableHeaderView = self.tableHeaderView;
    self.tableView.tableFooterView = self.tableFooterView;
}

- (void)setGroup:(IMAGroup *)group
{
    _group = group;
    
    _isHoster = [group isCreatedByMe];
    
    if (!XOIsEmptyArray([group members])) {
        _groupMembers = [group members];
    }
    
    if (_isHoster) {
        self.menus = @[NSLocalizedString(@"live.groupnm", nil), NSLocalizedString(@"live.groupnt", nil), NSLocalizedString(@"live.Stickytop", nil), NSLocalizedString(@"live.mutenotif", nil), NSLocalizedString(@"live.deletele", nil), NSLocalizedString(@"live.Disband", nil)];
    } else {
        self.menus = @[NSLocalizedString(@"live.groupnm", nil), NSLocalizedString(@"live.groupnt", nil), NSLocalizedString(@"live.Stickytop", nil), NSLocalizedString(@"live.mutenotif", nil), NSLocalizedString(@"live.deletele", nil)];
    }
    [self.tableView reloadData];
    
    [self refreshGroupInfo];
}

- (void)refreshGroupInfo
{
    [[GroupManager shareManager] getGroupInfoModel:self.group.groupId complection:^(BOOL finish, XOGroupInfoModel * _Nullable infoModel) {
        if (finish) {
            self->_groupInfoModel = infoModel;
            if (self->_groupInfoModel) {
                [self.tableView reloadData];
            }
        }
    }];
}

#pragma mark ========================= noti =========================

- (void)groupListInfoUpdate:(NSNotification *)noti
{
    [self refreshGroupInfo];
}

#pragma mark ========================= memeber =========================

- (void)loadGroupMember
{
    if (_group && !XOIsEmptyString(_group.groupId)) {
        
#if UserNewInterFace
        
        NSDictionary *param = @{@"groupId": _group.groupId};
        [DYRequest requestWithURLStr:@"/friend/charGroup/queryMember" params:param HaveArrOrNo:NO Finish:^(id result) {
            ResponseBean *response = [ResponseBean yy_modelWithJSON:result];
            if (XOHttpSuccessCode == response.code) {
                NSArray <NSDictionary *>* list = response.data;
                self.groupMembers = list;
                
                [self initilizationMembers];
                
                self.title = [NSString stringWithFormat:NSLocalizedString(@"live.chatinfold", nil), (long)self.groupMembers.count];
            }
        } Fail:^(NSError *error) {
            NSLog(@"reques.error: %@",error);
        }];
        
#else
        
        HttpPost *http = [HttpPost getGroupMemberList:_group.groupId];
        [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
            
            ResponseBean *response = [ResponseBean yy_modelWithJSON:request.responseJSONObject];
            NSArray <NSDictionary *>* list = response.data[@"list"];
            self.groupMembers = list;
            
            [self initilizationMembers];
            
            self.title = [NSString stringWithFormat:NSLocalizedString(@"live.chatinfold", nil), (long)self.groupMembers.count];
            
        } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
            
            NSLog(@"reques.error: %@", request.error);
        }];
        
#endif
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
        _tableView.backgroundColor = BackgroundColor;
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
        _tableHeaderView.backgroundColor = BackgroundColor;
        
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
        _tableFooterView.backgroundColor = BackgroundColor;
        
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

- (NSMutableArray *)showMembers
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
        NSLog(@"退群");
    }
    // 解散群
    else {
        NSLog(@"解散群");
    }
}

- (void)goback
{
    [self.navigationController popViewControllerAnimated:YES];
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
        
        if (2 == indexPath.section) {
            if ([_groupInfoModel.topFlag boolValue]) {
                [cell setOn:YES];
            } else {
                [cell setOn:NO];
            }
        } else {
            if ([_groupInfoModel.isMute boolValue]) {
                [cell setOn:YES];
            } else {
                [cell setOn:NO];
            }
        }
        
        __weak GroupMemberSwitchCell *preCell = cell;
        cell.switchClick = ^(BOOL on) {
            if (2 == indexPath.section) {
                // 置顶 | 取消置顶
                [preCell setIsLocked:YES];
                [self topTheConversaion:on complection:^(BOOL finish, BOOL result) {
                    [preCell setIsLocked:NO];
                    if (finish) {
                        // 操作成功
                        _groupInfoModel.topFlag = @(on);
                    } else {
                        // 操作失败, 回退状态
                        [preCell setOn:!on];
                    }
                }];
            }
            else if (3 == indexPath.section) {
                // 消息免打扰
                [preCell setIsLocked:YES];
                [[GroupManager shareManager] modifyGroupMute:on withGroupId:self.group.groupId complection:^(BOOL finish, NSError * _Nonnull error) {
                    [preCell setIsLocked:NO];
                    if (finish) {
                        // 操作成功
                        _groupInfoModel.isMute = @(on);
                    } else {
                        // 操作失败, 回退状态
                        [preCell setOn:!on];
                    }
                }];
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
        if (indexPath.section == 0) {
            cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
            if (!XOIsEmptyString(_groupInfoModel.name)) {
                cell.detailTextLabel.text = _groupInfoModel.name;
            }
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = title;
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            if (self.group.isCreatedByMe) {
                GroupInfoEditViewController *editVC = [[GroupInfoEditViewController alloc] init];
                editVC.editType = GroupEditTypeName;
                editVC.groupId = self.group.groupId;
                editVC.xoGroupModel = _groupInfoModel;
                editVC.delegate = self;
                editVC.isOwner = self.group.isCreatedByMe;
                [[BaseAppDelegate sharedAppDelegate] pushViewController:editVC withBackTitle:@"back"];
            } else {
                [SVProgressHUD showWithStatus:NSLocalizedString(@"msg.groupname.editTip", nil)];
                [SVProgressHUD dismissWithDelay:0.5];
            }
        }
            break;
        case 1: {
            GroupInfoEditViewController *editVC = [[GroupInfoEditViewController alloc] init];
            editVC.editType = GroupEditTypeNotice;
            editVC.groupId = self.group.groupId;
            editVC.xoGroupModel = _groupInfoModel;
            editVC.delegate = self;
            editVC.isOwner = self.group.isCreatedByMe;
            [[BaseAppDelegate sharedAppDelegate] pushViewController:editVC withBackTitle:@"back"];
        }
            break;
            
        case 4:{  // 退群
            // 如果是群主
            if (self.group.isCreatedByMe && !XOIsEmptyArray(self.groupMembers)) {
                NSString *oldOwnerId = [XOUserInfoManager shareManager].memId;
                // 如果群成员个数只有两个, 则直接解散群
                if (self.groupMembers.count <= 2) {
                    NSString *name = [XOUserInfoManager shareManager].userInfo.realName;
                    [self sendCustomMessage:name memId:nil type:CustomMsgType_Disband handler:nil];
                    [self disbandGroup:self.group.groupId];
                }
                // 否则先转让群主, 再退群
                else {
                    NSString *newOwnerId = self.groupMembers[1][@"memId"];
                    __block NSString *name = self.groupMembers[1][@"realName"];
                    if (!XOIsEmptyString(newOwnerId)) {
                        [self changeGroupOwner:oldOwnerId toTargetGroupOwner:newOwnerId complection:^(BOOL finish) {
                            if (finish) {
                                // 发送一条自定义消息到群聊中
                                [self sendCustomMessage:name memId:nil type:CustomMsgType_ChangeOwner handler:nil];
                                // 退群
                                [self exitGroup:self.group.groupId];
                            }
                        }];
                    }
                }
            }
            // 不是群主
            else {
                [self exitGroup:self.group.groupId];
            }
        }
            break;
            
        case 5:  // 解散群
        {
            NSString *name = [XOUserInfoManager shareManager].userInfo.realName;
            [self sendCustomMessage:name memId:nil type:CustomMsgType_Disband handler:nil];
            [self disbandGroup:self.group.groupId];
        }
            break;
        default:
            break;
    }
}

// 发送自定义消息
- (void)sendCustomMessage:(NSString * _Nullable)content memId:(NSString * _Nullable)memId type:(CustomMsgType)type handler:(void(^)(void))handler
{
    IMAConversation *conversation = [[IMAPlatform sharedInstance].conversationMgr chatWith:self.group];
    if (conversation) {
        // XML 协议的自定义消息
        NSString * xml = [[GroupManager shareManager] getCustomMessageContentWith:content memId:memId type:type];
        // 转换为 NSData
        NSData *data = [xml dataUsingEncoding:NSUTF8StringEncoding];
        TIMCustomElem * custom_elem = [[TIMCustomElem alloc] init];
        [custom_elem setData:data];
        TIMMessage * msg = [[TIMMessage alloc] init];
        [msg addElem:custom_elem];
        IMAMsg *imaMsg = [IMAMsg msgWith:msg];
        [conversation sendMessage:imaMsg completion:^(NSArray *imamsgList, BOOL succ, int code) {
            if (handler) {
                handler ();
            }
            
            if (succ) {
                NSLog(@"SendMsg Succ");
            } else {
                NSLog(@"SendMsg Failed:%d", code);
            }
        }];
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
            NSDictionary *info = self.showMembers[indexPath.item];
            cell.imageUrl = info[@"picture"];
            cell.name = info[@"realName"];
        } else {
            cell.imageUrl = @"";
            cell.name = @"";
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
    // 添加群成员
    if (indexPath.item == self.showMembers.count) {
        
        __block NSMutableArray <NSString *>* arr = [NSMutableArray array];
        [self.groupMembers enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *memId = obj[@"memId"];
            if (!XOIsEmptyString(memId)) {
                [arr addObject:memId];
            }
        }];
        
        CreateGroupViewController *selectVC = [[CreateGroupViewController alloc] init];
        selectVC.memberType = GroupMemberType_Add;
        selectVC.existMemberIds = arr;
        selectVC.delegate = self;
        [[BaseAppDelegate sharedAppDelegate] pushViewController:selectVC];
    }
    // 剔除群成员
    else if (indexPath.item > self.showMembers.count) {
        __block NSMutableArray <NSDictionary *>* arr = [NSMutableArray array];
        [self.groupMembers enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *memId = obj[@"memId"];
            if (!XOIsEmptyString(memId) && ![memId isEqualToString:[XOUserInfoManager shareManager].memId]) {
                [arr addObject:obj];
            }
        }];
        
        CreateGroupViewController *selectVC = [[CreateGroupViewController alloc] init];
        selectVC.memberType = GroupMemberType_Remove;
        selectVC.groupMembers = arr;
        selectVC.delegate = self;
        [[BaseAppDelegate sharedAppDelegate] pushViewController:selectVC];
    }
}

#pragma mark ========================= GroupInfoEditViewControllerProtocol =========================

- (void)groupInfoEdit:(GroupInfoEditViewController *)editVC didEditSuccess:(NSString *)modifyText
{
    if (GroupEditTypeName == editVC.editType) {
        _groupInfoModel.name = modifyText;
        self.group.groupInfo.groupName = modifyText;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
        
        [self sendCustomMessage:modifyText memId:nil type:CustomMsgType_ModifyName handler:nil];
    }
    else if (GroupEditTypeNotice == editVC.editType) {
        _groupInfoModel.notice = modifyText;
        self.group.groupInfo.notification = modifyText;
        
        [self sendCustomMessage:modifyText memId:nil type:CustomMsgType_ModifyNotice handler:nil];
    }
}

#pragma mark ========================= CreateGroupViewControllerDelegate =========================

// 添加群成员回调
- (void)addGroupMember:(CreateGroupViewController *)groupViewController selectMember:(NSArray <NSDictionary *> *)selectMember
{
    if (!XOIsEmptyArray(selectMember)) {
        [self addGroupMembers:selectMember];
    }
}

// 剔除群成员回调
- (void)removeGroupMember:(CreateGroupViewController *)groupViewController selectMember:(NSArray<NSDictionary *> *)selectMember
{
    if (!XOIsEmptyArray(selectMember)) {
        [self removeGroupMembers:selectMember];
    }
}

#pragma mark ========================= API =========================

// 群聊置顶 | 取消置顶
- (void)topTheConversaion:(BOOL)top complection:(void(^)(BOOL finish, BOOL result))handler
{
#if UserNewInterFace
    
    if (XOIsEmptyString(self.group.groupId)) {
        NSLog(@"修改群信息的groupId不能为空");
        return;
    }
    NSDictionary *param = @{@"groupId":self.group.groupId, @"topFlag": @(0)};
    [DYRequest requestWithURLStr:@"/friend/charGroup/top" params:param HaveArrOrNo:YES Finish:^(id result) {
        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:result];
        if (XOHttpSuccessCode == reponse.code) {
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler(YES, top);
                }];
            }

            [[GroupManager shareManager] modifyGroupTop:top withGroupId:self.group.groupId complection:^(BOOL finish, NSError * _Nonnull error) {
                if (finish) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:XOMessageConversationTopNotifiation object:nil];
                }
            }];
        }
        else {
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler(NO, top);
                }];
            }

            [SVProgressHUD showWithStatus:@"top fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
    } Fail:^(NSError *error) {
        if (handler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                handler(NO, top);
            }];
        }

        [SVProgressHUD showWithStatus:@"top fail"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
#else

    HttpPost *http = [HttpPost groupToTop:self.group.groupId top:top];
    [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {

        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:request.responseObject];
        if (XOHttpSuccessCode == reponse.code) {
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler(YES, top);
                }];
            }

            [[GroupManager shareManager] modifyGroupTop:top withGroupId:self.group.groupId complection:^(BOOL finish, NSError * _Nonnull error) {
                if (finish) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:XOMessageConversationTopNotifiation object:nil];
                }
            }];
        }
        else {
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler(NO, top);
                }];
            }

            [SVProgressHUD showWithStatus:@"top fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {

        if (handler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                handler(NO, top);
            }];
        }

        [SVProgressHUD showWithStatus:@"top fail"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
#endif
}

// 解散群
- (void)disbandGroup:(NSString *)groupId
{
    if (XOIsEmptyString(groupId)) {
        NSLog(@"修改群信息的groupId不能为空");
        return;
    }
    
#if UserNewInterFace
    
    NSDictionary *param = @{@"groupId": groupId};
    [DYRequest requestWithURLStr:@"/friend/charGroup/destroyGroup" params:param HaveArrOrNo:YES Finish:^(id result) {
        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:result];
        if (XOHttpSuccessCode == reponse.code) {
            IMAConversation *conv = [[IMAPlatform sharedInstance].conversationMgr queryConversationWith:self.group];
            if (conv) {
                [[IMAPlatform sharedInstance].conversationMgr deleteConversation:conv needUIRefresh:YES];
            }
            // 删除本地群
            [[GroupManager shareManager] removeGroup:@{@"groupId": groupId}];

            [SVProgressHUD showWithStatus:@"disband group success"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        }
        else {
            [SVProgressHUD showWithStatus:@"disband group fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
    } Fail:^(NSError *error) {
        [SVProgressHUD showWithStatus:@"disband group fail"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
#else
    
    [SVProgressHUD show];
    HttpPost *http = [HttpPost disbandGroup:groupId];
    [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        
        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:request.responseObject];
        if (XOHttpSuccessCode == reponse.code) {
            
            IMAConversation *conv = [[IMAPlatform sharedInstance].conversationMgr queryConversationWith:self.group];
            if (conv) {
                [[IMAPlatform sharedInstance].conversationMgr deleteConversation:conv needUIRefresh:YES];
            }
            // 删除本地群
            [[GroupManager shareManager] removeGroup:@{@"groupId": groupId}];
            
            [[IMAPlatform sharedInstance].conversationMgr asyncConversationList];
            
            [SVProgressHUD showWithStatus:@"disband group success"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        }
        else {
            [SVProgressHUD showWithStatus:@"disband group fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }

    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {

        [SVProgressHUD showWithStatus:@"disband group fail"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
#endif
}

// 退群
- (void)exitGroup:(NSString *)groupId
{
    if (XOIsEmptyString(groupId)) {
        NSLog(@"修改群信息的groupId不能为空");
        return;
    }
    
    // 发送退群消息
//    XOUserInfoModel *infoModel = [XOUserInfoManager shareManager].userInfo;
//    [self sendCustomMessage:infoModel.realName memId:infoModel.memId type:CustomMsgType_ExitGroup  handler:^(void){
    
#if UserNewInterFace
        
        NSDictionary *param = @{@"groupId": groupId};
        [DYRequest requestWithURLStr:@"/friend/charGroup/signOut" params:param HaveArrOrNo:YES Finish:^(id result) {
            ResponseBean *reponse = [ResponseBean yy_modelWithJSON:result];
            if (XOHttpSuccessCode == reponse.code) {

                IMAConversation *conv = [[IMAPlatform sharedInstance].conversationMgr queryConversationWith:self.group];
                if (conv) {
                    [[IMAPlatform sharedInstance].conversationMgr deleteConversation:conv needUIRefresh:YES];
                }

                // 删除本地群
                [[GroupManager shareManager] removeGroup:@{@"groupId": groupId}];

                [SVProgressHUD showWithStatus:@"exit success"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                });
            }
            else {
                [SVProgressHUD showWithStatus:@"exit fail"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                });
            }
        } Fail:^(NSError *error) {
            [SVProgressHUD showWithStatus:@"exit fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }];

#else
        
        HttpPost *http = [HttpPost groupExit:groupId];
        [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {

            ResponseBean *reponse = [ResponseBean yy_modelWithJSON:request.responseObject];
            if (XOHttpSuccessCode == reponse.code) {
                IMAConversation *conv = [[IMAPlatform sharedInstance].conversationMgr queryConversationWith:self.group];
                if (conv) {
                    [[IMAPlatform sharedInstance].conversationMgr deleteConversation:conv needUIRefresh:YES];
                }
                
                [[IMAPlatform sharedInstance].conversationMgr asyncConversationList];
                
                // 删除本地群
                [[GroupManager shareManager] removeGroup:@{@"groupId": groupId}];
                
                [SVProgressHUD showWithStatus:@"exit success"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                });
            }
            else {
                [SVProgressHUD showWithStatus:@"exit fail"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                });
            }

        } failure:^(__kindof YTKBaseRequest * _Nonnull request) {

            [SVProgressHUD showWithStatus:@"exit fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }];

#endif
//    }];
}

// 转让群主
- (void)changeGroupOwner:(NSString *)oldGroupOwner toTargetGroupOwner:(NSString *)groupOwner complection:(void(^)(BOOL finish))handler
{
    if (XOIsEmptyString(self.group.groupId)) {
        NSLog(@"转让群主的groupId不能为空");
        return;
    }
    
    if (XOIsEmptyString(oldGroupOwner)) {
        NSLog(@"转让群主的oldGroupOwner不能为空");
        return;
    }
    
    if (XOIsEmptyString(groupOwner)) {
        NSLog(@"转让群主的groupOwner不能为空");
        return;
    }
    
#if UserNewInterFace
    
    NSDictionary *param = @{@"groupId":self.group.groupId, @"targetGroupOwner": groupOwner};
    [DYRequest requestWithURLStr:@"/friend/charGroup/changeGroupOwner" params:param HaveArrOrNo:YES Finish:^(id result) {
        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:result];
        if (XOHttpSuccessCode == reponse.code) {
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler (YES);
                }];
            }
        }
        else {
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler (NO);
                }];
            }

            [SVProgressHUD showWithStatus:@"transfer fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
    } Fail:^(NSError *error) {
        if (handler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                handler (NO);
            }];
        }

        [SVProgressHUD showWithStatus:@"transfer fail"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
#else
    
    HttpPost *http = [HttpPost changeGroupOwner:self.group.groupId from:oldGroupOwner toTargetGroupOwner:groupOwner];
    [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {

        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:request.responseObject];
        if (XOHttpSuccessCode == reponse.code) {
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler (YES);
                }];
            }
        }
        else {
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler (NO);
                }];
            }

            [SVProgressHUD showWithStatus:@"transfer fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }

    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {

        if (handler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                handler (NO);
            }];
        }

        [SVProgressHUD showWithStatus:@"transfer fail"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
#endif
}

// 添加群成员
- (void)addGroupMembers:(NSArray <NSDictionary *>*)addMemberIds
{
    if (XOIsEmptyArray(addMemberIds)) {
        return;
    }
    
    __block NSMutableString *names = [[NSMutableString alloc] init];
    __block NSMutableArray <NSString *>* memberIds = [NSMutableArray array];
    [addMemberIds enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *memId = obj[@"memId"];
        if (!XOIsEmptyString(memId)) {
            [memberIds addObject:memId];
        }
        NSString *name = obj[@"name"];
        if (!XOIsEmptyString(name)) {
            [names appendString:name];
            if (idx < addMemberIds.count - 1) {
                [names appendString:@","];
            }
        }
    }];
    
    if (XOIsEmptyString(self.group.groupId)) {
        NSLog(@"修改群信息的groupId不能为空");
        return;
    }
    
    if (XOIsEmptyArray(memberIds)) {
        NSLog(@"加人列表ID数组不能为空");
        return;
    }
    
#if UserNewInterFace
    
    NSDictionary *param = @{@"groupId": self.group.groupId, @"memerIds": memberIds};
    [DYRequest requestWithURLStr:@"/friend/charGroup/addMember" params:param HaveArrOrNo:YES Finish:^(id result) {
        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:result];
        if (XOHttpSuccessCode == reponse.code) {
            // 重新加载群成员
            [self loadGroupMember];

            if (!XOIsEmptyString(names)) {
                [self sendCustomMessage:names memId:nil type:CustomMsgType_AddMember handler:nil];
            }
        }
        else {
            [SVProgressHUD showWithStatus:@"add members fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
    } Fail:^(NSError *error) {
        [SVProgressHUD showWithStatus:@"add members fail"];
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             [SVProgressHUD dismiss];
        });
    }];

#else
    
    HttpPost *http = [HttpPost groupAdd:self.group.groupId members:memberIds];
    [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {

        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:request.responseJSONObject];
        if (XOHttpSuccessCode == reponse.code) {
            // 重新加载群成员
            [self loadGroupMember];

            if (!XOIsEmptyString(names)) {
                [self sendCustomMessage:names type:CustomMsgType_AddMember handler:nil];
            }

        }
        else {
            [SVProgressHUD showWithStatus:@"add members fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }

    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {

        [SVProgressHUD showWithStatus:@"add members fail"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
#endif
}

// 删除群成员
- (void)removeGroupMembers:(NSArray <NSDictionary *>*)removeMemberIds
{
    if (XOIsEmptyArray(removeMemberIds)) {
        return;
    }
    
    __block NSMutableString *names = [[NSMutableString alloc] init];
    __block NSMutableArray <NSString *>* memberIds = [NSMutableArray array];
    [removeMemberIds enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *memId = obj[@"memId"];
        if (!XOIsEmptyString(memId)) {
            [memberIds addObject:memId];
        }
        NSString *name = obj[@"realName"];
        if (!XOIsEmptyString(name)) {
            [names appendString:name];
            if (idx < removeMemberIds.count - 1) {
                [names appendString:@","];
            }
        }
    }];
    
    [removeMemberIds enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *memId = obj[@"memId"];
        NSString *name = obj[@"realName"];
        if (!XOIsEmptyString(name) && !XOIsEmptyString(memId)) {
            [self sendCustomMessage:name memId:memId type:CustomMsgType_ExitGroup handler:nil];
        }
    }];
    
#if UserNewInterFace
        
    if (XOIsEmptyString(self.group.groupId)) {
        NSLog(@"修改群信息的groupId不能为空");
        return;
    }

    if (XOIsEmptyArray(memberIds)) {
        NSLog(@"加人列表ID数组不能为空");
        return;
    }
    NSDictionary *param = @{@"groupId": self.group.groupId, @"memerIds": memberIds};
    [DYRequest requestWithURLStr:@"/friend/charGroup/delMember" params:param HaveArrOrNo:YES Finish:^(id result) {
        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:result];
        if (XOHttpSuccessCode == reponse.code) {
            // 重新加载群成员
            [self loadGroupMember];
        }
        else {
            [SVProgressHUD showWithStatus:@"remove members fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }
    } Fail:^(NSError *error) {
        [SVProgressHUD showWithStatus:@"remove members fail"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
#else
    
    HttpPost *http = [HttpPost groupKick:self.group.groupId members:memberIds];
    [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {

        ResponseBean *reponse = [ResponseBean yy_modelWithJSON:request.responseJSONObject];
        if (XOHttpSuccessCode == reponse.code) {
            // 重新加载群成员
            [self loadGroupMember];

            if (!XOIsEmptyString(names)) {
                [self sendCustomMessage:names type:CustomMsgType_ExitGroup handler:nil];
            }
        }
        else {
            [SVProgressHUD showWithStatus:@"remove members fail"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
        }

    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {

        [SVProgressHUD showWithStatus:@"remove members fail"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
#endif
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
            _switchBtn.onTintColor = mainPurpleColor;
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
        _switchBtn.tintColor = mainPurpleColor;
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
        _titleLabel.font = [UIFont systemFontOfSize:15];
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

- (void)setImageName:(NSString *)imageName
{
    _imageName = imageName;
    
    UIImage *image = [UIImage imageNamed:@"imageName"];
    if (image) {
        self.iconImageView.image = image;
    }
}

- (void)setName:(NSString *)name
{
    _name = [name copy];
    _nameLabel.text = name;
}

- (void)setImageUrl:(NSString *)imageUrl
{
    _imageUrl = imageUrl;
    
    if (!XOIsEmptyString(imageUrl)) {
        [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"default_avatar"]];
    } else {
        [self.iconImageView setImage:[UIImage imageNamed:@"default_avatar"]];
    }
}

- (void)setShowAdd:(BOOL)showAdd
{
    _showAdd = showAdd;
    if (showAdd) {
        self.operationImageView.hidden = NO;
        self.iconImageView.hidden = YES;
        self.nameLabel.hidden = YES;
        [self.operationImageView setImage:[UIImage imageNamed:@"groupMember_add"]];
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
        [self.operationImageView setImage:[UIImage imageNamed:@"groupMember_remove"]];
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
    self.nameLabel.frame = CGRectMake(0, self.width + 5, self.width, self.height - self.width - 5);
}

@end
