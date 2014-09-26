//
//  StateMaintenanceManager.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-4.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "StateMaintenanceManager.h"
#import "DDUserlistModule.h"
#import "LoginEntity.h"
#import "UserEntity.h"
#import "DDUserOnlineStateAPI.h"
#import "DDReceiveStateChangedAPI.h"
#import "DDReceiveOnlineUserListAPI.h"
NSString* const notificationonlineStateChange = @"notification_Online_State_Change";

static NSInteger const updateStateInterval = 60;

@interface StateMaintenanceManager(PrivateAPI)

- (void)postTheOnlineStateChangeNotificationWithChangedUsersInfo:(NSDictionary*)changedUserInfo;
- (void)maintanceOnlineStateOnTimer:(NSTimer*)timer;
- (void)receiveUserLoginSuccess:(NSNotification*)notification;
- (void)receiveUserReloginSuccess:(NSNotification*)notification;
- (void)receiveUserOfflineNotification:(NSNotification*)notification;
- (void)p_registerStateMaintenance;
- (void)p_updateOnlineStateUsers;

@end

@implementation StateMaintenanceManager
{
    NSMutableDictionary* _stateMaintenanceInfo;
    NSTimer* _stateMaintenanceTimer;
}
+ (instancetype)instance
{
    static StateMaintenanceManager* g_stateMaintenanceManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_stateMaintenanceManager = [[StateMaintenanceManager alloc] init];
    });
    return g_stateMaintenanceManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _stateMaintenanceInfo = [[NSMutableDictionary alloc] init];
        [self p_registerStateMaintenance];
        [self p_updateOnlineStateUsers];
    }
    return self;
}

- (void)addMaintenanceManagerUserID:(NSString*)userID
{
    if ([userID isEqualToString:@"11m2ec4"])
    {
        DDLog(@"asdx");
    }
    if (userID)
    {
        if (![[_stateMaintenanceInfo allKeys] containsObject:userID]) {
            NSNumber* state = @(USER_STATUS_OFFLINE);
            [_stateMaintenanceInfo setObject:state forKey:userID];
        }
    }
    else
    {
        DDLog(@"error:在线状态");
    }
}

- (UserState)getUserStateForUserID:(NSString*)userID
{
    NSNumber* state = _stateMaintenanceInfo[userID];

    if (!state)
    {
        log4Error(@"get not exit user state,user ID:%@",userID);
        return USER_STATUS_OFFLINE;
    }
    return [state intValue];
}

- (void)offlineAllUser
{
    NSMutableDictionary* changedUserOnlineState = [[NSMutableDictionary alloc] init];
    [_stateMaintenanceInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        NSString* userID = (NSString*)key;
        NSNumber* state = (NSNumber*)obj;
        if ([state intValue] != USER_STATUS_ONLINE)
        {
            [changedUserOnlineState setObject:[NSNumber numberWithInt:USER_STATUS_OFFLINE] forKey:userID];
        }
    }];
    [changedUserOnlineState enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        [_stateMaintenanceInfo setObject:[NSNumber numberWithInt:USER_STATUS_OFFLINE] forKey:key];
    }];
    [self postTheOnlineStateChangeNotificationWithChangedUsersInfo:changedUserOnlineState];
}

