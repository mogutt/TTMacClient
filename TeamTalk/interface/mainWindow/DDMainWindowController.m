//
//  DDMainWindowController.m
//  Duoduo
//
//  Created by zuoye on 13-11-28.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "DDMainWindowController.h"
#import "DDGroupViewController.h"
#import "DDRecentContactsViewController.h"
#import "DDSplitView.h"
#import "DDChattingViewController.h"
#import "MessageEntity.h"
#import "UserEntity.h"
#import "DDUserlistModule.h"
#import "DDMessageModule.h"
#import "SessionEntity.h"
#import "DDSessionModule.h"
#import "DDUserInfoManager.h"
#import "DDChattingViewModule.h"
#import "DDSetting+OffLineReadMsgManager.h"
#import "StateMaintenanceManager.h"
#import "Reachability.h"
#import "DDLoginManager.h"
#import "DDMainWindowControllerModule.h"
#import "SessionEntity.h"
#import "DDClientState.h"
#import "DDChattingWindowManager.h"
#import "DDGroupModule.h"
#import "GroupEntity.h"
#import "NSWindow+Animation.h"
#import "DDGroupInfoManager.h"
#import "DDDatabaseUtil.h"
#import "DDUserPreferences.h"
#import "DDCommonApi.h"
#import "DDUserMsgReadACKAPI.h"
#import "DDGroupMsgReadACKAPI.h"
#import "DDUserInfoAPI.h"
#import "DDOrganizationViewController.h"
#define MAIN_WINDOW_NIB	@"DDMainWindow"		//Filename of the login window nib

@interface DDMainWindowController ()

- (void)p_initialFirstColumnViewControllers;

- (void)receiveDeletedFromGroupNotification:(NSNotification*)notification;
- (void)receiveReachabilityChangedNotification:(NSNotification*)notification;
- (void)receiveKickOffNotification:(NSNotification*)notification;
- (void)n_receiveBecomeKeyWindowNotification:(NSNotification*)notification;
- (void)n_receiveMessageNotification:(NSNotification*)notification;
- (void)n_receiveP2PMessageNotification:(NSNotification*)notification;
- (void)n_receiveP2pIntranetNotification:(NSNotification*)notification;

- (void)p_promptNewMessage:(MessageEntity*)message;


@end

@implementation DDMainWindowController
{
    BOOL _showSession;
    NSMutableArray* _firstColumnViewControllers;
    NSString* _lastSessionID;
    
    NSInteger _selectedIndexInLeftBar;
}

+ (instancetype)instance
{
    static DDMainWindowController* g_mainWindowController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_mainWindowController = [[DDMainWindowController alloc] init];
    });
    return g_mainWindowController;
}

-(id)init
{
	if ((self = [super initWithWindowNibName:MAIN_WINDOW_NIB])) {
		//Retain our owner
		//owner = inOwner;
        
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        
        preOnlineMenuTag = USER_STATUS_ONLINE;
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveDeletedFromGroupNotification:) name:MKN_DDSESSIONMODULE_DELETEDFROMGROUP object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveReachabilityChangedNotification:) name:kReachabilityChangedNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveBecomeKeyWindowNotification:) name:NSWindowDidBecomeKeyNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveMessageNotification:) name:notificationReceiveMessage object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveP2PMessageNotification:) name:notificationReceiveP2PShakeMessage object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveP2pIntranetNotification:) name:notificationReceiveP2PIntranetMessage object:nil];
        
        [self module];
    }
	return self;
}

- (DDMainWindowControllerModule*)module
{
    if (!_module)
    {
        _module = [[DDMainWindowControllerModule alloc] init];
    }
    return _module;
}

-(void)awakeFromNib{
        
    _showSession = NO;
    [self.window setAlphaValue:0];
    [self.window fadeInAnimation];
}



- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [_statusItem setImage:[NSImage imageNamed:@"icon_statusbar"]];
    [_statusItem setHighlightMode:YES];
    [_statusItem setTarget:self];
    [_statusItem setAction:@selector(onStatusItemClick)];
    
    [self p_initialFirstColumnViewControllers];
    
    [self.mainSplitView setPosition:100 ofDividerAtIndex:0];
    [_leftBarViewController selectTheItemAtIndex:0];
    _leftBarViewController.delegate = self;
    NSViewController* viewController = _firstColumnViewControllers[0];
    [viewController.view setFrame:NSMakeRect(0, 0, self.firstColumnView.bounds.size.width, self.firstColumnView.bounds.size.height)];
    [self.firstColumnView addSubview:viewController.view];

}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
}

- (IBAction)pressOnlineStateBtn:(id)sender
{
    NSRect rect =  [sender frame];
    NSPoint pt = NSMakePoint(rect.origin.x, rect.origin.y);
    pt = [[sender superview] convertPoint:pt toView:nil];
    pt.y-=4;
    NSInteger winNum = [[sender window] windowNumber];
    
    
    NSEvent *event= [NSEvent mouseEventWithType:NSLeftMouseDown location:pt modifierFlags:NSLeftMouseDownMask timestamp:0 windowNumber:winNum context:[[sender window] graphicsContext] eventNumber:0 clickCount:1 pressure:1];
    [NSMenu popUpContextMenu: onlineStateMenu withEvent:event forView:sender];
}


#pragma mark openChat
-(void)openChat:(NSString *)sId icon:(NSImage *)icon{
    
    _lastSessionID = sId;
    DDMessageModule* messageModule = [DDMessageModule shareInstance];
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    sessionModule.chatingSessionID = sId;
    

    SessionEntity *sessionEntity = [[DDSessionModule shareInstance] getSessionBySId:sId];
    if (!sessionEntity)
    {
        if ([sId rangeOfString:@"group"].length > 0)
        {
            DDGroupModule* groupModule = [DDGroupModule shareInstance];
            GroupEntity* group = [groupModule getGroupByGId:sId];
            UInt32 groupType = group.groupType;
            sessionEntity = [[DDSessionModule shareInstance] createGroupSession:sId type:groupType];
            
        }
        else
        {
            sessionEntity = [[DDSessionModule shareInstance] createSingleSession:sId];
        }
        //刷新最近联系人
    }
    
    if ([[_chattingBackgroudView subviews] containsObject:[currentChattingViewController view]]) {
        [[currentChattingViewController view] removeFromSuperview ];
    }
    
    switch ([[StateMaintenanceManager instance] getMyOnlineState])
    {
        case USER_STATUS_ONLINE:
        case USER_STATUS_LEAVE:
        {
            if ([messageModule countMessageBySessionId:sId] > 0)
            {
                SessionEntity* session = [sessionModule getSessionBySId:sId];
                [sessionModule tcpSendReadedAck:session];
            }
        }
            break;
        case USER_STATUS_OFFLINE:
        {
            [[DDSetting instance] addOffLineReadMsgSessionID:sessionEntity.sessionId];
        }
            break;
    }

    DDMessageModule* moduleMsg = [DDMessageModule shareInstance];
    NSArray* msgArray = [moduleMsg popArrayMessage:sId];
    BOOL appendUnreadMessage = YES;
    if ([[DDChattingWindowManager instance] openChattingWindowForSessionID:sId])
    {
        if ([msgArray count] > 30)
        {
            [[DDChattingWindowManager instance] removeChattingWindowForSessionID:sId];
            appendUnreadMessage = NO;
        }
    }
    else
    {
        appendUnreadMessage = NO;
    }
    
    currentChattingViewController=[[DDChattingWindowManager instance] openChattingWindowForSessionID:sId];
    if (!currentChattingViewController) {
        DDChattingViewController* chattingVC = [[DDChattingViewController alloc] initWithNibName:@"DDChattingView" bundle:nil];
        DDChattingViewModule* chattingModule = [[DDChattingViewModule alloc] initWithSession:sessionEntity];
        chattingVC.module = chattingModule;
        
        [[DDChattingWindowManager instance] addChattingWindow:chattingVC forSessionID:sId];
    }
    
    currentChattingViewController = [[DDChattingWindowManager instance] openChattingWindowForSessionID:sId];
    
    [_chattingBackgroudView addSubview:[currentChattingViewController view]];
    [[currentChattingViewController view] setFrame:[_chattingBackgroudView bounds]];

    
    if (appendUnreadMessage)
    {
        for (NSInteger index = 0; index < [msgArray count]; index ++)
        {
            MessageEntity* msg = msgArray[index];
            [currentChattingViewController addMessageToChatContentView:msg isHistoryMsg:NO showtime:kIgnore showName:kIgnoreThis];
        }
    }
    [currentChattingViewController makeInputViewFirstResponder];
    [currentChattingViewController scrollToMessageEnd];
}

