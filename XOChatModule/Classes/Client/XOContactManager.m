//
//  XOContactManager.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOContactManager.h"
#import <fmdb/FMDB.h>
#import <XOBaseLib/XOBaseLib.h>
#import <GCDMulticastDelegate/GCDMulticastDelegate.h>

static XOContactManager * __contactManager = nil;

@interface XOContactManager ()
{
    GCDMulticastDelegate    <XOContactDelegate> *_multiDelegate;
}
@property (nonatomic, retain) FMDatabaseQueue   *DBQueue;

@end

@implementation XOContactManager

+ (instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __contactManager = [[XOContactManager alloc] init];
    });
    return __contactManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _multiDelegate = [(GCDMulticastDelegate <XOContactDelegate> *)[GCDMulticastDelegate alloc] init];
        // 加载本地免打扰和置顶群
        [self loadMuteListAndToppingList];
    }
    return self;
}

- (void)dealloc
{
    [_multiDelegate removeAllDelegates];
}

#pragma mark ========================= 通讯录列表同步 =========================

// 同步好友列表
- (void)asyncFriendList
{
    // 获取好友列表
    [[TIMManager sharedInstance].friendshipManager getFriendList:^(NSArray<TIMFriend *> *friends) {
        NSLog(@"好友列表: %@", friends);
        
        [self clearContactsList:^(BOOL result) {
            NSLog(@"清空联系人列表: %d", result);
            
            [self initDataBase];
            
            [self batchInsertContact:friends handler:^(BOOL result) {
                NSLog(@"批量插入联系人: %d", result);
            }];
        }];
        
    } fail:^(int code, NSString *msg) {
        NSLog(@"查询好友列表失败: code:%d  msg:%@", code, msg);
    }];
}

// 同步群列表
- (void)asyncGroupList
{
    // 获取群列表
    [[TIMManager sharedInstance].groupManager getGroupList:^(NSArray<TIMGroupInfo *> *groups) {
        NSLog(@"查询群列表: %@", groups);
        
        [self clearGroupList:^(BOOL result) {
            NSLog(@"清空群列表: %d", result);
            
            [self initDataBase];
            
            [self batchInsertGroup:groups handler:^(BOOL result) {
                NSLog(@"批量插入群: %d", result);
            }];
        }];
        
    } fail:^(int code, NSString *msg) {
        NSLog(@"查询群列表失败: code:%d  msg:%@", code, msg);
    }];
}

#pragma mark ========================= TIMFriendshipListener =========================
/**
 *  添加好友通知
 *
 *  @param users 好友列表（NSString*）
 */
- (void)onAddFriends:(NSArray*)users
{
    NSLog(@"添加好友通知: %@", users);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnAddFriends:)]) {
        [_multiDelegate xoOnAddFriends:users];
    }
}

/**
 *  删除好友通知
 *
 *  @param identifiers 用户id列表（NSString*）
 */
- (void)onDelFriends:(NSArray*)identifiers
{
    NSLog(@"删除好友通知: %@", identifiers);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnDelFriends:)]) {
        [_multiDelegate xoOnDelFriends:identifiers];
    }
}

/**
 *  好友资料更新通知
 *
 *  @param profiles 资料列表（TIMSNSChangeInfo *）
 */
- (void)onFriendProfileUpdate:(NSArray<TIMSNSChangeInfo *> *)profiles
{
    NSLog(@"好友资料更新通知: %@", profiles);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnFriendProfileUpdate:)]) {
        [_multiDelegate xoOnFriendProfileUpdate:profiles];
    }
}

/**
 *  好友申请通知
 *
 *  @param reqs 好友申请者id列表（TIMFriendPendencyInfo *）
 */
- (void)onAddFriendReqs:(NSArray<TIMFriendPendencyInfo *> *)reqs
{
    NSLog(@"好友申请通知: %@", reqs);
    if (_multiDelegate.count > 0 && [_multiDelegate hasDelegateThatRespondsToSelector:@selector(xoOnAddFriendReqs:)]) {
        [_multiDelegate xoOnAddFriendReqs:reqs];
    }
}

#pragma mark ========================= 添加|删除代理 =========================