- (void)mergerUsersOnlineState:(NSDictionary*)onlineState
{
    NSMutableDictionary* changedUserOnlineState = [[NSMutableDictionary alloc] init];
    DDLog(@"date:%f",[[NSDate date] timeIntervalSince1970]);

//    NSArray* allKey = [_stateMaintenanceInfo allKeys];
//    for (NSInteger index = 0; index < [_stateMaintenanceInfo count]; index ++) {
//        NSString* userID = allKey[index];
//        NSNumber* oldOnlineState = _stateMaintenanceInfo[userID];
//        if (onlineState[userID])
//        {
//            NSNumber* newOnline = onlineState[userID];
//            if (![newOnline isEqual:oldOnlineState])
//            {
//                [changedUserOnlineState setObject:newOnline forKey:userID];
//                [_stateMaintenanceInfo setObject:newOnline forKey:userID];
//            }
//        }
//        else
//        {
//            if (![oldOnlineState isEqualToNumber:@(USER_STATUS_OFFLINE)])
//            {
//                [_stateMaintenanceInfo setObject:@(USER_STATUS_OFFLINE) forKey:userID];
//                [changedUserOnlineState setObject:@(USER_STATUS_OFFLINE) forKey:userID];
//            }
//        }
//    }
//    DDLog(@"date:%f",[[NSDate date] timeIntervalSince1970]);


    [onlineState enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* userID = (NSString*)key;
        NSNumber* onlineState = (NSNumber*)obj;
        NSNumber* oldOnlineState = _stateMaintenanceInfo[userID];
        
        if (![oldOnlineState isEqualToNumber:onlineState])
        {
            [changedUserOnlineState setObject:onlineState forKey:userID];
            [_stateMaintenanceInfo setObject:onlineState forKey:userID];
        }
    }];
    
    NSArray* allUsers = [_stateMaintenanceInfo allKeys];
    NSArray* sendAllKeys = [onlineState allKeys];
    NSString* myID = [[DDUserlistModule shareInstance] myUserId];
    [allUsers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if (![sendAllKeys containsObject:obj] && ![obj isEqualToString:myID])
        {
            [_stateMaintenanceInfo setObject:@(USER_STATUS_OFFLINE) forKey:obj];
        }
    }];
    
    //永远在线的用户
    [self p_updateOnlineStateUsers];
    
    [self postTheOnlineStateChangeNotificationWithChangedUsersInfo:changedUserOnlineState];
}

- (void)updateUsersOnlineStateForUserInDic:(NSDictionary*)onlineState
{
    NSMutableDictionary* changedUserOnlineState = [[NSMutableDictionary alloc] init];
    [onlineState enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* userID = (NSString*)key;
        NSNumber* onlineState = (NSNumber*)obj;
        NSNumber* oldOnlineState = _stateMaintenanceInfo[userID];
        
        if (![oldOnlineState isEqualToNumber:onlineState])
        {
            [changedUserOnlineState setObject:onlineState forKey:userID];
            [_stateMaintenanceInfo setObject:onlineState forKey:userID];
        }
    }];
    [self postTheOnlineStateChangeNotificationWithChangedUsersInfo:changedUserOnlineState];

}

- (UserState)getMyOnlineState
{
    DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
    NSString* myID = userListModule.myUserId;
    NSNumber* state = _stateMaintenanceInfo[myID];
    return [state intValue];
}

- (void)changeMyOnlineState:(UserState)state
{
    DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
    NSString* myID = userListModule.myUserId;
    if (myID)
    {
        [_stateMaintenanceInfo setObject:[NSNumber numberWithInt:state] forKey:myID];
        if (state == USER_STATUS_OFFLINE)
        {
            [[_stateMaintenanceInfo allKeys] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [_stateMaintenanceInfo setObject:[NSNumber numberWithInt:USER_STATUS_OFFLINE] forKey:obj];
            }];
        }
        [self postTheOnlineStateChangeNotificationWithChangedUsersInfo:_stateMaintenanceInfo];
    }
}

- (void)updateUsersOnlineState:(NSArray*)userIDs
{
    NSMutableArray* notExitUsers = [[NSMutableArray alloc] init];
    for (NSString* userID in userIDs)
    {
        if (![[_stateMaintenanceInfo allKeys] containsObject:userID])
        {
            [notExitUsers addObject:userID];
            [_stateMaintenanceInfo setObject:[NSNumber numberWithInt:USER_STATUS_OFFLINE] forKey:userID];
        }
    }
}

