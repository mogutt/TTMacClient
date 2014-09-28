//
//  DDChattingContactListViewController.m
//  Duoduo
//
//  Created by zuoye on 14-1-9.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDChattingContactListViewController.h"
#import "ImageAndTextCell.h"
#import "DDSessionModule.h"
#import "DDMainModule.h"
#import "UserEntity.h"
#import "DDUserlistModule.h"
#import "SessionEntity.h"
#import "DDUserInfoManager.h"
#import "DDChattingContactListCell.h"
#import "DDGroupModule.h"
#import "GroupEntity.h"
#import "TcpProtocolHeader.h"
#import "DDTcpClientManager.h"
#import "DDChattingContactListModule.h"
#import "DDDeleteMemberFromGroupAPI.h"

@implementation DDChattingContactListViewController

-(id)init{
    self =[super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateContactList:) name:notificationonlineStateChange object:nil];
    }
    return self;
}

- (void)setSessionEntity:(SessionEntity *)sessionEntity
{
    if (_sessionEntity)
    {
        _sessionEntity = nil;
    }
    _sessionEntity = sessionEntity;
    self.module.session = sessionEntity;
    [self reloadContactListTableView];
    //将初始化获得群成员的在线状态
    [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
        [[StateMaintenanceManager instance] updateUsersOnlineState:_sessionEntity.groupUsers];

    }];
}

- (DDChattingContactListModule*)module
{
    if (!_module)
    {
        _module = [[DDChattingContactListModule alloc] init];
    }
    return _module;
}

-(void)awakeFromNib{
    ImageAndTextCell *celll = [[ImageAndTextCell alloc] init];
    [[self contactListColumn] setDataCell:celll];
    [self.contactListTableView setDataSource:self];
    [self.contactListTableView setTarget:self];
    [self.contactListTableView setDoubleAction:@selector(onParticipanListDoubleClicked:)];
    [self.contactListTableView setDelegate:self];
    [self.listViewTitleTextField setEditable:NO];
    [self.listViewTitleTextField setBackgroundColor:[NSColor clearColor]];
//    [self.contactListTableView setBackGroundImage:[NSImage imageNamed:@"panel_bg_theme_gray"]];

    
}

- (void)onParticipanListDoubleClicked:(id)sender{
    NSInteger clickedRow = [_contactListTableView clickedRow];
    if (clickedRow >= 0)
    {
        NSArray* groupUsers = [self.module showGroupMembers];
        UserEntity* selectUser = [groupUsers objectAtIndex:clickedRow];
        NSString *selectUserId = selectUser.userId;
        if([[[[DDUserlistModule shareInstance] myUser] userId ] isEqualToString:selectUserId]){    //点击的是自己,弹出自己的用户信息面板.
            
        }else{
            DDSessionModule* sessionModule = [DDSessionModule shareInstance];
            if (![sessionModule.recentlySessionIds containsObject:selectUserId])
            {
                [sessionModule createSingleSession:selectUserId];
                [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:nil];
            }
            [[DDMainWindowController instance] recentContactsSelectObject:selectUserId];
            [[DDMainWindowController instance] openChatViewByUserId:selectUserId];
        }
    }
}

-(void)updateContactList:(NSNotification*)notification
{
    NSDictionary* changedUserState = [notification object];
    __block BOOL change = NO;
    [[changedUserState allKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([self.module.session.groupUsers containsObject:obj])
        {
            change = YES;
            *stop = YES;
        }
    }];
    if (!change)
    {
        return;
    }
    [self reloadContactListTableView];
}

-(void)updateTitle{
    NSString *title = [NSString stringWithFormat:@"参与人(%ld/%ld)",[_sessionEntity onlineUsersInGroup],[_sessionEntity.groupUsers count]];
    [self.listViewTitleTextField setStringValue:title];
    [self setLabelAttribute:self.listViewTitleTextField];
}

