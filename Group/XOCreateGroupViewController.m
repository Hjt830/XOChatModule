//
//  XOCreateGroupViewController.m
//  xxoogo
//
//  Created by 鼎一  on 2019/5/22.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import "XOCreateGroupViewController.h"
#import "MemberTableViewCell.h"
#import "NewPersonInfoViewController.h"
#import "GroupSelectMemberViewController.h"


static NSString * const MemberTableViewCellID = @"MemberTableViewCellID"
static NSString * const GroupMemberIconCellID = @"GroupMemberIconCellID";

@interface XOCreateGroupViewController ()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
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
    self.title = NSLocalizedString(@"live.Group.chat", nil);
    
    [self setupSubView];
    
    [self layoutSubviewsFrame];
    
    if (GroupMemberType_Remove == self.memberType) {
        [self sortRemoveListWithArray:self.groupMembers];   // 移出群成员时排序
    }
}

- (void)setupSubView
{
    [self. self.headView addSubview:self.collectionView];
    [self. self.headView addSubview:self.searchbar];
    [self.view addSubview:self. self.headView];
    [self.view addSubview:self.tableView];
}

#pragma mark ========================= touch event =========================

- (void)sureClick
{
    [self.view endEditing:YES];
    
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
        
        NSDictionary *dic = [self sortObjectsAccordingToInitialWith:groupMemberList SortKey:@"sortKey"];
        @synchronized (self) {
            [self.groupData removeAllObjects];
            [self.groupChatData removeAllObjects];
            [self.groupData  addObjectsFromArray:dic[@"Group"]];
            [self.groupChatData addObjectsFromArray:dic[@"GroupChar"]];
            [self.tableView reloadData];
        }
    }
}

#pragma mark ========================= API =========================

// 创建群
- (void)createGroup
{
    // 创建群最少要3人，也就是除自己外最少要选择2个人
    if (self.addData.count <= 1) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"live.choose.people", nil)];
        [SVProgressHUD dismissWithDelay:1.2f];
        return;
    }
    
    [[TIMGroupManager sharedInstance] createPrivateGroup:@[] groupName:@"" succ:^(NSString *groupId) {
        
        
        
    } fail:^(int code, NSString *msg) {
        
    }];
    
    
    NSMutableArray *muarr = [NSMutableArray arrayWithArray:self.addData];
    for (FansBean *bean in muarr) {
        if ([bean.memId isEqualToString:[XOUserInfoManager shareManager].memId]) {
            [muarr removeObject:bean];
        }
    }
    NSMutableArray *mutablearr = [[NSMutableArray alloc]init];
    if (muarr.count > 0) {
        NSString *string;
        for (NSInteger i = 0; i<self.addData.count; i++) {
            FansBean *bean = self.addData[i];
            NSString *str = bean.memId;
            if (0 == i) {
                string = str;
            }else{
                string = [string stringByAppendingString:[NSString stringWithFormat:@",%@",str]];
            }
            [mutablearr addObject:str];
        }
        
        sureBtn.enabled = NO;
        
        [SVProgressHUD dismiss];
        [SVProgressHUD showWithStatus:NSLocalizedString(@"live.load", nil)];
        
        if (XOIsEmptyArray(mutablearr)) {
            NSLog(@"创建群失败，memberIds不能为空");
            return;
        }
        NSDictionary *param = @{@"memerIds":mutablearr};
        [DYRequest requestWithURLStr:@"/friend/charGroup/createPrivateGroup" params:param HaveArrOrNo:YES Finish:^(id result) {
            sureBtn.enabled = YES;
            [SVProgressHUD dismiss];
            ResponseBean *response = [ResponseBean modeWithDictionary:result];
            if (XOHttpSuccessCode == response.code) {

                [[GroupManager shareManager] addGroup:response.data complection:^(BOOL finish, NSError * _Nonnull error) {

                    __block NSString *groupId = response.data[@"groupId"];
                    [[TIMManager sharedInstance].groupManager getGroupList:^(NSArray *arr) {

                        [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            TIMGroupInfo *info = (TIMGroupInfo *)obj;
                            if (!XOIsEmptyString(info.group) && !XOIsEmptyString(groupId) && [info.group isEqualToString:groupId]) {
                                IMAGroup *group = [[IMAGroup alloc] initWithInfo:info];
                                // 跳转聊天页面
                                CustomChatUIViewController *vc = [[CustomChatUIViewController alloc] initWith:group];
                                [[BaseAppDelegate sharedAppDelegate] pushViewController:vc];
                                *stop = YES;
                                // 发送自定义消息
                                [self sendCreateGroupMessage:group];
                            }
                        }];

                    } fail:^(int code, NSString *msg) {

                        NSLog(@"code: %d   msg: %@", code, msg);
                    }];
                }];

            } else {
                [TopHud showNotice:response.message withTime:tipTime];
            }
        } Fail:^(NSError *error) {
            sureBtn.enabled = YES;
            [SVProgressHUD dismiss];
        }];
    }
    else {
        [UIDialogView showDialgWithText:NSLocalizedString(@"live.addmember.noempty", nil) okClick:^{}];
    }
}

