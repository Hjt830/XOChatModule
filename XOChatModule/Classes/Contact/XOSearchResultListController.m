//
//  XOSearchResultListController.m
//  XOChatModule
//
//  Created by kenter on 2019/10/11.
//

#import "XOSearchResultListController.h"
#import "XOContactListViewController.h"
#import "XOChatClient.h"
#import "NSBundle+ChatModule.h"

static NSString *SearchContactCellID = @"SearchContactCellID";  // 联系人cell

@interface XOSearchResultListController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView                         *tableView;  // 搜索结果列表
@property (nonatomic, strong) NSMutableArray          <NSArray *> *dataSource; // 数据源
@property (nonatomic, strong) NSMutableArray        <TIMFriend *> *contactList; // 数据源
@property (nonatomic, strong) NSMutableArray     <TIMGroupInfo *> *groupList; // 数据源

@end

@implementation XOSearchResultListController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewColor];
    
    [self.view addSubview:self.tableView];
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorInset = UIEdgeInsetsMake(0, 10, 0, 20);
        _tableView.separatorColor = RGBA(230, 230, 230, 1);
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.rowHeight = 60.f;
        _tableView.sectionHeaderHeight = 30.0f;
        _tableView.sectionFooterHeight = 0.0f;
        
        [_tableView registerClass:[XOContactListCell class] forCellReuseIdentifier:SearchContactCellID];
//        [tableView registerClass:[XOGroupListCell class] forCellReuseIdentifier:SearchGroupCellID];
//        [tableView registerClass:[XOConversationListCell class] forCellReuseIdentifier:SearchConversationCellID];
    }
    return _tableView;
}

- (NSMutableArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (NSMutableArray <TIMFriend *>*)contactList
{
    if (!_contactList) {
        _contactList = [NSMutableArray array];
    }
    return _contactList;
}

- (NSMutableArray<TIMGroupInfo *> *)groupList
{
    if (!_groupList) {
        _groupList = [NSMutableArray array];
    }
    return _groupList;
}

#pragma mark ====================== UITableViewDataSource =======================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = self.dataSource[indexPath.section][indexPath.row];
    // 联系人
    if ([object isKindOfClass:[TIMFriend class]]) {
        XOContactListCell *cell = [tableView dequeueReusableCellWithIdentifier:SearchContactCellID forIndexPath:indexPath];
        TIMFriend *contact = (TIMFriend *)object;
        cell.contact = contact;
        if (!XOIsEmptyString(contact.remark) && !XOIsEmptyString(contact.profile.nickname)) {
            cell.detailTextLabel.text = contact.profile.nickname;
        }
        return cell;
    }
    // 群组
    else if ([object isKindOfClass:[TIMGroupInfo class]]) {
        XOContactListCell *cell = [tableView dequeueReusableCellWithIdentifier:SearchContactCellID forIndexPath:indexPath];
        TIMGroupInfo *group = (TIMGroupInfo *)object;
        cell.group = group;
        return cell;
    }
    
    return [tableView dequeueReusableCellWithIdentifier:SearchContactCellID forIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    NSArray *array = self.dataSource[section];
    if (!XOIsEmptyArray(array)) {
        id object = array[0];
        if ([object isKindOfClass:[TIMFriend class]]) title = XOChatLocalizedString(@"contact.friend");
        // 群组
        else if ([object isKindOfClass:[TIMGroupInfo class]]) title = XOChatLocalizedString(@"contact.group");
    }
    return title;
}

#pragma mark ====================== UITableViewDelegate =======================

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(XOSearchList:didSelectContact:)]) {
        id object = self.dataSource[indexPath.section][indexPath.row];
        [self.delegate XOSearchList:self didSelectContact:object];
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *keyword = searchController.searchBar.text;
    if (XOIsEmptyString(keyword)) {
        return;
    }
    
    [self.dataSource removeAllObjects];
    
    // 联系人页面搜索（可查联系人,群组）
    if (XOSearchTypeContact == self.searchType) {
        [self searchContactWith:keyword];
        [self searchGroupWith:keyword];
    }
    // 群组页面搜索 (只查群组)
    else if (XOSearchTypeGroup == self.searchType) {
        [self searchGroupWith:keyword];
    }
    // 加好友页面搜索 (只显示手机通讯录)
    else if (XOSearchTypeAddFriend == self.searchType) {
        [self searchAddressBookWith:keyword];
    }
    // 会话页面搜索 （可查联系人,群组,会话）
    else if (XOSearchTypeConversation == self.searchType) {
        [self searchContactWith:keyword];
        [self searchGroupWith:keyword];
        [self searchConversationWith:keyword];
    }
    // 个人名片搜索 (只查联系人)
    else if (XOSearchTypeCarte == self.searchType) {
        [self searchContactWith:keyword];
    }
}