- (void)addDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (delegate != nil) {
        // 判断是否已经添加同一个类的对象作为代理
        if (delegateQueue == nil || delegateQueue == NULL) {
            if ([_multiDelegate countOfClass:[delegate class]] > 0) {
                [_multiDelegate removeDelegate:delegate];
            }
            [_multiDelegate addDelegate:delegate delegateQueue:dispatch_get_main_queue()];
        } else{
            if ([_multiDelegate countOfClass:[delegate class]] > 0) {
                [_multiDelegate removeDelegate:delegate];
            }
            [_multiDelegate addDelegate:delegate delegateQueue:delegateQueue];
        }
    }
}
- (void)removeDelegate:(id <XOContactDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if ([_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegateQueue delegateQueue:delegateQueue];
    }
}
- (void)removeDelegate:(id <XOContactDelegate>)delegate
{
    if ([_multiDelegate countOfClass:[delegate class]] > 0) {
        [_multiDelegate removeDelegate:delegate delegateQueue:NULL];
    }
}


#pragma mark ========================= 免打扰 & 置顶 =========================

// 加载本地免打扰和置顶群
- (void)loadMuteListAndToppingList
{
    _muteArray = [NSArray arrayWithContentsOfURL:[self MuteListURL]];
    _toppingArray = [NSArray arrayWithContentsOfURL:[self ToppingListURL]];
}

// 是否免打扰群
- (BOOL)isMuteGroup:(NSString *)groupId
{
    return [_muteArray containsObject:groupId];
}
// 增加免打扰
- (BOOL)addMuteListWithGroupId:(NSString *)groupId
{
    if (!XOIsEmptyString(groupId)) {
        // 为空
        if (XOIsEmptyArray(_muteArray)) {
            NSMutableArray *muteList = [NSMutableArray array];
            [muteList addObject:groupId];
            if ([muteList writeToURL:[self MuteListURL] atomically:YES]) {
                _muteArray = muteList;
                NSLog(@"增加免打扰群成功: %@", groupId);
                return YES;
            }
            else {
                NSLog(@"增加免打扰群失败: %@", groupId);
                return NO;
            }
        }
        // 不为空
        else {
            NSMutableArray *muteList = [_muteArray mutableCopy];
            [muteList addObject:groupId];
            if ([muteList writeToURL:[self MuteListURL] atomically:YES]) {
                _muteArray = muteList;
                NSLog(@"增加免打扰群成功: %@", groupId);
                return YES;
            }
            else {
                NSLog(@"增加免打扰群失败: %@", groupId);
                return NO;
            }
        }
    }
    return NO;
}

// 删除免打扰
- (BOOL)removeMuteListWithGroupId:(NSString *)groupId
{
    if (!XOIsEmptyString(groupId)) {
        // 为空
        if (XOIsEmptyArray(_muteArray)) {
            return YES;
        }
        // 不为空
        else {
            if (![_muteArray containsObject:groupId]) {
                return YES;
            }
            else {
                NSMutableArray *muteList = [_muteArray mutableCopy];
                [muteList removeObject:groupId];
                if ([muteList writeToURL:[self MuteListURL] atomically:YES]) {
                    _muteArray = muteList;
                    NSLog(@"删除免打扰群成功: %@", groupId);
                    return YES;
                }
                else {
                    NSLog(@"删除免打扰群失败: %@", groupId);
                    return NO;
                }
            }
        }
    }
    return NO;
}

// 是否置顶了联系人
- (BOOL)isToppingReceiver:(NSString *)groupId
{
    return [_toppingArray containsObject:groupId];
}

// 增加置顶
- (BOOL)addToppingListWithReceiverId:(NSString *)receiverId
{
    if (!XOIsEmptyString(receiverId)) {
        // 为空
        if (XOIsEmptyArray(_toppingArray)) {
            NSMutableArray *toppingList = [NSMutableArray array];
            [toppingList addObject:receiverId];
            if ([toppingList writeToURL:[self ToppingListURL] atomically:YES]) {
                _toppingArray = toppingList;
                NSLog(@"增加置顶成功: %@", receiverId);
                return YES;
            }
            else {
                NSLog(@"增加置顶失败: %@", receiverId);
                return NO;
            }
        }
        // 不为空
        else {
            NSMutableArray *toppingList = [_toppingArray mutableCopy];
            [toppingList addObject:receiverId];
            if ([toppingList writeToURL:[self ToppingListURL] atomically:YES]) {
                _toppingArray = toppingList;
                NSLog(@"增加置顶成功: %@", receiverId);
                return YES;
            }
            else {
                NSLog(@"增加置顶失败: %@", receiverId);
                return NO;
            }
        }
    }
    return NO;
}

