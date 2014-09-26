/************************************************************
 * @file         DDMainWindowController+Event.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       主窗口事件处理category
 ************************************************************/

#import "DDCommonApi.h"
#import "DDUserListModule.h"
#import "DDMessageModule.h"
#import "DDScreenCaptureModule.h"
#import "DDSessionModule.h"
#import "DDLoginModule.h"
#import "DDChattingViewController.h"
#import "DDAlertWindowController.h"
#import "DDUserPreferences.h"
#import "DDDatabaseUtil.h"
#import "StateMaintenanceManager.h"

@interface DDMainWindowController(PrivateAPI)

- (void)promptNewMessage:(MessageEntity*)message;

@end

@implementation DDMainWindowController (Event)

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
#warning 截屏通知
//        [[DDLogic instance] addObserver:MODULE_ID_CAPTURE name:MKN_DDSCREENCAPTUREMODULE_OK observer:self selector:@selector(onScreenCaptureClickOk:)];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MKN_DDSCREENCAPTUREMODULE_OK object:nil];
}

#pragma mark message handle

//截图点击确定.
-(void)onScreenCaptureClickOk:(NSNotification *)notification
{
    [[duoduo interfaceController] paste:nil];
}

-(void)onUpdateStateIcon:(NSNotification *)notification
{
    if(USER_STATUS_OFFLINE != [[StateMaintenanceManager instance] getMyOnlineState])
    {
        [[DDAlertWindowController defaultControler] closeAlertWindow];
    }
}

#pragma mark PrivateAPI
- (void)promptNewMessage:(MessageEntity*)message
{
    if(message && [[DDUserPreferences defaultInstance] showBubbleHint])
    {
        NSString* senderID = message.senderId;
        DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
        UserEntity* user = [userListModule getUserById:senderID];
        [self notifyUserNewMsg:message.sessionId title:user.name content:message.msgContent];
    }
    
    if ([[DDUserPreferences defaultInstance] playNewMesageSound]) {
        [DDCommonApi playSound:@"message.wav"];
    }
//    dispatch_async(dispatch_get_main_queue(), ^(){
//        [recentConverstationController.userListTableView reloadData];
//    });
}
@end