-(void)openChatViewByUserId:(NSString *)userId {
    if (userId)
    {
        [self openChat:userId icon:nil];
    }
}

-(void)updateCurrentChattingViewController
{
    if (currentChattingViewController)
    {
        [currentChattingViewController updateUI];
    }
}

- (void)recentContactsSelectObject:(NSString*)sessionID
{
    DDRecentContactsViewController* recentContacts = _firstColumnViewControllers[0];
    [recentContacts selectSession:sessionID];
}

- (void)shakeTheWindow
{
    [self.window beginShakeAnimation];
}

static NSString* const SESSION_ID = @"sessionId";          //群消息到达
-(void)notifyUserNewMsg:(NSString*)sId title:(NSString*)title content:(NSString*)content
{
    NSUserNotificationCenter* notifyCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    //如果缓存命中，则先remove掉    {
//        [notifyCenter removeDeliveredNotification:cachedNotification];
    NSUserNotification* notification = [[NSUserNotification alloc]init];
    
    //标题过滤
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    SessionEntity* session = [sessionModule getSessionBySId:sId];
    if (session.type != SESSIONTYPE_SINGLE)
    {
        notification.title = [NSString stringWithFormat:@"%@-%@",session.name,title];
    }
    else
    {
        notification.title = title;
    }
    
    //内容过滤
    NSError* error = NULL;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"&\\$#@~\\^@\\[\\{:[\\w|\\W]+?:\\}\\]&\\$~@#@"
                                                                           options:0
                                                                             error:&error];
    NSString* result = [regex stringByReplacingMatchesInString:content
                                                       options:0
                                                         range:NSMakeRange(0, content.length)
                                                  withTemplate:@"[图片]"];
    notification.informativeText = result;
    notification.hasActionButton = YES;
    notification.actionButtonTitle = @"OK";
    notification.otherButtonTitle = @"Cancel";
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:sId forKey:SESSION_ID];
    [notification setUserInfo:userInfo];
    [notifyCenter deliverNotification:notification];
}

- (void)leftChangeUseravatar:(NSImage*)image
{
    [_leftBarViewController.avatarImageView setImage:image];
}

#pragma mark 点击了消息通知中心弹出来的面板.
- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification
{
    if(!notification || !notification.userInfo)
        return;
    
    [[self window] makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    NSString* sessionId = [notification.userInfo objectForKey:SESSION_ID];
    if (sessionId)
    {
        DDRecentContactsViewController* recentContactsVC = (DDRecentContactsViewController*)_firstColumnViewControllers[0];
        [self openChatViewByUserId:sessionId];
        [recentContactsVC selectSession:sessionId];
    }
    else
    {
        //内网消息
        [self.leftBarViewController selectTheItemAtIndex:2];
    }

}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}
-(void)renderTotalUnreadedCount:(NSUInteger)count
{
    #define MAX_UNREADEDCOUNT_STRING @"99+"
    #define EMPTY_UNREADEDCOUNT_STRING  @""
    
    NSDockTile* title = [[NSApplication sharedApplication] dockTile];

    if (count == 0)
    {
        [_statusItem setImage:[NSImage imageNamed:@"icon_statusbar"]];
    }
    else
    {
        [_statusItem setImage:[NSImage imageNamed:@"icon_statusbar_blue"]];
    }
    
    if(count > 99)
    {
        [_statusItem setTitle:MAX_UNREADEDCOUNT_STRING];
        [title setBadgeLabel:MAX_UNREADEDCOUNT_STRING];
    }
    else if(count > 0)
    {
        [_statusItem setTitle:[NSString stringWithFormat:@"%ld",count]];
        [title setBadgeLabel:[NSString stringWithFormat:@"%ld",count]];
    }
    else
    {
        [_statusItem setTitle:EMPTY_UNREADEDCOUNT_STRING];
        [title setBadgeLabel:EMPTY_UNREADEDCOUNT_STRING];
    }
    
    //左侧Item
    dispatch_async(dispatch_get_main_queue(), ^{
        DDMessageModule* messageModule = [DDMessageModule shareInstance];
        int unreadIntranetMessage = [messageModule countOfUnreadIntranetMessageForSessionID:@"1szei2"];
        [_leftBarViewController setMessageCount:unreadIntranetMessage atIndex:2];
        [_leftBarViewController setMessageCount:count atIndex:0];
    });
}