- (void)beginMaintanceOnlineState
{
    if (!_stateMaintenanceTimer)
    {
        _stateMaintenanceTimer = [NSTimer scheduledTimerWithTimeInterval:updateStateInterval target:self selector:@selector(maintanceOnlineStateOnTimer:) userInfo:nil repeats:YES];
        [_stateMaintenanceTimer fire];
    }
}

- (void)changeUserOnlineState:(NSString*)userID onlineState:(UserState)state
{
    [_stateMaintenanceInfo setObject:@(state) forKey:userID];
}

- (void)dealloc
{
}

#pragma mark - PrivateAPI
- (void)postTheOnlineStateChangeNotificationWithChangedUsersInfo:(NSDictionary*)changedUserInfo
{
    if ([changedUserInfo count] > 0)
    {
        [NotificationHelp postNotification:notificationonlineStateChange userInfo:nil object:changedUserInfo];
    }
}

- (void)maintanceOnlineStateOnTimer:(NSTimer*)timer
{
    //发包更新用户在线状态
    
    NSArray* allUserInfo = [_stateMaintenanceInfo allKeys];
    if ([allUserInfo count] > 0)
    {
//        DDUserOnlineStateAPI* userOnlineStateAPI = [[DDUserOnlineStateAPI alloc] init];
//        [userOnlineStateAPI requestWithObject:allUserInfo Completion:^(id response, NSError *error) {
//            if (!error)
//            {
//                [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
//                    [self mergerUsersOnlineState:response];
//                }];
//            }
//            else
//            {
//                DDLog(@"error:%@",[error domain]);
//            }
//        }];
    }
}

- (void)receiveUserLoginSuccess:(NSNotification*)notification
{
    if (!_stateMaintenanceTimer)
    {
        _stateMaintenanceTimer = [NSTimer scheduledTimerWithTimeInterval:updateStateInterval target:self selector:@selector(maintanceOnlineStateOnTimer:) userInfo:nil repeats:YES];
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [_stateMaintenanceTimer fire];
        });
//        [_stateMaintenanceTimer fire];
    }
}

- (void)receiveUserOfflineNotification:(NSNotification*)notification
{
    if (_stateMaintenanceTimer)
    {
        [_stateMaintenanceTimer invalidate];
        _stateMaintenanceTimer = nil;
    }
}

- (void)p_registerStateMaintenance
{
    DDReceiveStateChangedAPI* api = [[DDReceiveStateChangedAPI alloc] init];
    [api registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        if (!error)
        {
            NSDictionary* dictStatus = (NSDictionary*)object;
            [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                [[StateMaintenanceManager instance] updateUsersOnlineStateForUserInDic:dictStatus];
            }];
        }
        else
        {
            DDLog(@"error:%@",[error domain]);
        }
    }];
    
    DDReceiveOnlineUserListAPI* onlineUserListAPI = [[DDReceiveOnlineUserListAPI alloc] init];
    [onlineUserListAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        if (!error)
        {
            [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                NSDictionary* dictionStatus = (NSDictionary*)object;
                [dictionStatus enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    [self addMaintenanceManagerUserID:key];
                }];
                if ([dictionStatus count] > 0)
                {
                    [[StateMaintenanceManager instance] mergerUsersOnlineState:dictionStatus];
                }
            }];
        }
        else
        {
            DDLog(@"error:%@",[error domain]);
        }
    }];
}

- (void)receiveUserReloginSuccess:(NSNotification*)notification
{
    [self p_updateOnlineStateUsers];
    if (!_stateMaintenanceTimer)
    {
        _stateMaintenanceTimer = [NSTimer scheduledTimerWithTimeInterval:updateStateInterval target:self selector:@selector(maintanceOnlineStateOnTimer:) userInfo:nil repeats:YES];
        [_stateMaintenanceTimer fire];
    }
}

- (void)p_updateOnlineStateUsers
{
    //小T
    [_stateMaintenanceInfo setValue:@(USER_STATUS_ONLINE) forKey:@"11m2ec4"];
}

@end
