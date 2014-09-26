//
//  DDRecentContactsViewController.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-29.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDRecentContactsViewController.h"
#import "DDSessionModule.h"
#import "DDRecentContactsCell.h"
#import "DDMessageModule.h"
#import "DDSearch.h"
#import "DDSearchViewController.h"
#import "DDHttpModule.h"
#import "UserEntity.h"
#import "DDUserlistModule.h"
#import "DDAlertWindowController.h"
#import "GroupEntity.h"
#import "DDRecentContactsModule.h"
#import "SessionEntity.h"
#import "DDSetting.h"
#import "DDUserInfoManager.h"
#import "DDRemoveSessionAPI.h"
#import "DDGroupModule.h"
#import "DDGroupInfoManager.h"
#import "NSView+LayerAddition.h"
@interface DDRecentContactsViewController ()

- (void)p_clickTheTableView;
- (void)p_showSearchResultView;

- (void)n_receiveReloadRecentContacts:(NSNotification*)notification;
- (void)n_receiveStateChanged:(NSNotification*)notification;

- (void)p_resetSelectedRow;

- (void)p_receiveBoundsChanged:(NSNotification*)notification;
@end

@implementation DDRecentContactsViewController
{
    NSString* _selectedSessionID;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        _selectedSessionID = @"";
    }
    return self;
}

- (void)awakeFromNib
{
    [_tableView setHeaderView:nil];
    [_tableView setTarget:self];
    [_tableView setAction:@selector(p_clickTheTableView)];
    
    [_tableView setMenu:self.menu];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_receiveBoundsChanged:) name:NSViewBoundsDidChangeNotification object:nil];
    self.popover = [[NSPopover alloc] init];
    self.popover.contentViewController = _searchViewController;
    self.popover.behavior = NSPopoverBehaviorTransient;
}

- (DDRecentContactsModule*)module
{
    if (!_module)
    {
        _module = [[DDRecentContactsModule alloc] init];
    }
    return _module;
}

#pragma mark public API
- (void)selectSession:(NSString*)sessionID
{
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    NSArray* recentSessionIDs = moduleSess.recentlySessionIds;
    NSInteger selectedRow = [recentSessionIDs indexOfObject:sessionID];
    if([recentSessionIDs containsObject:sessionID])
    {
        if (selectedRow >= 0)
        {
            NSString* sId = moduleSess.recentlySessionIds[selectedRow];
            _selectedSessionID = sId;
            [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            _selectedSessionID = sessionID;
            [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
            [_tableView scrollRowToVisible:selectedRow];
        }
    }
}

- (void)updateData
{
    [_tableView reloadData];
}

- (void)initialData
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveReloadRecentContacts:) name:notificationReloadTheRecentContacts object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveStateChanged:) name:notificationonlineStateChange object:nil];
    [self.module loadRecentContacts:^(NSArray *contacts) {
        DDSessionModule* sessionModule = [DDSessionModule shareInstance];
        [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
            [sessionModule sortRecentlySessions];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_tableView reloadData];
            });
        }];
    }];
}

#pragma mark - Menu Action
- (IBAction)removeSession:(id)sender
{
    NSInteger rowNumber = [_tableView clickedRow];
    NSUInteger selectedRowNumber = [_tableView selectedRow];
    if (rowNumber < 0)
    {
        return;
    }
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    NSString* sId = moduleSess.recentlySessionIds[rowNumber];
    SessionEntity* session = [moduleSess getSessionBySId:sId];
    
    //发送移除会话请求
    uint32_t sessionType = 0;
    switch (session.type)
    {
        case SESSIONTYPE_SINGLE:
            sessionType = 1;
            break;
        case SESSIONTYPE_GROUP:
            sessionType = 2;
            break;
    }
    
    DDRemoveSessionAPI* removeSessionAPI = [[DDRemoveSessionAPI alloc] init];
    NSArray* object = @[session.orginId,@(sessionType)];
    [removeSessionAPI requestWithObject:object Completion:^(id response, NSError *error) {
        if (!error) {
            if (!response)
            {
                return;
            }
            [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                DDSessionModule* sessionModule = [DDSessionModule shareInstance];
                NSInteger row = [sessionModule.recentlySessionIds indexOfObject:sId];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [_tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationSlideDown];
                    if (selectedRowNumber == row)
                    {
                        [self selectSession:sessionModule.recentlySessionIds[0]];
                        [self.delegate recentContactsViewController:self selectSession:sessionModule.recentlySessionIds[0]];
                    }
                });
                
                if ([session.sessionId hasPrefix:GROUP_PRE])
                {
                    DDGroupModule* groupModule = [DDGroupModule shareInstance];
                    [groupModule.recentlyGroupIds removeObject:session.sessionId];
                }
                else
                {
                    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
                    [userModule.recentlyUserIds removeObject:session.sessionId];
                }
                [sessionModule.recentlySessionIds removeObject:session.sessionId];
                DDMessageModule* messageModule = [DDMessageModule shareInstance];
                [messageModule popArrayMessage:session.sessionId];
                [self.module saveRecentContacts];
                [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:nil];
//                [sessionModule sortRecentlySessions];
            }];
        }
        else
        {
            DDLog(@"Error:%@",[error domain]);
        }
    }];
}

