//
//  XOChatListViewController.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/7/5.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOChatListViewController.h"
#import "XOConversationListCell.h"

#import <ImSDK/ImSDK.h>

static NSString *ConversationCellID = @"ConversationCellID";
static NSString *ConversationHeaderFooterID = @"ConversationHeaderFooterID";

@interface XOChatListViewController ()

@property (nonatomic, strong) NSArray   <TIMConversation *>* dataSource;

@end

@implementation XOChatListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"InBox";
    
    self.dataSource = [[TIMManager sharedInstance] getConversationList];
    
    self.tableView.rowHeight = 60.0f;
    [self.tableView registerClass:[XOConversationListCell class] forCellReuseIdentifier:ConversationCellID];
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:ConversationHeaderFooterID];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[TIMManager sharedInstance] conversationCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XOConversationListCell *cell = [tableView dequeueReusableCellWithIdentifier:ConversationCellID forIndexPath:indexPath];
    
    if (self.dataSource.count > indexPath.row) {
        TIMConversation *conversation = self.dataSource[indexPath.row];
        cell.conversation = conversation;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:ConversationHeaderFooterID];
    return header;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:ConversationHeaderFooterID];
    return footer;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TIMConversation *conversation = self.dataSource[indexPath.row];
    
    
    
}


@end
