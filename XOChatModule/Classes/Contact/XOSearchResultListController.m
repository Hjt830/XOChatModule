//
//  XOSearchResultListController.m
//  XOChatModule
//
//  Created by kenter on 2019/10/11.
//

#import "XOSearchResultListController.h"
#import "XOContactListViewController.h"

static NSString *SearchContactCellID = @"SearchContactCellID";  // 联系人cell

@interface XOSearchResultListController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView                   *tableView;  // 搜索结果列表
@property (nonatomic, strong) NSMutableArray    <NSArray *> *dataSource; // 数据源

@end

@implementation XOSearchResultListController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = BG_TableColor;
    
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
        if ([object isKindOfClass:[TIMFriend class]]) title = @"联系人";
        // 群组
        else if ([object isKindOfClass:[TIMGroupInfo class]]) title = @"群聊";
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
    NSString *keyword = [searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (XOIsEmptyString(keyword)) {
        return;
    }
    
    [self.dataSource removeAllObjects];
    keyword = [NSString stringWithFormat:@"%@", [keyword pinyinString]];
    
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
//    keyword = [NSString stringWithFormat:@"*%@*", keyword];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nick LIKE %@ OR nickPinyin LIKE %@ OR remark LIKE %@ or remarkPinyin LIKE %@", keyword, keyword, keyword, keyword];
//    [[XOContactCoreDataStorage getInstance] getContactListAsyncWith:predicate result:^(BOOL finish, NSArray<XOContact *> * _Nullable contactList) {
//        if (self.dataSource.count > 0) {
//            [self.dataSource insertObject:contactList atIndex:0];
//        } else {
//            [self.dataSource addObject:contactList];
//        }
//        [self.tableView reloadData];
//    }];
}

// 搜索群组
- (void)searchGroupWith:(NSString *)keyword
{
//    keyword = [NSString stringWithFormat:@"*%@*", keyword];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupName LIKE %@ OR groupNamePinyin LIKE %@", keyword, keyword, keyword];
//    [[XOGroupCoreDataStorage getInstance] getGroupListAsyncWith:predicate result:^(BOOL finish, NSArray<XOContact *> * _Nullable groupList) {
//        if (self.dataSource.count > 0) {
//            [self.dataSource insertObject:groupList atIndex:1];
//        } else {
//            [self.dataSource addObject:groupList];
//        }
//        [self.tableView reloadData];
//    }];
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