- (IBAction)viewContact:(id)sender
{
    NSInteger rowNumber = [_tableView clickedRow];
    if(rowNumber < 0)
        return;
    
    
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    NSString* sId = moduleSess.recentlySessionIds[rowNumber];
    
    if (![sId hasPrefix:@"group"])
    {
        DDUserlistModule* userListModel = [DDUserlistModule shareInstance];
        UserEntity* showUser = [userListModel getUserById:sId];
        
        [[DDUserInfoManager instance] showUser:showUser forContext:self];
    }
    else
    {
        DDGroupModule* groupModule = [DDGroupModule shareInstance];
        GroupEntity* group = [groupModule getGroupByGId:sId];
        
        [[DDGroupInfoManager instance] showGroup:group context:self];
    }
    
}

-(IBAction)topSession:(id)sender
{
    NSInteger clickRow = [_tableView clickedRow];
    if(clickRow < 0)
        return;
    
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    NSString* sId = moduleSess.recentlySessionIds[clickRow];
    
    [[DDSetting instance] addTopSessionID:sId];
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
        [sessionModule sortRecentlySessions];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger row = [sessionModule.recentlySessionIds indexOfObject:sId];
            [_tableView moveRowAtIndex:clickRow toIndex:row];
            [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];

        });
    }];
}

-(IBAction)cancelTopSession:(id)sender
{
    NSInteger rowNumber = [_tableView clickedRow];
    if(rowNumber < 0)
        return;
    
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    NSString* sId = moduleSess.recentlySessionIds[rowNumber];
    
    [[DDSetting instance] removeTopSessionID:sId];
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
        [sessionModule sortRecentlySessions];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger row = [sessionModule.recentlySessionIds indexOfObject:sId];
            [_tableView moveRowAtIndex:rowNumber toIndex:row];
            [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        });
    }];
}

-(IBAction)shieldSession:(id)sender
{
    NSInteger rowNumber = [_tableView clickedRow];
    if(rowNumber < 0)
        return;
    
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    NSString* sId = moduleSess.recentlySessionIds[rowNumber];
    
    [[DDSetting instance] addShieldSessionID:sId];
    
    [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:rowNumber] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    
}

-(IBAction)cancelShieldSession:(id)sender
{
    NSInteger rowNumber = [_tableView clickedRow];
    if(rowNumber < 0)
        return;
    
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    NSString* sId = moduleSess.recentlySessionIds[rowNumber];
    
    [[DDSetting instance] removeShieldSessionID:sId];
    [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:rowNumber] columnIndexes:[NSIndexSet indexSetWithIndex:0]];

}

#pragma mark - DDSearchViewControllerDelegate
- (void)selectTheSearchResultObject:(id)object
{
    NSString* sessionID = nil;
    int type = 0;
    if ([object isKindOfClass:[UserEntity class]])
    {
        sessionID = [(UserEntity*)object userId];
    }
    else
    {
        sessionID = [(GroupEntity*)object groupId];
        type = [(GroupEntity*)object groupType];
    }
    //[_searchViewController.view setHidden:YES];
    [self hiddenPopView];
    [_searchField setStringValue:@""];
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    if (![sessionModule.recentlySessionIds containsObject:sessionID])
    {
        if ([sessionID hasPrefix:@"group"])
        {
            [sessionModule createGroupSession:sessionID type:type];
        }
        else
        {
            [sessionModule createSingleSession:sessionID];
        }
    }
    
    SessionEntity* session = [sessionModule getSessionBySId:sessionID];
    session.lastSessionTime = [[NSDate date] timeIntervalSince1970];
    _selectedSessionID = sessionID;
    [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:@{@"ScrollToSelected":@(YES)} object:nil];
    
    [[DDMainWindowController instance] openChat:sessionID icon:nil];
}