// 添加群成员
- (void)addGroupMember
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(addGroupMember:selectMember:)]) {
        
        __block NSMutableArray <NSDictionary *>* mutArr = [NSMutableArray array];
        [self.addData enumerateObjectsUsingBlock:^(FansBean  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSMutableDictionary *mutdict = [NSMutableDictionary dictionary];
            if (!XOIsEmptyString(obj.memId)) {
                [mutdict setValue:obj.memId forKey:@"memId"];
            }
            if (!XOIsEmptyString(obj.realName)) {
                [mutdict setValue:obj.realName forKey:@"name"];
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
            NSDictionary *dict = [obj yy_modelToJSONObject];
            [mutArr addObject:dict];
        }];
        [self.delegate removeGroupMember:self selectMember:mutArr];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

 //  加载头视图
- (void)initHeadview
{
     self.headView = [[UIView alloc] init]; //CGRectMake(0, NavHFit, SCREENW, 54);
     self.headView.backgroundColor = kWhiteColor;
    searchbar = [[UISearchBar alloc]init];   //CGRectMake((SCREENW -290)/2, 9, 290, 36);
    searchbar.placeholder = NSLocalizedString(@"live.search.user", nil);
    searchbar.barTintColor = kWhiteColor;
    for (UIView *subview in self.searchbar.subviews) {  //更改UISearchBar的背景为透明
        for(UIView* grandSonView in subview.subviews){
            if ([grandSonView isKindOfClass:NSClassFromString(@"UISearchBarBackground")]) {
                grandSonView.alpha = 0.0f;
            }else if([grandSonView isKindOfClass:NSClassFromString(@"UISearchBarTextField")] ){
            }else{
                grandSonView.alpha = 0.0f;
            }
        }
    }
    [searchbar setSearchFieldBackgroundImage:[UIImage imageNamed:@"search_bac"] forState:UIControlStateNormal];
    //改变左边搜索图标坐标位置。后面的占位符苹果已经做好约束总是跟随在搜索🔍图标后面。
    [searchbar setPositionAdjustment:UIOffsetMake(100, 0) forSearchBarIcon:UISearchBarIconSearch];
    searchbar.delegate = self;
    [ self.headView addSubview:searchbar];
    [self.view addSubview: self.headView];
}

-(void)layoutSubviewsFrame
{
    CGFloat width = (SCREENW - 40*6)/7;
    if (self.addData.count > 0) {
        self.collectionView.frame = CGRectMake(10, 10, SCREENW-20, 60);
    }else{
        self.collectionView.frame = CGRectZero;
    }
    self.searchbar.frame = CGRectMake((SCREENW-290)/2, CGRectGetMaxY(self.collectionView.frame)+9, 290, 36);
    self. self.headView.frame = CGRectMake(0, 0, SCREENW, CGRectGetMaxY(self.collectionView.frame)+54);
    self.tableView.frame = CGRectMake(0, CGRectGetMaxY( self.headView.frame), SCREENW, SCREENH- CGRectGetMaxY( self.headView.frame) -(TabHFit -49));
    if (self.addData.count > 0) {
        [sureBtn setTitle:[NSString stringWithFormat:@"%@(%ld)", NSLocalizedString(@"live.ok", nil), (long)self.addData.count] forState:UIControlStateNormal];
    }else{
        [sureBtn setTitle:NSLocalizedString(@"live.ok", nil) forState:UIControlStateNormal];
    }
}

#pragma mark ========================= 发送创群消息 =========================

- (void)sendCreateGroupMessage:(IMAGroup *)group
{
    IMAConversation *conversation = [[IMAPlatform sharedInstance].conversationMgr chatWith:group];
    if (conversation) {
        // XML 协议的自定义消息
        NSString * xml = [[GroupManager shareManager] getCustomMessageContentWith:nil memId:nil type:CustomMsgType_CreateGroup];
        // 转换为 NSData
        NSData *data = [xml dataUsingEncoding:NSUTF8StringEncoding];
        TIMCustomElem * custom_elem = [[TIMCustomElem alloc] init];
        [custom_elem setData:data];
        TIMMessage * msg = [[TIMMessage alloc] init];
        [msg addElem:custom_elem];
        IMAMsg *imaMsg = [IMAMsg msgWith:msg];
        [conversation sendMessage:imaMsg completion:^(NSArray *imamsgList, BOOL succ, int code) {
            if (succ) {
                NSLog(@"SendMsg Succ");
            } else {
                NSLog(@"SendMsg Failed:%d", code);
            }
        }];
    }
}

#pragma mark    获取数据
-(void)getTableviewDataWithSearchStr:(NSString *)str
{
   [SVProgressHUD dismiss];
    [SVProgressHUD showWithStatus:NSLocalizedString(@"live.load", nil)];
    WEAK_SELF;
    HttpPost *http = [HttpPost getCreateGroupMembers:[XOUserInfoManager shareManager].memId size:10 page:1 name:str];
    [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        STRONG_SELF;
        [SVProgressHUD dismiss];
        [sself.tableView.mj_header endRefreshing];
        ResponseBean *response = [ResponseBean yy_modelWithJSON:request.responseJSONObject];
        NSLog(@"返回的fans结果%@",request.responseJSONObject);
        if (response.code == XOHttpSuccessCode) {
            NSArray <FansBean *>* arr = [NSArray yy_modelArrayWithClass:[FansBean class] json: response.data[@"data"]];
            __block NSMutableArray <FansBean *>* mutarr = [NSMutableArray arrayWithArray:arr];
            
            // 过滤掉已经在群中的成员
            if (GroupMemberType_Add == self.memberType) {
                if (!XOIsEmptyArray(self.existMemberIds)) {
                    [self.existMemberIds enumerateObjectsUsingBlock:^(NSString * _Nonnull memId, NSUInteger idx, BOOL * _Nonnull stop) {
                        [mutarr enumerateObjectsUsingBlock:^(FansBean * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([obj.memId isEqualToString:memId]) {
                                [mutarr removeObject:obj];
                                *stop = YES;
                            }
                        }];
                    }];
                }
            }
            
            @synchronized (self) {
                if (self.dataSource.count > 0) {
                    [self.dataSource removeAllObjects];
                }
                [self.dataSource addObjectsFromArray:mutarr];
            }
            
            NSDictionary *dic = [self sortObjectsAccordingToInitialWith:self.dataSource SortKey:@"sortKey"];
            @synchronized (self) {
                [self.groupData removeAllObjects];
                [self.groupChatData removeAllObjects];
                [self.groupData  addObjectsFromArray:dic[@"Group"]];
                [self.groupChatData addObjectsFromArray:dic[@"GroupChar"]];
            }
            [self.tableView reloadData];
        } else {
            STRONG_SELF;
            [UIDialogView showDialgWithText:response.message okClick:nil title:NSLocalizedString(@"live.tip", nil)
                               buttonTittle:NSLocalizedString(@"live.ok", nil)];
        }
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        STRONG_SELF;
        [SVProgressHUD dismiss];
        [MShowInfoView showInfo:@"Network connection is failed"];
        [sself.tableView.mj_header endRefreshing];
    }];
}

#pragma mark    获取更多数据
-(void)getTableviewDataWithPage:(NSInteger)pag SearchStr:(NSString *)str{
   [SVProgressHUD dismiss];
    [SVProgressHUD showWithStatus:NSLocalizedString(@"live.load", nil)];
    WEAK_SELF;
    HttpPost *http = [HttpPost getCreateGroupMembers:[XOUserInfoManager shareManager].memId size:10 page:pag name:str];
    [http startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        STRONG_SELF;
        [SVProgressHUD dismiss];
        ResponseBean *response = [ResponseBean yy_modelWithJSON:request.responseJSONObject];
        NSInteger total = [request.responseJSONObject[@"data"][@"total"] integerValue];
        if (response.code == XOHttpSuccessCode) {
            NSArray *arr = (NSArray *)response.data;
            if (arr.count > 0) {
                NSArray *arr = [NSArray yy_modelArrayWithClass:[FansBean class] json:response.data[@"data"]];
                __block NSMutableArray <FansBean *>* mutarr = [NSMutableArray arrayWithArray:arr];
                
                // 过滤掉已经在群中的成员
                if (GroupMemberType_Add == self.memberType) {
                    if (!XOIsEmptyArray(self.existMemberIds)) {
                        [self.existMemberIds enumerateObjectsUsingBlock:^(NSString * _Nonnull memId, NSUInteger idx, BOOL * _Nonnull stop) {
                            [mutarr enumerateObjectsUsingBlock:^(FansBean * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ([obj.memId isEqualToString:memId]) {
                                    [mutarr removeObject:obj];
                                    *stop = YES;
                                }
                            }];
                        }];
                    }
                }
                
                @synchronized (self) {
                    [self.dataSource addObjectsFromArray:mutarr];
                }
                
                if (self.dataSource.count >= total) {
                    [self.tableView.mj_footer endRefreshingWithNoMoreData];
                }
                
                NSDictionary *dic = [self sortObjectsAccordingToInitialWith:self.dataSource SortKey:@"sortKey"];
                @synchronized (self) {
                    [self.groupData removeAllObjects];
                    [self.groupChatData removeAllObjects];
                    if (arr.count < 10) {
                        [self.groupData  addObjectsFromArray:dic[@"Group"]];
                        [self.groupChatData addObjectsFromArray:dic[@"GroupChar"]];
                        [self.tableView.mj_footer endRefreshingWithNoMoreData];
                    } else {
                        [self.groupData  addObjectsFromArray:dic[@"Group"]];
                        [self.groupChatData addObjectsFromArray:dic[@"GroupChar"]];
                    }
                }
                [self.tableView reloadData];
            } else {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
        } else {
            STRONG_SELF;
            [UIDialogView showDialgWithText:response.message okClick:nil title:NSLocalizedString(@"live.tip", nil)
                               buttonTittle:NSLocalizedString(@"live.ok", nil)];
        }
        [self.tableView.mj_footer endRefreshing];
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        STRONG_SELF;
        [SVProgressHUD dismiss];
        [MShowInfoView showInfo:@"Network connection is failed"];
        [self.tableView.mj_footer endRefreshing];
    }];
}


#pragma mark ========================= UITableViewDataSource & UITableViewDelegate =========================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.groupChatData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *arr = self.groupData[section];
    return arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MemberTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MemberTableViewCell" forIndexPath:indexPath];
    
    // 创建群 | 添加群成员
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType) {
        FansBean *bean = self.groupData[indexPath.section][indexPath.row];
        BOOL contain = NO;
        for (FansBean *bean1  in self.addData) {
            if ([bean1.memId isEqualToString:bean.memId]) {
                contain = YES;
                break;
            }
        }
        if (contain) {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }else{
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        [cell giveSubviewValueWithData:bean];
    }
    // 踢出群成员
    else if (GroupMemberType_Remove == self.memberType) {
        GroupMemberInfoModel *model = self.groupData[indexPath.section][indexPath.row];
        BOOL contain = NO;
        for (GroupMemberInfoModel *info in self.addData) {
            NSString *dictMemId = model.memId;
            NSString *memId = info.memId;
            if (!XOIsEmptyString(memId) && !XOIsEmptyString(dictMemId) && [memId isEqualToString:dictMemId]) {
                contain = YES;
                break;
            }
        }
        if (contain) {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }else{
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        cell.memberInfo = model;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType) {
        if (100 == self.addData.count) {
            [UIDialogView showDialgWithText:NSLocalizedString(@"live.addgroup.more", nil) okClick:^{
            }];
            return;
        }
        FansBean *bean = self.groupData[indexPath.section][indexPath.row];
        BOOL contain = NO;
        for (FansBean *bean1  in self.addData) {
            if ([bean1.memId isEqualToString:bean.memId]) {
                contain = YES;
                break;
            }
        }
        if (!contain) {
            [self.addData addObject:bean];
            [self layoutSubviewsFrame];
            [self.collectionView reloadData];
            [self refreshRightBBIStatus];
        }
    }
    else if (GroupMemberType_Remove == self.memberType) {
        GroupMemberInfoModel *model = self.groupData[indexPath.section][indexPath.row];
        NSString *dictMemId = model.memId;
        BOOL contain = NO;
        for (GroupMemberInfoModel *info  in self.addData) {
            NSString *memId = info.memId;
            if (!XOIsEmptyString(memId) && !XOIsEmptyString(dictMemId) && [memId isEqualToString:dictMemId]) {
                contain = YES;
                break;
            }
        }
        
        if (!contain) {
            [self.addData addObject:model];
            [self layoutSubviewsFrame];
            [self.collectionView reloadData];
            [self refreshRightBBIStatus];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType) {
        //取消选择时删除对应数据
        FansBean *bean = self.groupData[indexPath.section][indexPath.row];
        BOOL contain = NO;
        for (FansBean *bean1  in self.addData) {
            if ([bean1.memId isEqualToString:bean.memId]) {
                contain = YES;
                break;
            }
        }
        if (contain) {
            [self.addData removeObject:bean];
            [self layoutSubviewsFrame];
            [self.collectionView reloadData];
            [self refreshRightBBIStatus];
            
        }
    }
    else if (GroupMemberType_Remove == self.memberType) {
        GroupMemberInfoModel *model = self.groupData[indexPath.section][indexPath.row];
        NSString *dictMemId = model.memId;
        BOOL contain = NO;
        for (GroupMemberInfoModel *info  in self.addData) {
            NSString *memId = info.memId;
            if (!XOIsEmptyString(memId) && !XOIsEmptyString(dictMemId) && [memId isEqualToString:dictMemId]) {
                contain = YES;
                break;
            }
        }
        
        if (contain) {
            [self.addData removeObject:model];
            [self layoutSubviewsFrame];
            [self.collectionView reloadData];
            [self refreshRightBBIStatus];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREENW, 60)];
        label.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:247.0/255.0 alpha:1.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = kBlackColor;
    //    NSInteger asc = 65 + section;
    //    int asciicode = (int)asc;
        
        label.text = [NSString stringWithFormat:@"   %@",self.groupChatData[section]];
        return label;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 20;
}

- (void)scrollViewiewWillBeginDragging:(UIscrollViewiew *)scrollViewiew{
    [self.view endEditing:YES];
}

//显示每组标题索引
-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    NSMutableArray *muarr = [NSMutableArray arrayWithObject:UITableViewIndexSearch];  //添加搜索标识
    for (NSString *str in self.groupChatData) {
        [muarr addObject:str];
    }
    return muarr;
}

//返回每个索引的内容
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return self.groupChatData[section];
}