// 删除置顶
- (BOOL)removeToppingListWithReceiverId:(NSString *)receiverId
{
    if (!XOIsEmptyString(receiverId)) {
        // 为空
        if (XOIsEmptyArray(_toppingArray)) {
            return YES;
        }
        // 不为空
        else {
            if (![_toppingArray containsObject:receiverId]) {
                return YES;
            }
            else {
                NSMutableArray *toppingList = [_toppingArray mutableCopy];
                [toppingList removeObject:receiverId];
                if ([toppingList writeToURL:[self ToppingListURL] atomically:YES]) {
                    _toppingArray = toppingList;
                    NSLog(@"删除置顶成功: %@", receiverId);
                    return YES;
                }
                else {
                    NSLog(@"删除置顶失败: %@", receiverId);
                    return NO;
                }
            }
        }
    }
    return NO;
}

- (NSURL *)MuteListURL
{
    NSString *path = [XOUserSettingDirectory() stringByAppendingPathComponent:@"muteGroupList.plist"];
    return [NSURL fileURLWithPath:path];
}

- (NSURL *)ToppingListURL
{
    NSString *path = [XOUserSettingDirectory() stringByAppendingPathComponent:@"toppingGroupList.plist"];
    return [NSURL fileURLWithPath:path];
}

@end









// 联系人数据库名
NSString * const ContactDBName      = @"xocontact.sqlite";
// 联系人表名
XOTableName const ContactTableName   = @"t_contact";
// 联系人信息表名
XOTableName const ContactProfileTableName    = @"t_contactProfile";
// 群列表名
XOTableName const GroupTableName     = @"t_group";

// 创建联系人表
FOUNDATION_EXTERN_INLINE NSString * CreateContactTableSql() {
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (identifier text PRIMARY KEY, remark text, addWording text, addSource text, addTime integer); create index contactIndex on %@ (identifier)", ContactTableName, ContactTableName];
}

// 创建联系人信息表
FOUNDATION_EXTERN_INLINE NSString * CreateContactProfileTableSql() {
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (identifier text PRIMARY KEY, nickname text, allowType integer, faceURL text, selfSignature text, gender integer, birthday integer, language integer, level integer, role integer); create index contactProfileIndex on %@ (identifier)", ContactProfileTableName, ContactProfileTableName];
}

// 创建群列表
FOUNDATION_EXTERN_INLINE NSString * CreateGroupTableSql() {
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (groupId text PRIMARY KEY, groupName text, owner text, groupType text, createTime integer, lastInfoTime integer, lastMsgTime integer, maxMemberNum integer, memberNum integer, addOpt integer, notification integer, introduction text, faceURL text, onlineMemberNum integer, isSearchable integer, isMemberVisible integer, allShutup int); create index groupIndex on %@ (groupId)", GroupTableName, GroupTableName];
}

// 插入联系人SQL
FOUNDATION_EXTERN_INLINE NSString * InsertContactSql(TIMFriend *friend) {
    return [NSString stringWithFormat:@"INSERT INTO %@ (identifier, remark, addWording, addSource, addTime) VALUES ('%@', '%@', '%@', '%@', %llu)", ContactTableName, friend.identifier, friend.remark, friend.addWording, friend.addSource, (unsigned long long)friend.addTime];
}

// 插入联系人信息SQL
FOUNDATION_EXTERN_INLINE NSString * InsertContactProfileSql(TIMUserProfile *profile) {
    NSString *signature = profile.selfSignature.length < 4 ? nil : [[NSString alloc] initWithData:profile.selfSignature encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"INSERT INTO %@ (identifier, nickname, allowType, faceURL, selfSignature, gender, birthday, language, level, role) VALUES ('%@', '%@', %ld, '%@', '%@', %ld, %u, %u, %u, %u)", ContactProfileTableName, profile.identifier, profile.nickname, profile.allowType, profile.faceURL, signature, profile.gender, profile.birthday, (unsigned int)profile.language, (unsigned int)profile.level, (unsigned int)profile.role];
}

// 插入群SQL
FOUNDATION_EXTERN_INLINE NSString * InsertGroupSql(TIMGroupInfo *group) {
    return [NSString stringWithFormat:@"INSERT INTO %@ (groupId, groupName, owner, groupType, createTime, lastInfoTime, lastMsgTime, maxMemberNum, memberNum, addOpt, notification, introduction, faceURL, onlineMemberNum, isSearchable, isMemberVisible, allShutup) VALUES ('%@', '%@', '%@', '%@', %u, %u, %u, %u, %u, %ld, '%@', '%@', '%@', %u, %ld, %ld, %d)", GroupTableName, group.group, group.groupName, group.owner, group.groupType, (unsigned int)group.createTime, (unsigned int)group.lastInfoTime, (unsigned int)group.lastMsgTime, (unsigned int)group.maxMemberNum, (unsigned int)group.memberNum, group.addOpt, group.notification, group.introduction, group.faceURL, (unsigned int)group.onlineMemberNum, group.isSearchable, group.isMemberVisible, group.allShutup];
}