//菜单栏icon点击,打开窗口.
-(void)onStatusItemClick
{
    [[self window] makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];

    DDMessageModule* messageModule = [DDMessageModule shareInstance];
    if ([messageModule countUnreadMessage] > 0)
    {
        DDSessionModule* sessionModule = [DDSessionModule shareInstance];

        NSString* toSelectedSession = _lastSessionID ? _lastSessionID : [sessionModule getLastSession];
        
        [self openChatViewByUserId:toSelectedSession];

        
        DDRecentContactsViewController* recentContactsViewController = _firstColumnViewControllers[0];
        [recentContactsViewController selectSession:toSelectedSession];
        
        DDGroupViewController* groupViewController = _firstColumnViewControllers[1];
        [groupViewController selectGroup:toSelectedSession];
        
    }

}

#pragma mark NSSplitView

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (dividerIndex == 0)
    {
        return 230;
    }
    else
    {
        return 570;
    }
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (dividerIndex == 0)
    {
        return 230;
    }
    else
    {
        return 1000;
    }
}

//- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
//{
//    [splitView setPosition:230 ofDividerAtIndex:0];
//    [splitView setPosition:oldSize.width - 230 ofDividerAtIndex:1];
//}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
    if ([view isEqual:_chattingBackgroudView])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark DDRecentContactsViewContrpller Delegate
- (void)recentContactsViewController:(DDRecentContactsViewController *)viewController selectSession:(NSString *)session
{
    [self openChat:session icon:nil];
}

#pragma mark DDGroupViewController Delegate
- (void)groupViewController:(DDGroupViewController *)groupVC selectGroup:(GroupEntity *)group
{
    [self openChat:group.groupId icon:nil];
}

#pragma mark - DDLeftBarViewControllerDelegate
- (void)selectedItemIndex:(NSInteger)index
{
    _selectedIndexInLeftBar = index;
    NSMutableArray* toRemoveSubView = [NSMutableArray arrayWithArray:self.firstColumnView.subviews];
    [toRemoveSubView enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(NSView*)obj removeFromSuperview];
    }];
    NSViewController* viewController = _firstColumnViewControllers[index];
    [viewController.view setFrame:NSMakeRect(0, 0, self.firstColumnView.bounds.size.width, self.firstColumnView.bounds.size.height)];
    [self.firstColumnView addSubview:viewController.view];
    
    if (!_lastSessionID)
    {
        DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
        _lastSessionID = userListModule.recentlyUserIds[0];
    }
    if (_lastSessionID)
    {
        if (index == 0)
        {
            //选中最近联系人
            DDRecentContactsViewController* recentContactsVC = _firstColumnViewControllers[0];
            [recentContactsVC selectSession:_lastSessionID];
            [self openChatViewByUserId:_lastSessionID];
        }
        else if (index == 1)
        {
            DDGroupViewController* groupVC = _firstColumnViewControllers[1];
            [groupVC selectGroup:_lastSessionID];
            [self openChatViewByUserId:_lastSessionID];
        }
    }
    if (index == 2)
    {
        //改成打开组织架构
//        DDIntranetViewController* intranetVC = _firstColumnViewControllers[2];
//        [intranetVC selectItemAtIndex:0];
    }
}

