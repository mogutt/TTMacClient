/************************************************************
 * @file         DDApplicationInstance.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       多多应用程序级别相关的业务处理
 ************************************************************/

#import "DDModuleID.h"
#import "DDApplicationInstance.h"
#import "UserEntity.h"
#import "LoginEntity.h"

#import "DDSessionModule.h"
#import "DDUserListModule.h"
#import "DDLoginModule.h"
#import "DDScreenCaptureModule.h"
#import "DDHttpModule.h"
#import "DDMessageModule.h"
#import "DDMainModule.h"
#import "DDGroupModule.h"
#import "DDUserPreferences.h"

@interface DDApplicationInstance()

-(void)registerAllModules;
-(void)onLoginCompleted:(NSNotification*)notification;

@end

@implementation DDApplicationInstance

-(void)registerAllModules
{
    //tcp长连接
//    DDTcpLinkModule* moduleTcpLink = [[DDTcpLinkModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleTcpLink];
//    //会话模块
//    DDSessionModule* moduleSession = [[DDSessionModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleSession];
//    //成员列表模块
//    DDUserlistModule* moduleFriendList = [[DDUserlistModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleFriendList];
//    //登陆模块
//    DDLoginModule* moduleLogin = [[DDLoginModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleLogin];
//    //截屏模块
//    DDScreenCaptureModule* moduleCapture = [[DDScreenCaptureModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleCapture];
//    //文件传输模块
//    DDFileTransferModule* moduleFileTrans = [[DDFileTransferModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleFileTrans];
//    //http模块
//    DDHttpModule* moduleHttp = [[DDHttpModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleHttp];
//    //消息模块
//    DDMessageModule* moduleMessage = [[DDMessageModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleMessage];
//    //主窗口
//    DDMainModule* moduleMain = [[DDMainModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleMain];
//    //common模块
//    DDCommonModule* moduleCommon = [[DDCommonModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleCommon];
//    //群里列表管理模块
//    DDGroupModule* moduleGroup = [[DDGroupModule alloc] initModule];
//    [[DDLogic instance] registerModule:moduleGroup];
}

+(DDApplicationInstance*)instance
{
    static DDApplicationInstance* _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        _instance = [[self alloc] init];
    });
    
    return _instance;
}

-(BOOL)startup
{
    //注册所有多多业务模块
    [self registerAllModules];
    DDLog(@"App:DDLogic register all modules done!");

    //DDLogic框架初始化
//    if(![[DDLogic instance] startup])
//    {
//        DDLog(@"App:DDLogic startup failed!");
//        return NO;
//    }
    DDLog(@"App:DDLogic startup done!");
    
    return YES;
}

-(void)shutdown
{
    //DDLogic框架关闭
//    [[DDLogic instance] shutdown];
}

-(void)onLoginCompleted:(NSNotification*)notification
{
//    LoginEntity* logEntity = [notification.userInfo valueForKey:USERINFO_DEFAULT_KEY];
//    if(0 != logEntity.result)
//    {
//        DDLoginModule* moduleLogin = getDDLoginModule();
//       // [moduleLogin loginTcpServer];
//    }
//    else
//    {
//        //登陆成功，显示主窗口
//        DDMainModule* module = getDDMainModule();
//        [module showMainWindow];
//        DDTcpLinkModule* moduleTcpLink = getDDTcpLinkModule();
//        [moduleTcpLink startMonitorReachability];
//        
//        //注册快捷键.
//        [[DDUserPreferences defaultInstance] resetShortcutRegistration];
//    }
}
@end
