//
//  DDChattingContactListModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-22.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDChattingContactListModule.h"
#import "SessionEntity.h"
#import "DDSearch.h"
#import "DDUserlistModule.h"
#import "UserEntity.h"
#import "DDUserInfoAPI.h"
@interface DDChattingContactListModule(PrivateAPI)

- (NSArray*)getGroupUsers;

@end

@implementation DDChattingContactListModule
{
    NSMutableArray* _showUserMember;
    NSArray* _groupUsers;
    NSString* _lastSearchContent;
}

- (void)searchContent:(NSString*)searchContent completion:(Completion)completion
{
    _lastSearchContent = [searchContent copy];
    if (!self.session)
    {
        return;
    }
    
    if ([searchContent length] == 0)
    {
        _showUserMember = [[NSMutableArray alloc] initWithArray:_groupUsers];
        [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
            [self sortGroupUserCompletion:^{
                completion();
            }];
        }];
        return;
    }
    
    NSArray* ranges = [self getGroupUsers];
    
    [[DDSearch instance] searchContent:searchContent inRange:ranges completion:^(NSArray *result, NSError *error) {
        if (!error)
        {
            _showUserMember = [[NSMutableArray alloc] initWithArray:result];
            [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                [self sortGroupUserCompletion:^{
                    completion();
                }];
            }];
        }
    }];
}

- (void)setSession:(SessionEntity *)session
{
    _session = session;
    _showUserMember = [[NSMutableArray alloc] initWithArray:[self getGroupUsers]];
//    [self sortGroupUser];
}


- (NSMutableArray*)showGroupMembers
{
    return _showUserMember;
}

- (void)updateGroupMembersData:(Completion)completion
{
    NSMutableArray* groupUsers = [NSMutableArray array];
    [_session.groupUsers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
        UserEntity* user = [userListModule getUserById:obj];
        if (user && ![groupUsers containsObject:user]) {
            [groupUsers addObject:user];
        }
    }];
    _groupUsers = groupUsers;
    [self searchContent:_lastSearchContent completion:completion];
}

- (void)sortGroupUserCompletion:(Completion)completion
{
    [(NSMutableArray *)_showUserMember sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString* uId1 = [(UserEntity*)obj1 userId];
        NSString* uId2 = [(UserEntity*)obj2 userId];
        StateMaintenanceManager* stateMaintenanceManager = [StateMaintenanceManager instance];
        UserState user1OnlineState = [stateMaintenanceManager getUserStateForUserID:uId1];
        UserState user2OnlineState = [stateMaintenanceManager getUserStateForUserID:uId2];
        if((user1OnlineState == USER_STATUS_ONLINE) &&
           (user2OnlineState == USER_STATUS_LEAVE || user2OnlineState == USER_STATUS_OFFLINE))
        {
            return NSOrderedAscending;
        }
        else if(user1OnlineState == USER_STATUS_LEAVE && user2OnlineState == USER_STATUS_OFFLINE)
        {
            return NSOrderedAscending;
        }
        else if (user2OnlineState == USER_STATUS_ONLINE &&
                 (user1OnlineState == USER_STATUS_LEAVE || user1OnlineState == USER_STATUS_OFFLINE))
        {
            return NSOrderedDescending;
        }
        else if(user2OnlineState == USER_STATUS_LEAVE && user1OnlineState == USER_STATUS_OFFLINE)
        {
            return NSOrderedDescending;
        }
        else
        {
            return NSOrderedSame;
        }
        
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        completion();
    });
}

#pragma mark - private API
- (NSArray*)getGroupUsers
{
    if (!_groupUsers)
    {
        DDUserlistModule* userListModule = [DDUserlistModule shareInstance];

        NSMutableArray* groupUsers = [NSMutableArray array];
        NSMutableArray* unknowUsers = [NSMutableArray array];
        [_session.groupUsers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UserEntity* user = [userListModule getUserById:obj];
            if (!user) {
                [unknowUsers addObject:obj];
            }
            if (user && ![groupUsers containsObject:user]) {
                [groupUsers addObject:user];
            }
        }];
        _groupUsers = groupUsers;
        
        if ([unknowUsers count] > 0)
        {
            DDUserInfoAPI* userInfoAPI = [[DDUserInfoAPI alloc] init];
            [userInfoAPI requestWithObject:unknowUsers Completion:^(id response, NSError *error) {
                [response enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [userListModule addUser:obj];
                }];
                [self updateGroupMembersData:^{
                    [NotificationHelp postNotification:notificationonlineStateChange userInfo:nil object:nil];
                }];

            }];
        }
    }
    return _groupUsers;
}
@end
