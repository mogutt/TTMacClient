//
//  DDMainWindowControllerModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-15.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDMainWindowControllerModule.h"
#import "DDUserlistModule.h"
#import "UserEntity.h"
#import "DDMessageModule.h"
#import "DDGetOfflineFileAPI.h"
@interface DDMainWindowControllerModule(privateAPI)

- (void)n_receiveReloginNotification:(NSNotification*)notification;

@end

@implementation DDMainWindowControllerModule

- (id)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

#pragma mark - privateAPI
- (void)n_receiveReloginNotification:(NSNotification *)notification
{
    //登陆完成获取个人未读消息
    DDMessageModule* messageModule = [DDMessageModule shareInstance];
    [messageModule fetchAllUnReadMessageCompletion:^(NSError *error) {
        if(!error)
        {
            [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:nil];
        }
    }];
    
    //获取离线文件
    DDGetOfflineFileAPI* getOfflineFileAPI = [[DDGetOfflineFileAPI alloc] init];
    [getOfflineFileAPI requestWithObject:nil Completion:^(id response, NSError *error) {
        if(!error)
        {
            NSMutableArray* entity = (NSMutableArray*)response;
            if ([entity count] > 0)
            {
                
            }
        }
        else
        {
            DDLog(@"error:%@",[error domain]);
        }
    }];
}
@end