// 更新联系人SQL
FOUNDATION_EXTERN_INLINE NSString * UpdateContactSql(TIMFriend *friend) {
    return [NSString stringWithFormat:@"UPDATE %@ SET identifier = %@, remark = '%@', addWording = '%@', addSource = '%@', addTime = %llu", ContactTableName, friend.identifier, friend.remark, friend.addWording, friend.addSource, (unsigned long long)friend.addTime];
}

// 更新联系人信息SQL
FOUNDATION_EXTERN_INLINE NSString * UpdateContactProfileSql(TIMUserProfile *profile) {
    NSString *signature = profile.selfSignature.length < 4 ? nil : [[NSString alloc] initWithData:profile.selfSignature encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"UPDATE %@ SET identifier = '%@', nickname = '%@', allowType = %ld, faceURL = '%@', selfSignature = '%@', gender = %ld, birthday = %u, language = %u, level = %u, role = %u", ContactProfileTableName, profile.identifier, profile.nickname, profile.allowType, profile.faceURL, signature, (long)profile.gender, (unsigned int)profile.birthday, (unsigned int)profile.language, (unsigned int)profile.level, (unsigned int)profile.role];
}

// 更新群SQL
FOUNDATION_EXTERN_INLINE NSString * UpdateGroupSql(TIMGroupInfo *group) {
    return [NSString stringWithFormat:@"UPDATE %@ SET groupId = '%@', groupName = '%@', owner = '%@', groupType = '%@', createTime = %u, lastInfoTime = %u, lastMsgTime = %u, maxMemberNum = %u, memberNum = %u, addOpt = %ld, notification = '%@', introduction = '%@', faceURL = '%@', onlineMemberNum = %u, isSearchable = %ld, isMemberVisible = %ld, allShutup = %d", GroupTableName, group.group, group.groupName, group.owner, group.groupType, (unsigned int)group.createTime, (unsigned int)group.lastInfoTime, (unsigned int)group.lastMsgTime, (unsigned int)group.maxMemberNum, (unsigned int)group.memberNum, group.addOpt, group.notification, group.introduction, group.faceURL, (unsigned int)group.onlineMemberNum, group.isSearchable, group.isMemberVisible, group.allShutup];
}


@implementation XOContactManager (Database)

#pragma mark mark - ===================== 新建 数据库 | 表 =====================