#pragma mark - NSMenu Delegate
- (void)menuWillOpen:(NSMenu *)menu
{
    NSInteger rowNumber = [_tableView clickedRow];
    if(rowNumber < 0)
        return;
    
    //设置移除会话菜单
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    NSString* sessionID = sessionModule.recentlySessionIds[rowNumber];
    SessionEntity* session = [sessionModule getSessionBySId:sessionID];
    BOOL removeItemShow = YES;
    if (session.type == SESSIONTYPE_SINGLE)
    {
        UserEntity* user = [[DDUserlistModule shareInstance] getUserById:session.orginId];
        if((user.userRole & 0x20000000) != 0)
        {
            //公共帐号
            removeItemShow = NO;
        }
    }
    NSArray* topSession = [[DDSetting instance] getTopSessionIDs];
    if ([topSession containsObject:sessionID])
    {
        removeItemShow = NO;
    }
    
    NSMenuItem* removeMenuItem = [menu itemAtIndex:0];
    [removeMenuItem setHidden:!removeItemShow];
    
    
    //设置置顶菜单
    if ([topSession containsObject:sessionID])
    {
        NSMenuItem* topMenuItem = [menu itemAtIndex:2];
        [topMenuItem setHidden:YES];
        
        NSMenuItem* cancelMenuItem = [menu itemAtIndex:3];
        [cancelMenuItem setHidden:NO];
        
    }
    else
    {
        NSMenuItem* topMenuItem = [menu itemAtIndex:2];
        [topMenuItem setHidden:NO];
        
        
        NSMenuItem* cancelMenuItem = [menu itemAtIndex:3];
        [cancelMenuItem setHidden:YES];
        
    }
    //设置屏蔽菜单
    if (session.type == SESSIONTYPE_SINGLE)
    {
        NSMenuItem* shieldMenuItem = [menu itemAtIndex:5];
        [shieldMenuItem setHidden:YES];
        
        NSMenuItem* cancelShieldMenuItem = [menu itemAtIndex:6];
        [cancelShieldMenuItem setHidden:YES];
    }
    NSArray* shieldSessions = [[DDSetting instance] getShieldSessionIDs];
    if ([shieldSessions containsObject:sessionID])
    {
        NSMenuItem* shieldMenuItem = [menu itemAtIndex:5];
        [shieldMenuItem setHidden:YES];
        
        NSMenuItem* cancelShieldMenuItem = [menu itemAtIndex:6];
        [cancelShieldMenuItem setHidden:NO];
    }
    else
    {
        NSMenuItem* shieldMenuItem = [menu itemAtIndex:5];
        [shieldMenuItem setHidden:NO];
        
        NSMenuItem* cancelShieldMenuItem = [menu itemAtIndex:6];
        [cancelShieldMenuItem setHidden:YES];
    }
    
}

#pragma mark NSTextField Delegate

- (void)controlTextDidChange:(NSNotification *)obj
{
   
    DDSearch* search = [DDSearch instance];
    [search searchContent:_searchField.stringValue completion:^(NSArray *result, NSError *error) {
        if ([result count] == 0)
        {
            //[_searchViewController.view setHidden:YES];
            [self hiddenPopView];
        }
        else
        {
            [_searchViewController setShowData:result];
            CGFloat height = 0;
            if ([result count] > 10)
            {
                height = [_searchViewController rowHeight] * 10;
            }
            else
            {
                height = [_searchViewController rowHeight] * [result count] + 6;
            }
            [self.popover setContentSize:NSMakeSize(self.view.bounds.size.width, height)];
//            [_searchViewController.view setFrameSize:NSMakeSize(self.view.bounds.size.width, height)];
            [self p_showSearchResultView];
        }
    }];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
//    if (![control isEqual:_searchField])
//    {
//        return YES;
//    }
    if ([NSStringFromSelector(commandSelector) isEqualToString:@"moveDown:"])
    {
        [_searchViewController selectNext];
    }
    else if ([NSStringFromSelector(commandSelector) isEqualToString:@"moveUp:"])
    {
        [_searchViewController selectLast];
    }
    else if ([NSStringFromSelector(commandSelector) isEqualToString:@"insertNewline:"])
    {
        id object = [_searchViewController selectedObject];
        NSString* sessionID = nil;
        int type = 0;
        if ([object isKindOfClass:[UserEntity class]])
        {
            sessionID = [(UserEntity*)object userId];
        }
        else
        {
            sessionID = [(GroupEntity*)object groupId];
            type = [(GroupEntity*)object groupType];
        }
        //[_searchViewController.view setHidden:YES];
        [self hiddenPopView];
        [_searchField setStringValue:@""];
        DDSessionModule* sessionModule = [DDSessionModule shareInstance];
        if (![sessionModule.recentlySessionIds containsObject:sessionID])
        {
            if ([sessionID hasPrefix:@"group"])
            {
                [sessionModule createGroupSession:sessionID type:type];
            }
            else
            {
                [sessionModule createSingleSession:sessionID];
            }
            [self n_receiveReloadRecentContacts:nil];
        }
        SessionEntity* session = [sessionModule getSessionBySId:sessionID];
        session.lastSessionTime = [[NSDate date] timeIntervalSince1970];
        _selectedSessionID = sessionID;
        [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:@{@"ScrollToSelected":@(YES)} object:nil];
        [[DDMainWindowController instance] openChat:sessionID icon:nil];
    }
	else
    {
        if ([textView respondsToSelector:commandSelector])
        {
            [textView performSelector:commandSelector withObject:nil afterDelay:0];
        }
    }
    return YES;
}