#pragma mark Private API
- (void)mainWindowBecomeAlive:(NSNotification*)notification
{
    DDMessageModule* messageModule = [DDMessageModule shareInstance];
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    NSString* sessionID = sessionModule.chatingSessionID;
    if ([messageModule countMessageBySessionId:sessionID] > 0)
    {
//        [self selectTheSessionSegment:nil];
        [self openChatViewByUserId:sessionID];
        DDRecentContactsViewController* recentContactsVC = _firstColumnViewControllers[0];
        [recentContactsVC selectSession:sessionID];
    }
}

- (void)receiveDeletedFromGroupNotification:(NSNotification*)notification
{
    NSString* sessionID = [notification object];
    [[DDMessageModule shareInstance] removeArrayMessage:sessionID];
}

- (void)receiveReachabilityChangedNotification:(NSNotification*)notification
{
    Reachability* reachability = [notification object];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([reachability isReachable])
        {
            [[DDAlertWindowController defaultControler] closeAlertWindow];
        }
        else
        {
            [[DDAlertWindowController  defaultControler] showAlertWindow:[self window] title:@"网络故障" info:@"网络连接中断" leftBtnName:@"" midBtnName:@"" rightBtnName:@"确定"];
        }
    });
}

- (void)receiveKickOffNotification:(NSNotification *)notification
{
    [[DDAlertWindowController  defaultControler] showAlertWindow:[self window] title:@"下线通知" info:@"您的账号在另一地点登陆，您被迫下线" leftBtnName:@"" midBtnName:@"" rightBtnName:@"确定"];
}

- (void)p_initialFirstColumnViewControllers
{
    _firstColumnViewControllers = [[NSMutableArray alloc] init];
    DDRecentContactsViewController* recentContactsViewController = [[DDRecentContactsViewController alloc] initWithNibName:@"DDRecentContactsViewController" bundle:nil];
    [recentContactsViewController initialData];
    [recentContactsViewController setDelegate:self];
    [_firstColumnViewControllers addObject:recentContactsViewController];
    
    DDGroupViewController* groupViewController = [[DDGroupViewController alloc] initWithNibName:@"DDGroupViewController" bundle:nil];
    [groupViewController initialData];
    [groupViewController setDelegate:self];
    [_firstColumnViewControllers addObject:groupViewController];
    
    DDOrganizationViewController* organizationViewController = [[DDOrganizationViewController alloc] initWithNibName:@"DDOrganizationViewController" bundle:nil];
//    DDIntranetViewController* intranetViewController = [[DDIntranetViewController alloc] initWithNibName:@"DDIntranentViewController" bundle:nil];
//    [intranetViewController setDelegate:self];
    [_firstColumnViewControllers addObject:organizationViewController];
}

- (void)n_receiveBecomeKeyWindowNotification:(NSNotification*)notification
{
    
    NSWindow* window = [notification object];
    if([window isEqual:self.window])
    {
        if (_lastSessionID)
        {
            DDMessageModule* messageModule = [DDMessageModule shareInstance];
            if([messageModule countMessageBySessionId:_lastSessionID] > 0)
            {
                [self openChat:_lastSessionID icon:nil];
            }
            DDRecentContactsViewController* recentContactsVC = _firstColumnViewControllers[0];
            [recentContactsVC selectSession:_lastSessionID];
        }
    }
}