// 数据库地址
- (NSString *)databasePath
{
    NSString *directory = [[[DocumentDirectory() stringByAppendingPathComponent:@"message"] stringByAppendingPathComponent:CurrentUserPath()] stringByAppendingPathComponent:@"Contact"];
    // 判断路径是否存在
    BOOL isDir = FALSE;
    BOOL isDirExist = [XOFM fileExistsAtPath:directory isDirectory:&isDir];
    if (!(isDirExist && isDir)) {
        // 不存在则创建路径
        BOOL result = [XOFM createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        if (!result){
            NSLog(@"创建联系人数据库目录失败!!!!!");
        }
    }
    NSString *dbPath = [directory stringByAppendingPathComponent:ContactDBName];
    return dbPath;
}

/**
 *  @brief 创建数据库
 *  @return 创建结果  (-1: 表示创建失败  0: 表示创建成功  1: 表示已经存在，无需创建)
 */
- (int)initDataBase
{
    NSString *dbPath = [self databasePath];  // 数据库路径
    // 判断数据库是否存在
    BOOL dbExist = [XOFM fileExistsAtPath:dbPath isDirectory:NULL];
    if (dbExist) {
        NSLog(@"数据库已经存在, 不需要新建");
        
        // 连接数据库
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        if (!queue) {
            NSLog(@"连接数据库失败");
            return -1;
        }
        else {
            NSLog(@"连接数据库成功");
            self.DBQueue = queue;
            [self initTables];
            return 1;
        }
    }
    else {
        // 创建数据库
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        if (!queue) {
            NSLog(@"新建数据库失败");
            return -1;
        }
        else {
            NSLog(@"新建数据库成功");
            self.DBQueue = queue;
            [self initTables];
            
            return 0;
        }
    }
}

/**
 *  @brief 创建表
 */
- (void)initTables
{
    [self initTableWith:ContactTableName handler:nil];
    [self initTableWith:ContactProfileTableName handler:nil];
    [self initTableWith:GroupTableName handler:nil];
}


/**
 * @brief 创建表
 * @param name          表名
 * @param complection   回调  result:建表结果 (-1: 表示创建失败  0: 表示创建成功  1: 表示已经存在，无需创建)  error:建表失败原因
 */
- (void)initTableWith:(XOTableName)name handler:(void(^_Nullable)(int result, NSError * _Nullable error))complection
{
    if (XOIsEmptyString(name)) {
        NSLog(@"%s  表名不能为空", __func__);
        NSError *error = [NSError errorWithDomain:@"表名不能为空" code:0 userInfo:nil];
        if (complection) complection (-1, error);
    }
    else {
        [self.DBQueue inDatabase:^(FMDatabase *db) {
            
            if ([db tableExists:name]) {
                NSLog(@"%s  %@ 已经存在", __func__, name);
                if (complection) {
                    NSError *error = [NSError errorWithDomain:@"表已经存在" code:0 userInfo:nil];
                    complection (1, error);
                }
            }
            else {
                NSString *createSQL = nil;
                if ([name isEqualToString:ContactTableName]) createSQL = CreateContactTableSql();
                else if ([name isEqualToString:ContactProfileTableName]) createSQL = CreateContactProfileTableSql();
                else if ([name isEqualToString:GroupTableName]) createSQL = CreateGroupTableSql();
                
                BOOL res = [db executeStatements:createSQL];
                if (res) {
                    NSLog(@"%s  %@ 创建成功", __func__, name);
                    if (complection) complection (0, nil);
                }
                else {
                    NSLog(@"%s  %@ 创建失败", __func__, name);
                    if (complection) {
                        NSError *error = [NSError errorWithDomain:@"表创建失败" code:0 userInfo:nil];
                        complection (-1, error);
                    }
                }
            }
        }];
    }
}

#pragma mark ========================= 查询 =========================

#pragma mark 查询
/**
 * @brief 查询联系人信息
 */
- (void)getContactProfile:(NSString *)identifier handler:(void(^ _Nullable)(TIMUserProfile * _Nullable profile))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE identifier = '%@'", ContactProfileTableName, identifier];
        FMResultSet * rs = [db executeQuery:sql];
        
        // 遍历结果集
        if (rs.columnCount > 0) {
            BOOL contain = NO;
            while ([rs next]) {
                TIMUserProfile *profile = [[TIMUserProfile alloc] init];
                profile.identifier  = [rs stringForColumn:@"identifier"];
                profile.nickname    = [rs stringForColumn:@"nickname"];
                profile.allowType   = [rs longForColumn:@"allowType"];
                profile.faceURL     = [rs stringForColumn:@"faceURL"];
                profile.selfSignature = [[rs stringForColumn:@"selfSignature"] dataUsingEncoding:NSUTF8StringEncoding];
                profile.gender      = [rs longForColumn:@"gender"];
                profile.birthday    = [rs intForColumn:@"birthday"];
                profile.language    = [rs intForColumn:@"language"];
                profile.level       = [rs intForColumn:@"level"];
                profile.role        = [rs intForColumn:@"role"];
                
                contain = YES;
                if (complection) complection (profile);
                break;
            }
            
            if (!contain) {
                if (complection) complection (nil);
            }
        }
        else {
            if (complection) complection (nil);
        }
    }];
}

/**
 * @brief 查询所有的联系人
 */
- (void)getAllContactsList:(void(^ _Nullable)(NSArray <TIMFriend *> * _Nullable friendList))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        NSMutableArray <TIMFriend *> *mutArr = [NSMutableArray arrayWithCapacity:0];
        NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@", ContactTableName];
        FMResultSet * rs = [db executeQuery:sql];
        
        // 遍历结果集
        while ([rs next]) {
            TIMFriend *friend = [[TIMFriend alloc] init];
            friend.identifier   = [rs stringForColumn:@"identifier"];
            friend.remark       = [rs stringForColumn:@"remark"];
            friend.addWording   = [rs stringForColumn:@"addWording"];
            friend.addSource    = [rs stringForColumn:@"addSource"];
            friend.addTime      = [rs unsignedLongLongIntForColumn:@"addTime"];
            
            // 查询指定联系人信息
            NSString * profileSql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE identifier = '%@'", ContactProfileTableName, friend.identifier];
            FMResultSet * profileRS = [db executeQuery:profileSql];
            TIMUserProfile *profile = [[TIMUserProfile alloc] init];
            // 遍历结果集
            while ([profileRS next]) {
                profile.identifier  = [profileRS stringForColumn:@"identifier"];
                profile.nickname    = [profileRS stringForColumn:@"nickname"];
                profile.allowType   = [profileRS longForColumn:@"allowType"];
                profile.faceURL     = [profileRS stringForColumn:@"faceURL"];
                profile.selfSignature = [[profileRS stringForColumn:@"selfSignature"] dataUsingEncoding:NSUTF8StringEncoding];
                profile.gender      = [profileRS longForColumn:@"gender"];
                profile.birthday    = [profileRS intForColumn:@"birthday"];
                profile.language    = [profileRS intForColumn:@"language"];
                profile.level       = [profileRS intForColumn:@"level"];
                profile.role        = [profileRS intForColumn:@"role"];
                break;
            }
            friend.profile = profile;
            
            [mutArr addObject:friend];
        }
        
        if (complection) {
            complection (mutArr);
        }
    }];
}