//响应点击索引时的委托方法
-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index{
    //这里是为了指定索引index对应的是哪个section的，默认的话直接返回index就好。其他需要定制的就针对性处理
    if ([title isEqualToString:UITableViewIndexSearch]){
        [tableView setContentOffset:CGPointZero animated:NO];//tabview移至顶部
        return NSNotFound;
    }else{  // -1 添加了搜索标识
        return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index] - 1;
    }
}

//当前选中组
- (void)selectedSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    for (UIView *view in [tableView subviews]) { //UITableViewIndex
        if ([view isKindOfClass:[NSClassFromString(@"UITableViewIndex") class]]) {
            // 设置字体大小
            [view setValue:[UIFont systemFontOfSize:13] forKey:@"_font"];
            //设置view的大小
            view.bounds = CGRectMake(0, 0, 30, 30);
            //单单设置其中一个是无效的
        }
    }

}

-(NSMutableArray *)groupData{
    if (!_groupdata) {
        _groupdata = [[NSMutableArray alloc]init];
    }
    return _groupdata;
}

-(NSMutableArray *)groupChatData{
    if (!_groupchardata) {
        _groupchardata = [[NSMutableArray alloc]init];
    }
    return _groupchardata;
}

- (NSMutableArray *)addData{
    if (!_adddata) {
        _adddata = [[NSMutableArray alloc]init];
    }
    return _adddata;
}