-(void)setLabelAttribute:(NSTextField *)textField{
    NSMutableAttributedString *titleAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[textField attributedStringValue]];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor whiteColor]];
    [shadow setShadowOffset:NSMakeSize(1, 1)];
    NSRange fullRange = NSMakeRange(0, [[textField stringValue] length]);
    [titleAttributedString addAttribute:@"NSShadowAttributeName" value:shadow range:fullRange];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationonlineStateChange object:nil];
    [_contactListTableView setDataSource:nil];
    [_contactListTableView setDelegate:nil];
}

#pragma mark - NSSearchField
- (void)controlTextDidChange:(NSNotification *)obj
{
    [self.module searchContent:_searchField.stringValue completion:^{
        [_contactListTableView reloadData];
    }];
}

#pragma mark - NSMenu Delegate
- (void)menuWillOpen:(NSMenu *)menu
{
    DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
    NSString* myID = [userListModule myUserId];
    
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    GroupEntity* currentGroup = [groupModule getGroupByGId:self.sessionEntity.sessionId];
    //若为群主则可以移除群成员
    NSMenuItem* deleteUserMenuItem = [menu itemAtIndex:3];
    BOOL meIsGroupCreator = [myID isEqualToString:currentGroup.groupCreatorId];
    
    NSUInteger clickRow = [_contactListTableView clickedRow];
    NSArray* showGroupUsers = [self.module showGroupMembers];
    UserEntity* user = [userListModule getUserById:[showGroupUsers objectAtIndex:clickRow]];
    BOOL clickNotMe = ![user.userId isEqualToString:myID];
    
    if (clickNotMe && meIsGroupCreator)
    {
        [deleteUserMenuItem setHidden:NO];
    }
    else
    {
        [deleteUserMenuItem setHidden:YES];
    }
}

#pragma mark NSTableView Delegate mothed
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    NSArray* groupUsers = [self.module showGroupMembers];
    return [groupUsers count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 20;
}

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString* identifier = @"DDChattingContactListCellIdentifier";
    DDChattingContactListCell* cell = (DDChattingContactListCell*)[tableView makeViewWithIdentifier:identifier owner:self];
    NSArray* groupUsers = [self.module showGroupMembers];
    [cell configeWithUser:groupUsers[row]];
    return cell;
}

-(NSImage *)getOnlineStateIcon:(NSString *)userId{
    
    return nil;
}

- (IBAction)sendMsgToUsers:(id)sender {
    [self onParticipanListDoubleClicked:self];
}

- (IBAction)viewUserInfo:(id)sender
{
//    NSInteger rowNumber = [_contactListTableView selectedRow];
//    if(rowNumber < 0)
//        return;
    NSInteger clickedRow = [_contactListTableView clickedRow];
    if (clickedRow >= 0)
    {
        NSArray* groupUsers = [self.module showGroupMembers];
        UserEntity* selectedUser = [groupUsers objectAtIndex:clickedRow];
        NSString *selectUserId = selectedUser.userId;
        DDUserlistModule* userListModel = [DDUserlistModule shareInstance];
        UserEntity* showUser = [userListModel getUserById:selectUserId];
        [[DDUserInfoManager instance] showUser:showUser forContext:self];
    }
}

- (IBAction)deleteGroupMember:(id)sender
{
    NSInteger clickedRow = [_contactListTableView clickedRow];
    if (clickedRow >= 0)
    {
        NSArray* groupUsers = [self.module showGroupMembers];
        UserEntity* user = groupUsers[clickedRow];
        NSString* selectUserId = user.userId;
        
        DDDeleteMemberFromGroupAPI* deleteMemberAPI = [[DDDeleteMemberFromGroupAPI alloc] init];
        NSArray* array = @[_sessionEntity.orginId,@[selectUserId]];
        [deleteMemberAPI requestWithObject:array Completion:^(id response, NSError *error) {
        
            NSString* sessionID = self.module.session.sessionId;
            GroupEntity* group = [[DDGroupModule shareInstance] getGroupByGId:sessionID];
            if (group)
            {
                [group sortGroupUsers];
                [self reloadContactListTableView];
            }
        }];
    }
}

- (void)reloadContactListTableView
{
    [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
        [self.module updateGroupMembersData:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_contactListTableView reloadData];
                [self updateTitle];
            });
        }];
    }];
}

@end
