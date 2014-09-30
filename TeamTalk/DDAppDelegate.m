//
//  DDAppDelegate.m
//  Duoduo
//
//  Created by maye on 13-10-30.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "DDAppDelegate.h"
#import "UserEntity.h"
#import "DDSessionModule.h"
#import "DDLoginModule.h"
#import "DDMainModule.h"
#import "DDMainWindowController.h"
#import "DDApplicationInstance.h"
#import "DDMainWindowController.h"
#import "DDMessageModule.h"
#import "DDApplicationUpdate.h"
#import "DDLoginWindowController.h"
#import "DDClientStateMaintenanceManager.h"
#import "DDTcpClientManager.h"
#import "PFMoveApplication.h"
#import "DDServiceAccountModule.h"
//Portable Duoduo prefs key

#define PORTABLE_ADIUM_KEY					@"Preference Folder Location"
#define ALWAYS_RUN_SETUP_WIZARD FALSE

@implementation DDAppDelegate
{
    BOOL _showMainWindow;
}
#pragma mark Core Controllers
@synthesize interfaceController;



-(id)init{
    self =[super self];
    if (self) {
        NSString *logPath = [[self applicationSupportDirectory] stringByAppendingPathComponent:@"duoduo_log.txt"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self applicationSupportDirectory]]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[self applicationSupportDirectory]
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:NULL];
        }
        
        //设置默认记录级别
        [[L4Logger rootLogger] setLevel:[L4Level all]];
        //定义输出目标与日志模板
        [[L4Logger rootLogger] addAppender: [[L4RollingFileAppender alloc] initWithLayout:[L4Layout simpleLayout] fileName:logPath]];
        //自初始化并定义日志实例
        L4Logger *theLogger = [L4Logger loggerForClass:[L4FunctionLogger class]];
        [theLogger setLevel:[L4Level all]];
        
        setSharedDuoduo(self);

    }
    return self;
}



//duoduo is almost done lauching,init
- (void)applicationWillFinishLaunching:(NSNotification *)notification{
    
    PFMoveToApplicationsFolderIfNecessary();
    
    signal(SIGPIPE, SIG_IGN);
    
    //cocoa程序获取url scheme传入参数
    _showMainWindow = NO;
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
    log4CInfo(@"applicationWillFinishLaunching");
}


//duoduo has finished lauching.
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    [[DDApplicationUpdate instance] startAutoCheckUpdateAtOnce];
    //应用程序初始化相关
    [StateMaintenanceManager instance];
    [DDClientStateMaintenanceManager shareInstance];
    [DDServiceAccountModule shareInstance];
    [DDMessageModule shareInstance];
    
    log4CInfo(@"applicationDidFinishLaunching");
    if(nil == _loginWindowController)
    {
        _loginWindowController = [[DDLoginWindowController alloc] initWithWindowNibName:@"LoginSelect"];
    }
//    [DDMainWindowController instance];
    [_loginWindowController showWindow:nil];
    [_loginWindowController.window makeKeyAndOrderFront:nil];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    DDLog(@" --");
}

/*!
 * @brief Returns the location of Duoduo's preference folder
 *
 * This may be specified in our bundle's info dictionary keyed as PORTABLE_ADIUM_KEY
 * or, by default, be within the system's 'application support' directory.
 */
- (NSString *)applicationSupportDirectory
{
	//Path to the preferences folder
	static NSString *_preferencesFolderPath = nil;
	
    //Determine the preferences path if neccessary
	if (!_preferencesFolderPath) {
		_preferencesFolderPath = [[[[NSBundle mainBundle] infoDictionary] objectForKey:PORTABLE_ADIUM_KEY] stringByExpandingTildeInPath];
		if (!_preferencesFolderPath)
			_preferencesFolderPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Duoduo 1.0"];
	}
	
	return _preferencesFolderPath;
}


- (void)applicationWillTerminate:(NSNotification *)notification{
    DDLog(@"applicationWillTerminate begin...");
    
    [[DDApplicationInstance instance] shutdown];
    
    DDLog(@"applicationWillTerminate done");
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    BOOL result;
    if (flag) {
        if (_showMainWindow)
        {
            [[DDMainWindowController instance].window makeKeyAndOrderFront:nil];
        }
        result = NO;
    }
    else
    {
        if (_showMainWindow)
        {
            [[[DDMainWindowController instance] window] makeKeyAndOrderFront:self];
        }
        else
        {
            [[_loginWindowController window] makeKeyAndOrderFront:self];
        }
        
        result = YES;
    }
    
    return result;
}

- (void)applicationWillBecomeActive:(NSNotification *)notification
{
    if (_showMainWindow)
    {
        DDMessageModule* messageModule = [DDMessageModule shareInstance];
        DDSessionModule* sessionModule = [DDSessionModule shareInstance];
        NSString* chattingSessionID = [sessionModule chatingSessionID];
        if ([messageModule countMessageBySessionId:chattingSessionID] > 0)
        {
            DDLog(@"------------------------------------>applicationWillBecomeeActive:%@",chattingSessionID);
            [[DDMainWindowController instance] openChatViewByUserId:chattingSessionID];
        }
    }
}

- (void)showMainWindowController
{
    _showMainWindow = YES;
    [[DDMainWindowController instance].window makeKeyAndOrderFront:nil];
    [_loginWindowController close];
}

@end