- (NSMutableArray <FansBean *>*)dataSource{
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc]init];
    }
    return _dataSource;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if ([searchbar isFirstResponder]) {
        [searchbar resignFirstResponder];
    }
}

// 按首字母分组排序数组
-(NSDictionary *)sortObjectsAccordingToInitialWith:(NSArray *)willSortArr SortKey:(NSString *)sortkey {
    // 初始化UILocalizedIndexedCollation
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    //得出collation索引的数量，这里是27个（26个字母和1个#）
    NSInteger sectionTitlesCount = [[collation sectionTitles] count];
    //初始化一个数组newSectionsArray用来存放最终的数据，我们最终要得到的数据模型应该形如@[@[以A开头的数据数组], @[以B开头的数据数组], @[以C开头的数据数组], ... @[以#(其它)开头的数据数组]]
    NSMutableArray *newSectionsArray = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    
    //初始化27个空数组加入newSectionsArray
    for (NSInteger index = 0; index < sectionTitlesCount; index++) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [newSectionsArray addObject:array];
    }
    
    NSMutableArray *firstChar = [NSMutableArray arrayWithCapacity:10]; //initWithCapacity:10 并不代表里面的object数量不能大于10.也可以大于10.
    //将每个名字分到某个section下
    
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType) {
        for (FansBean *bean in willSortArr) {
            //获取name属性的值所在的位置，比如"林丹"，首字母是L，在A~Z中排第11（第一位是0），sectionNumber就为11
            NSInteger sectionNumber = [collation sectionForObject:bean collationStringSelector:NSSelectorFromString(sortkey)];
            //把name为“林丹”的p加入newSectionsArray中的第11个数组中去
            NSMutableArray *sectionNames = newSectionsArray[sectionNumber];
            [sectionNames addObject:bean];
            
            //拿出每名字的首字母
            NSString * str= collation.sectionTitles[sectionNumber];
            [firstChar addObject:str];
        }
    }
    else if (GroupMemberType_Remove == self.memberType) {
        for (GroupMemberInfoModel *infoModel in willSortArr) {
            //获取name属性的值所在的位置，比如"林丹"，首字母是L，在A~Z中排第11（第一位是0），sectionNumber就为11
            NSInteger sectionNumber = [collation sectionForObject:infoModel collationStringSelector:NSSelectorFromString(sortkey)];
            //把name为“林丹”的p加入newSectionsArray中的第11个数组中去
            __block NSMutableArray *sectionNames = newSectionsArray[sectionNumber];
            [self.groupMembers enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *memId = obj[@"memId"];
                if (!XOIsEmptyString(memId) && [infoModel.memId isEqualToString:memId]) {
                    [sectionNames addObject:infoModel];
                }
            }];
            //拿出每名字的首字母
            NSString * str= collation.sectionTitles[sectionNumber];
            [firstChar addObject:str];
        }
    }
    
    //返回首字母排好序的数据
    NSArray *firstCharResult = [self SortFirstChar:firstChar];
    
    //对每个section中的数组按照name属性排序
    for (NSInteger index = 0; index < sectionTitlesCount; index++) {
        NSMutableArray *personArrayForSection = newSectionsArray[index];
        if (!XOIsEmptyArray(personArrayForSection)) {
            NSArray *sortedPersonArrayForSection = [collation sortedArrayFromArray:personArrayForSection collationStringSelector:NSSelectorFromString(sortkey)];
            newSectionsArray[index] = sortedPersonArrayForSection;
        }
    }
    
    //删除空的数组
    NSMutableArray *finalArr = [NSMutableArray new];
    for (NSInteger index = 0; index < sectionTitlesCount; index++) {
        if (((NSMutableArray *)(newSectionsArray[index])).count != 0) {
            [finalArr addObject:newSectionsArray[index]];
        }
    }
    
    NSLog(@"排序结果：%@**** %@",finalArr,firstCharResult);
    return @{@"Group":finalArr,@"GroupChar":firstCharResult};
}