/**
 * @brief 查询群信息
 */
- (void)getGroupInfo:(NSString *)groupId handler:(void(^ _Nullable)(TIMGroupInfo * _Nullable groupInfo))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE groupId = '%@'", GroupTableName, groupId];
        FMResultSet * rs = [db executeQuery:sql];
        
        // 遍历结果集
        if (rs.columnCount > 0) {
            BOOL contain = NO;
            while ([rs next]) {
                TIMGroupInfo *group = [[TIMGroupInfo alloc] init];
                group.group             = [rs stringForColumn:@"groupId"];
                group.groupName         = [rs stringForColumn:@"groupName"];
                group.owner             = [rs stringForColumn:@"owner"];
                group.groupType         = [rs stringForColumn:@"groupType"];
                group.createTime        = [rs intForColumn:@"createTime"];
                group.lastInfoTime      = [rs intForColumn:@"lastInfoTime"];
                group.lastMsgTime       = [rs intForColumn:@"lastMsgTime"];
                group.maxMemberNum      = [rs intForColumn:@"maxMemberNum"];
                group.memberNum         = [rs intForColumn:@"memberNum"];
                group.addOpt            = [rs intForColumn:@"addOpt"];
                group.notification      = [rs stringForColumn:@"notification"];
                group.introduction      = [rs stringForColumn:@"introduction"];
                group.faceURL           = [rs stringForColumn:@"faceURL"];
                group.onlineMemberNum   = [rs intForColumn:@"onlineMemberNum"];
                group.isSearchable      = [rs intForColumn:@"isSearchable"];
                group.isMemberVisible   = [rs intForColumn:@"isMemberVisible"];
                group.allShutup         = [rs intForColumn:@"allShutup"];
                
                contain = YES;
                if (complection) complection (group);
                break;
            }
            
            if (!contain) {
                if (complection) complection (nil);
            }
        }
        else {
            if (complection) complection (nil);
        }
    }];
}

/**
 * @brief 查询所有的群
 */
- (void)getAllGroupsList:(void(^ _Nullable)(NSArray <TIMGroupInfo *> * _Nullable groupList))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        NSMutableArray <TIMGroupInfo *> *mutArr = [NSMutableArray arrayWithCapacity:0];
        NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@", GroupTableName];
        FMResultSet * rs = [db executeQuery:sql];
        
        // 遍历结果集
        while ([rs next]) {
            TIMGroupInfo *group = [[TIMGroupInfo alloc] init];
            group.group             = [rs stringForColumn:@"groupId"];
            group.groupName         = [rs stringForColumn:@"groupName"];
            group.owner             = [rs stringForColumn:@"owner"];
            group.groupType         = [rs stringForColumn:@"groupType"];
            group.createTime        = [rs intForColumn:@"createTime"];
            group.lastInfoTime      = [rs intForColumn:@"lastInfoTime"];
            group.lastMsgTime       = [rs intForColumn:@"lastMsgTime"];
            group.maxMemberNum      = [rs intForColumn:@"maxMemberNum"];
            group.memberNum         = [rs intForColumn:@"memberNum"];
            group.addOpt            = [rs intForColumn:@"addOpt"];
            group.notification      = [rs stringForColumn:@"notification"];
            group.introduction      = [rs stringForColumn:@"introduction"];
            group.faceURL           = [rs stringForColumn:@"faceURL"];
            group.onlineMemberNum   = [rs intForColumn:@"onlineMemberNum"];
            group.isSearchable      = [rs intForColumn:@"isSearchable"];
            group.isMemberVisible   = [rs intForColumn:@"isMemberVisible"];
            group.allShutup         = [rs intForColumn:@"allShutup"];
            
            [mutArr addObject:group];
        }
        
        if (complection) {
            complection (mutArr);
        }
    }];
}

#pragma mark 增加