- (void)n_receiveMessageNotification:(NSNotification*)notification
{
    MessageEntity* message = [notification object];
    NSString* sessionId = message.sessionId;
    DDMessageModule* moduleMsg = [DDMessageModule shareInstance];
    if([moduleMsg countMessageBySessionId:sessionId] < 1)
        return;
    if ([sessionId isEqualToString:_lastSessionID] && [[NSApplication sharedApplication] isActive] && [self.window isKeyWindow])     //当前焦点项
    {
        MessageEntity* msg = [moduleMsg popMessage:sessionId];
        [currentChattingViewController addMessageToChatContentView:msg isHistoryMsg:NO showtime:kIgnore showName:kIgnoreThis];
        DDSessionModule* moduleSess = [DDSessionModule shareInstance];
        SessionEntity* session = [moduleSess getSessionBySId:sessionId];
        [[DDDatabaseUtil instance] insertMessage:msg
                                         success:^{
                                             
                                             [moduleSess tcpSendReadedAck:session];
                                         } failure:^(NSString *errorDescripe) {
                                             
                                         }];
        DDLog(@"***************************************************************");
    }
    else
    {
        //不是当前列,要显示未读消息.
        [self p_promptNewMessage:message];
    }
}

- (void)n_receiveP2PMessageNotification:(NSNotification*)notification
{
    NSDictionary* dic = [notification object];
    NSDictionary* contentDic = dic[@"content"];
    if (!contentDic)
    {
        return;
    }

    NSString* fromUserId = dic[@"fromUserID"];
    DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
    UserEntity* user = [userListModule getUserById:fromUserId];
    NSString* content = contentDic[@"Content"];
    if ([content isEqualToString:@"shakewindow"])
    {
        [self notifyUserNewMsg:fromUserId title:user.name content:@"向你发送了一个抖动"];
        [NSApp activateIgnoringOtherApps:YES];
        [self.window makeKeyAndOrderFront:nil];
        [self.window beginShakeAnimation];
        
        //
        DDSessionModule* sessionModule = [DDSessionModule shareInstance];
        SessionEntity* session = [sessionModule getSessionBySId:fromUserId];
        session.lastSessionTime = [[NSDate date] timeIntervalSince1970];
        [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:nil];
    }
}

- (void)n_receiveP2pIntranetNotification:(NSNotification*)notification
{
    NSDictionary* dic = [notification object];
    NSDictionary* content = dic[@"content"];
    if ([[DDUserPreferences defaultInstance] playNewMesageSound]) {
        [DDCommonApi playSound:@"message.wav"];
    }
    if ([[DDUserPreferences defaultInstance] showBubbleHint])
    {
        NSUserNotificationCenter* notifyCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
        //如果缓存命中，则先remove掉    {
        //        [notifyCenter removeDeliveredNotification:cachedNotification];
        NSUserNotification* userNotification = [[NSUserNotification alloc]init];
        
        //内容过滤
        userNotification.title = [NSString stringWithFormat:@"内网 - %@",content[@"Author"]];
        userNotification.informativeText = content[@"Content"];
        userNotification.hasActionButton = YES;
        userNotification.actionButtonTitle = @"OK";
        userNotification.otherButtonTitle = @"Cancel";
        [userNotification setUserInfo:dic];
        [notifyCenter deliverNotification:userNotification];
    }
}

- (void)p_promptNewMessage:(MessageEntity*)message
{
    if(message && [[DDUserPreferences defaultInstance] showBubbleHint])
    {
        NSString* senderID = message.senderId;
        DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
        UserEntity* user = [userListModule getUserById:senderID];
        if (user)
        {
            if ([[DDUserPreferences defaultInstance] playNewMesageSound]) {
                [DDCommonApi playSound:@"message.wav"];
            }
            [self notifyUserNewMsg:message.sessionId title:user.name content:message.msgContent];
        }
        else
        {
            DDUserInfoAPI* userInfoAPI = [[DDUserInfoAPI alloc] init];
            [userInfoAPI requestWithObject:@[senderID] Completion:^(id response, NSError *error) {
                UserEntity* user = response[0];
                [userListModule addUser:user];
                if ([[DDUserPreferences defaultInstance] playNewMesageSound]) {
                    [DDCommonApi playSound:@"message.wav"];
                }
                [self notifyUserNewMsg:message.sessionId title:user.name content:message.msgContent];
            }];
        }
    }
}
- (IBAction)showMyInfo:(id)sender
{
    DDUserlistModule* userListModel = [DDUserlistModule shareInstance];
    UserEntity* showUser = [userListModel myUser];
    [[DDUserInfoManager instance] showUser:showUser forContext:self];
}
@end