-(NSArray *)SortFirstChar:(NSArray *)firstChararry{
    //数组去重复
    NSMutableArray *noRepeat = [[NSMutableArray alloc]initWithCapacity:8];
    NSMutableSet *set = [[NSMutableSet alloc]initWithArray:firstChararry];
    
    [set enumerateObjectsUsingBlock:^(id obj , BOOL *stop){
        [noRepeat addObject:obj];
    }];
    
    //字母排序
    NSArray *resultkArrSort1 = [noRepeat sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    //把”#“放在最后一位
    NSMutableArray *resultkArrSort2 = [[NSMutableArray alloc]initWithArray:resultkArrSort1];
    if ([resultkArrSort2 containsObject:@"#"]) {
        
        [resultkArrSort2 removeObject:@"#"];
        [resultkArrSort2 addObject:@"#"];
    }
    return resultkArrSort2;
}

#pragma mark UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.addData.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    GroupMemberIconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GroupMemberIconCell" forIndexPath:indexPath];
    
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType) {
        FansBean *baen = self.addData[indexPath.item];
        cell.imageUrl = baen.picture;
    } else if (GroupMemberType_Remove == self.memberType) {
        GroupMemberInfoModel *model = self.addData[indexPath.item];
        cell.imageUrl = model.picture;
    }
    
    return  cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self.addData removeObjectAtIndex:indexPath.item];
    [self.collectionView reloadData];
    [self.tableView reloadData];
    [self layoutSubviewsFrame];
}