// 插入联系人
- (void)insertContact:(TIMFriend * _Nonnull)friend handler:(void(^ _Nullable)(BOOL result))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        BOOL isFriendExist = NO;
        NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE identifier = '%@'", ContactProfileTableName, friend.identifier];
        FMResultSet * rs = [db executeQuery:sql];
        while (rs) {
            isFriendExist = YES;
            break;
        }
        
        // 存在就先删除联系人
        if (isFriendExist) {
            // 删除联系人
            NSString *deleteContactSql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE identifier = '%@'", ContactTableName, friend.identifier];
            if (![db executeUpdate:deleteContactSql]) {
                NSLog(@"删除联系人失败  id: %@  remark: %@", friend.identifier, friend.profile.nickname);
            }
            // 删除联系人信息
            NSString *deleteContactProfileSql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE identifier = '%@'", ContactProfileTableName, friend.identifier];
            if(![db executeUpdate:deleteContactProfileSql]) {
                NSLog(@"删除联系人信息失败  id: %@  remark: %@", friend.identifier, friend.profile.nickname);
            }
        }
        
        // 插入联系人
        BOOL result1 = [db executeUpdate:InsertContactSql(friend)];
        BOOL result2 = [db executeUpdate:InsertContactProfileSql(friend.profile)];
        
        if (!result1 || !result2) {
            NSLog(@"插入联系人失败: id: %@   nickname: %@", friend.profile.identifier, friend.profile.nickname);
            if (complection) complection (NO);
        }
        else {
            NSLog(@"插入联系人成功: id: %@   nickname: %@", friend.profile.identifier, friend.profile.nickname);
            if (complection) complection (YES);
        }
    }];
}

// 批量插入联系人
- (void)batchInsertContact:(NSArray <TIMFriend *>* _Nonnull)friendList handler:(void(^ _Nullable)(BOOL result))complection
{
    // 开启事务
    [self.DBQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        
        @try {
            for (int i = 0; i < friendList.count; i++) {
                TIMFriend *friend = friendList[i];
                
                BOOL isFriendExist = NO;
                NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE identifier = '%@'", ContactProfileTableName, friend.identifier];
                FMResultSet * rs = [db executeQuery:sql];
                while (rs) {
                    isFriendExist = YES;
                    break;
                }
                
                // 存在就先删除联系人
                if (isFriendExist) {
                    // 删除联系人
                    NSString *deleteContactSql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE identifier = '%@'", ContactTableName, friend.identifier];
                    if (![db executeUpdate:deleteContactSql]) {
                        NSLog(@"删除联系人失败  id: %@  remark: %@", friend.identifier, friend.profile.nickname);
                    }
                    // 删除联系人信息
                    NSString *deleteContactProfileSql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE identifier = '%@'", ContactProfileTableName, friend.identifier];
                    if(![db executeUpdate:deleteContactProfileSql]) {
                        NSLog(@"删除联系人信息失败  id: %@  remark: %@", friend.identifier, friend.profile.nickname);
                    }
                }
                
                // 插入联系人
                NSString *sql1 = InsertContactSql(friend);
                NSString *sql2 = InsertContactProfileSql(friend.profile);
                BOOL result1 = [db executeUpdate:sql1];
                BOOL result2 = [db executeUpdate:sql2];
                
                if (!result1 || !result2) {
                    NSLog(@"插入联系人失败: id: %@   nickname: %@", friend.profile.identifier, friend.profile.nickname);
                } else {
                    NSLog(@"插入联系人成功: id: %@   nickname: %@", friend.profile.identifier, friend.profile.nickname);
                }
            }
            if (complection) complection (YES);
            
        } @catch (NSException *exception) {
            
            NSLog(@"exception: %@", exception);
            [db rollback];
            if (complection) complection (NO);
            
        } @finally {
            [db commit];
            [db close];
        }
    }];
}

// 插入群
- (void)insertGroup:(TIMGroupInfo * _Nonnull)group handler:(void(^ _Nullable)(BOOL result))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        BOOL isGroupExist = NO;
        NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE groupId = '%@'", GroupTableName, group.group];
        FMResultSet * rs = [db executeQuery:sql];
        while (rs) {
            isGroupExist = YES;
            break;
        }
        
        // 存在就先删除群
        if (isGroupExist) {
            // 删除群
            NSString *deleteGroupSql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE groupId = '%@'", GroupTableName, group.group];
            if (![db executeUpdate:deleteGroupSql]) {
                NSLog(@"删除群失败  id: %@  remark: %@", group.group, group.groupName);
            }
        }
        // 插入群
        BOOL result = [db executeUpdate:InsertGroupSql(group)];
        if (!result) {
            NSLog(@"插入群失败: id: %@   nickname: %@", group.group, group.groupName);
            if (complection) complection (NO);
        } else {
            NSLog(@"插入群成功: id: %@   nickname: %@", group.group, group.groupName);
            if (complection) complection (YES);
        }
    }];
}