#pragma mark TableView DataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    return [moduleSess.recentlySessionIds count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 50;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    NSString* sId = moduleSess.recentlySessionIds[row];
    SessionEntity* session = [moduleSess getSessionBySId:sId];
    
    NSString* identifier = [tableColumn identifier];
    NSString* cellIdentifier = @"RecentContactCellIdentifier";
    if ([identifier isEqualToString:@"RecentContactColumnIdentifier"])
    {
        DDRecentContactsCell* cell = (DDRecentContactsCell*)[tableView makeViewWithIdentifier:cellIdentifier owner:self];
        [cell configeCellWithObject:session];
        
        return cell;
    }
    return nil;
}

#pragma mark privateAPI
- (void)p_clickTheTableView
{
    NSInteger selectedRow = [_tableView selectedRow];
    DDSessionModule* moduleSess = [DDSessionModule shareInstance];
    if (selectedRow >= 0)
    {
        NSString* sId = moduleSess.recentlySessionIds[selectedRow];
        _selectedSessionID = sId;
        if (self.delegate)
        {
            [self.delegate recentContactsViewController:self selectSession:sId];
        }
        [_tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] columnIndexes:[NSIndexSet indexSetWithIndex:0]];

    }
}

- (void)p_showSearchResultView
{

    [_searchViewController.view setHidden:NO];
    if (self.isShowPop == 0) {
            [self.popover showRelativeToRect:[self.searchField bounds] ofView:self.searchField preferredEdge:NSMaxXEdge];
        [self.searchField becomeFirstResponder];
        [[self.searchField currentEditor] moveToEndOfLine:nil];
        self.isShowPop =1;
    }
}

- (void)n_receiveReloadRecentContacts:(NSNotification*)notification
{
    log4Info(@"RecentContacts Reload");
    NSString* object = [notification object];
    NSDictionary* userInfo = [notification userInfo];
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
        [sessionModule sortRecentlySessions];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (object)
            {
                [_tableView reloadData];
                [self selectSession:object];
                if (self.delegate)
                {
                    [self.delegate recentContactsViewController:self selectSession:object];
                }
            }
            else
            {
                [_tableView reloadData];
                [self p_resetSelectedRow];
            }
            
            NSNumber* scroll = userInfo[@"ScrollToSelected"];
            if ([scroll boolValue])
            {
                NSInteger selectedRow = [sessionModule.recentlySessionIds indexOfObject:_selectedSessionID];
                [_tableView scrollRowToVisible:selectedRow];
            }
            
        });
    }];

}

- (void)n_receiveStateChanged:(NSNotification *)notification
{
    [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
        NSMutableIndexSet* changedIndexSet = [NSMutableIndexSet indexSet];
        NSDictionary* changeDic = [notification object];
        DDSessionModule* sessionModule = [DDSessionModule shareInstance];
        [[changeDic allKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([sessionModule.recentlySessionIds containsObject:obj])
            {
                @autoreleasepool {
                    NSInteger row = [sessionModule.recentlySessionIds indexOfObject:obj];
                    [changedIndexSet addIndex:row];
                }
            }
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView reloadDataForRowIndexes:changedIndexSet columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        });
    }];
}

- (void)p_resetSelectedRow
{
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    NSArray* recentSessionIDs = sessionModule.recentlySessionIds;
    [recentSessionIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqualToString:_selectedSessionID])
        {
            [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
            *stop = YES;
        }
    }];
}

- (void)p_receiveBoundsChanged:(NSNotification*)notification
{
    
    id object = [notification object];
    if ([object isEqual:self.clipView])
    {
        [self hiddenPopView];
    }
}
-(void)hiddenPopView
{
    [_searchViewController.view setHidden:YES];
    [self.popover performClose:nil];
    self.isShowPop=0;
}
@end