// 搜索好友
- (void)searchContactWith:(NSString *)keyword
{
    [[XOChatClient shareClient].contactManager getContactWithKeyword:keyword handler:^(NSArray<TIMFriend *> * _Nullable contactList) {
        
        @synchronized (self.contactList) {
            if (!XOIsEmptyArray(self.contactList)) {
                [self.contactList removeAllObjects];
            }
            [self.contactList addObjectsFromArray:contactList];
            if (![self.dataSource containsObject:self.contactList]) {
                [self.dataSource addObject:self.contactList];
            }
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    }];
}

// 搜索群组
- (void)searchGroupWith:(NSString *)keyword
{
    [[XOChatClient shareClient].contactManager getGroupWithKeyword:keyword handler:^(NSArray<TIMGroupInfo *> * _Nullable groupList) {
        @synchronized (self.dataSource) {
            if (!XOIsEmptyArray(self.groupList)) {
                [self.groupList removeAllObjects];
            }
            [self.groupList addObjectsFromArray:groupList];
            if (![self.dataSource containsObject:self.groupList]) {
                [self.dataSource addObject:self.groupList];
            }
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    }];
}

// 搜索会话
- (void)searchConversationWith:(NSString *)keyword
{
//    NSArray <HTMessage *>* msgList = [HTMessage MR_findAllInContext:[XOMsgCoreDataManager shareManager].bgMOC];
//    NSMutableArray *chatterList = @[].mutableCopy;
//    [msgList enumerateObjectsUsingBlock:^(HTMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        HTMessage *message = [obj AES_decryptHTMessage];
//        NSString *msgContent = message.body.content;
//        NSString *chatter = message.isSender ? message.to : message.from;
//        XOContact *contact = [[XOContactCoreDataStorage getInstance] getContactWith:chatter];
//        if (!XOIsEmptyString(msgContent) && [msgContent containsString:keyword] && ![chatterList containsObject:chatter]) {
//            [chatterList addObject:chatter];
//        }
//        else if (([contact.remark containsString:keyword] || [contact.nick containsString:keyword]) && ![chatterList containsObject:chatter]) {
//            [chatterList addObject:chatter];
//        }
//    }];
//
//    if (!XOIsEmptyArray(chatterList)) {
//        NSMutableArray *conversationList = @[].mutableCopy;
//        [chatterList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatterId == %@", obj];
//            HTConversation *conversation = [HTConversation MR_findFirstWithPredicate:predicate];
//            if (conversation) {
//                [conversationList addObject:conversation];
//            }
//        }];
//        if (!XOIsEmptyArray(conversationList)) {
//            [self.dataSource addObject:conversationList];
//            [self.tableView reloadData];
//        }
//    }
}

// 搜手机通讯录
- (void)searchAddressBookWith:(NSString *)keyword
{
//    [self.dataSource addObject:addressBookList];
//    [self.tableView reloadData];
}

#pragma mark ====================== UIScrollViewDelegate =======================

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(XOSearchListDidScrollTable:)]) {
        [self.delegate XOSearchListDidScrollTable:self];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(XOSearchListDidScrollTable:)]) {
        [self.delegate XOSearchListDidScrollTable:self];
    }
}

@end