#pragma mark UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{  //dia
    
    // 创建群 | 添加群成员
    if (GroupMemberType_Create == self.memberType || GroupMemberType_Add == self.memberType) {
        __block CreateGroupViewController *pre = self;
        page = 1;
        self.tableView.mj_header = [MJRefreshHeader headerWithRefreshingBlock:^{
            page = 1;
            [pre getTableviewDataWithSearchStr:searchbar.text];
            [pre.tableView.mj_footer resetNoMoreData];
        }];
        [self.tableView.mj_header beginRefreshing];
        self.tableView.mj_footer = [MJRefreshAutoFooter footerWithRefreshingBlock:^{
            page += 1;
            [pre getTableviewDataWithPage:page SearchStr:searchbar.text];
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
                if ([realName containsString:keyword Options:NSCaseInsensitiveSearch]) {
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
        CGFloat height = CGRectGetMaxY( self.headView.frame);
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.allowsMultipleSelection = YES;
        _tableView.sectionIndexColor = [UIColor lightTextColor]; //设置默认时索引值颜色
        _tableView.sectionIndexTrackingBackgroundColor = AppTinColor; //设置选中时，索引背景颜色
        _tableView.sectionIndexBackgroundColor = [UIColor clearColor]; // 设置默认时，索引的背景颜色
        
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
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[GroupMemberIconCell class] forCellWithReuseIdentifier:GroupMemberIconCellID];
    }
    return _collectionView;
}

- (UIView *) self.headView
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
        _searchbar.placeholder = NSLocalizedString(@"live.search.user", nil);
        _searchbar.barTintColor = [UIColor whiteColor];
        _searchbar.tintColor = [UIColor lightGrayColor];
        for (UIView *subview in _searchbar.subviews) {  //更改UISearchBar的背景为透明
            for(UIView* grandSonView in subview.subviews){
                if ([grandSonView isKindOfClass:NSClassFromString(@"UISearchBarBackground")]) {
                    grandSonView.alpha = 0.0f;
                }else if([grandSonView isKindOfClass:NSClassFromString(@"UISearchBarTextField")] ){
                }else{
                    grandSonView.alpha = 0.0f;
                }
            }
        }
        [_searchbar setSearchFieldBackgroundImage:[UIImage imageNamed:@"search_bac"] forState:UIControlStateNormal];
        //改变左边搜索图标坐标位置。后面的占位符苹果已经做好约束总是跟随在搜索图标后面。
        [_searchbar setPositionAdjustment:UIOffsetMake(100, 0) forSearchBarIcon:UISearchBarIconSearch];
        _searchbar.delegate = self;
    }
    return _searchbar;
}


@end



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