// 批量插入群
- (void)batchInsertGroup:(NSArray <TIMGroupInfo *> * _Nonnull)groupsList handler:(void(^ _Nullable)(BOOL result))complection
{
    // 开启事务
    [self.DBQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        
        @try {
            for (int i = 0; i < groupsList.count; i++) {
                TIMGroupInfo *group = groupsList[i];
                
                BOOL isGroupExist = NO;
                NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE groupId = '%@'", GroupTableName, group.group];
                FMResultSet * rs = [db executeQuery:sql];
                while (rs) {
                    isGroupExist = YES;
                    break;
                }
                
                // 存在就先删除群
                if (isGroupExist) {
                    // 删除群
                    NSString *deleteGroupSql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE groupId = '%@'", GroupTableName, group.group];
                    if (![db executeUpdate:deleteGroupSql]) {
                        NSLog(@"删除群失败  id: %@  remark: %@", group.group, group.groupName);
                    }
                }
                // 插入群
                NSString *groupSQL = InsertGroupSql(group);
                BOOL result = [db executeUpdate:groupSQL];
                if (!result) {
                    NSLog(@"插入群失败: id: %@   nickname: %@", group.group, group.groupName);
                    *rollback = YES;
                } else {
                   NSLog(@"插入群成功: id: %@   nickname: %@", group.group, group.groupName);
               }
            }
            if (complection) complection (YES);
            
        } @catch (NSException *exception) {
            
            NSLog(@"exception: %@", exception);
            [db rollback];
            if (complection) complection (NO);
            
        } @finally {
            [db commit];
            [db close];
        }
    }];
}

#pragma mark 删除

// 清空联系人表和联系人信息表
- (void)clearContactsList:(void(^ _Nullable)(BOOL result))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        BOOL result1 = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@", ContactTableName]];
        BOOL result2 = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@", ContactProfileTableName]];
        if (result1 && result2) {
            if (complection) complection (YES);
        } else {
            if (complection) complection (NO);
        }
    }];
}

// 清空群表
- (void)clearGroupList:(void(^ _Nullable)(BOOL result))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        BOOL result = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@", GroupTableName]];
        if (result) {
            if (complection) complection (YES);
        } else {
            if (complection) complection (NO);
        }
    }];
}

// 删除联系人
- (void)deleteContact:(NSString * _Nonnull)userId handler:(void(^ _Nullable)(BOOL result))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        NSString *sql1 = [NSString stringWithFormat:@"DELETE FROM %@ WHERE identifier = '%@'", ContactTableName, userId];
        NSString *sql2 = [NSString stringWithFormat:@"DELETE FROM %@ WHERE identifier = '%@'", ContactProfileTableName, userId];
        BOOL result1 = [db executeUpdate:sql1];
        BOOL result2 = [db executeUpdate:sql2];
        
        if (result1 && result2) {
            if (complection) complection (YES);
        } else {
            if (complection) complection (NO);
        }
    }];
}

// 删除群
- (void)deleteGroup:(NSString * _Nonnull)groupId handler:(void(^ _Nullable)(BOOL result))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE groupId = '%@'", GroupTableName, groupId];
        BOOL result = [db executeUpdate:sql];
        
        if (result) {
            if (complection) complection (YES);
        } else {
            if (complection) complection (NO);
        }
    }];
}

#pragma mark 更新

// 更新联系人
- (void)updateContact:(TIMFriend *)friend handler:(void(^ _Nullable)(BOOL result))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        BOOL result = [db executeUpdate:UpdateContactSql(friend)];
        if (result) {
            if (complection) complection (YES);
        } else {
            if (complection) complection (NO);
        }
    }];
}

// 更新联系人信息
- (void)updateContactProfile:(TIMUserProfile *)profile handler:(void(^ _Nullable)(BOOL result))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        BOOL result = [db executeUpdate:UpdateContactProfileSql(profile)];
        if (result) {
            if (complection) complection (YES);
        } else {
            if (complection) complection (NO);
        }
    }];
}

// 更新群
- (void)updateGroup:(TIMGroupInfo *)group handler:(void(^ _Nullable)(BOOL result))complection
{
    [self.DBQueue inDatabase:^(FMDatabase *db) {
        
        BOOL result = [db executeUpdate:UpdateGroupSql(group)];
        if (result) {
            if (complection) complection (YES);
        } else {
            if (complection) complection (NO);
        }
        [db close];
    }];
}


@end
