//
//  DDRecentContactsModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-29.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDRecentContactsModule.h"
#import "DDRecentConactsAPI.h"
#import "DDRecentGroupAPI.h"
#import "DDUserlistModule.h"
#import "DDGroupModule.h"
#import "UserEntity.h"
#import "GroupEntity.h"
#import "SessionEntity.h"
#import "DDSessionModule.h"
#import "DDUnreadMessageUserAPI.h"
#import "DDUsersUnreadMessageAPI.h"
#import "DDGetOfflineFileAPI.h"
#import "SpellLibrary.h"
#import "DDPathHelp.h"
#import "DDSetting.h"
#import "DDGroupInfoAPI.h"
#import "DDUserInfoAPI.h"
#import "DDDatabaseUtil.h"
#define RECETNT_CONTACTS_PLIST_FILE                 @"RecentPerson.plist"

typedef void(^RecentUsersCompletion)();
typedef void(^RecentGroupCompletion)();
typedef void(^LoadTopSessionCompletion)();
typedef void(^LoadLocalRecentCOntactsCompletion)();

@interface DDRecentContactsModule(PrivateAPI)

- (void)p_loadRecentUsers:(RecentUsersCompletion)completion;
- (void)p_loadRecentGroups:(RecentGroupCompletion)completion;

- (void)p_mergerUsersAndGroups;


- (NSString*)p_plistPath;
- (void)p_loadLocalRecentContactsCompletion:(LoadLocalRecentCOntactsCompletion)completion;
- (void)p_loadTopSession:(LoadTopSessionCompletion)completion;

@end

@implementation DDRecentContactsModule
{
    BOOL _finishedLoadRecentUsers;
    BOOL _finishedLoadRecentGroups;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _finishedLoadRecentGroups = NO;
        _finishedLoadRecentUsers = NO;
    }
    return self;
}

- (void)loadRecentContacts:(LoadRecentContactsCompletion)completion
{
    [self p_loadLocalRecentContactsCompletion:^{
        [self p_mergerUsersAndGroups];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
    }];
    //获取最近联系用户
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
        [self p_loadRecentUsers:^{
            [[DDSundriesCenter instance] pushTaskToSerialQueue:^{

                _finishedLoadRecentUsers = YES;
                if (_finishedLoadRecentGroups && _finishedLoadRecentUsers)
                {
                    [self p_loadTopSession:^{
                        [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                            [self p_mergerUsersAndGroups];
                            [self saveRecentContacts];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                log4Info(@"获取最近联系人成功");
                                completion(sessionModule.recentlySessionIds);
                            });

                        }];
                    }];
                }
            }];
        }];
        
        [self p_loadRecentGroups:^{
            [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                _finishedLoadRecentGroups = YES;
                if (_finishedLoadRecentUsers && _finishedLoadRecentGroups)
                {
                    [self p_loadTopSession:^{
                        [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                            [self p_mergerUsersAndGroups];
                            [self saveRecentContacts];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                log4Info(@"获取最近联系人成功");
                                completion(sessionModule.recentlySessionIds);
                            });
                        }];
                    }];
                }
            }];

        }];
        
    }];
}

- (void)saveRecentContacts
{
    NSMutableArray* recentContacts = [[NSMutableArray alloc] init];
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    
    for(NSString* groupID in groupModule.recentlyGroupIds)
    {
        GroupEntity* group = [groupModule getGroupByGId:groupID];
        [recentContacts addObject:group];
    }
    
    for(NSString* uId in userModule.recentlyUserIds)
    {
        UserEntity* user = [userModule getUserById:uId];
        if (user)
        {
            [recentContacts addObject:user];
        }
    }
    
    [[DDDatabaseUtil instance] updateRecentUsers:recentContacts completion:^(BOOL success) {
        if (success)
        {
            DDLog(@"保存最近联系人成功");
        }
        else
        {
            log4Error(@"保存最近联系人失败");
        }
    }];
}

#pragma mark PrivateAPI

- (void)p_loadRecentUsers:(RecentUsersCompletion)completion
{

    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    DDRecentConactsAPI* contactsApi = [[DDRecentConactsAPI alloc] init];
    [contactsApi requestWithObject:nil Completion:^(id response, NSError *error) {
        if (!error)
        {
            [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                NSArray* recentlyUsers = (NSArray*)response;
                if (!userModule.recentlyUserIds)
                {
                    userModule.recentlyUserIds = [[NSMutableArray alloc] init];
                }
                for (NSString* userID in recentlyUsers)
                {
                    if (![userModule.recentlyUserIds containsObject:userID] && ![userModule isInIgnoreUserList:userID])
                    {
                        [userModule.recentlyUserIds addObject:userID];
                    }
                }
                [self saveRecentContacts];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });

            }];
        }
        else
        {
            [self p_loadRecentUsers:completion];
            DDLog(@"error:%@",[error domain]);
        }
    }];
}

- (void)p_loadRecentGroups:(RecentGroupCompletion)completion
{
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    DDRecentGroupAPI* groupApi = [[DDRecentGroupAPI alloc] init];
    [groupApi requestWithObject:nil Completion:^(id response, NSError *error) {
        if (!error)
        {
            [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                NSArray* recentlyGroups = (NSArray*)response;
                if (!groupModule.recentlyGroupIds) {
                    groupModule.recentlyGroupIds = [[NSMutableArray alloc] init];
                }
                for(GroupEntity* group in recentlyGroups)
                {
//                    if ([group.name isEqualToString:@"MIT"])
//                    {
//                    static int index = 0;
//                    index ++;
//                        DDLog(@"----------->%@  %i",group.name,index);
//                    }
                    if (![groupModule.recentlyGroupIds containsObject:group.groupId]) {
                        [groupModule addGroup:group];
                        [[SpellLibrary instance] addSpellForObject:group];
                        [groupModule.recentlyGroupIds addObject:group.groupId];
                    }
                    else
                    {
                        GroupEntity* oldGroup = [groupModule getGroupByGId:group.groupId];
                        oldGroup.groupUserIds = [group.groupUserIds mutableCopy];
                        oldGroup.name = [group.name copy];
                    }
                }
                [self saveRecentContacts];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }];
        }
        else
        {
            [self p_loadRecentGroups:completion];
            DDLog(@"error:%@",[error domain]);
        }
    }];
}

- (void)p_mergerUsersAndGroups
{
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    
    NSArray* arrUserIds = userModule.recentlyUserIds;
    for(NSString* groupID in groupModule.recentlyGroupIds)
    {
        GroupEntity* group = [groupModule getGroupByGId:groupID];
        SessionEntity* session = [[SessionEntity alloc] init];
        session.sessionId = group.groupId;
        session.lastSessionTime = group.groupUpdated;
        session.type = SESSIONTYPE_GROUP;
        if (![sessionModule.recentlySessionIds containsObject:session.sessionId])
        {
            [sessionModule addSession:session];
            [sessionModule.recentlySessionIds addObject:session.sessionId];
        }
    }
    
    for(NSString* uId in arrUserIds)
    {
        SessionEntity* session = [[SessionEntity alloc] init];
        session.sessionId = uId;
        session.type = SESSIONTYPE_SINGLE;
        UserEntity* user = [userModule getUserById:uId];
        session.lastSessionTime = user.userUpdated;
        if (![sessionModule.recentlySessionIds containsObject:session.sessionId])
        {
            [sessionModule addSession:session];
            [sessionModule.recentlySessionIds addObject:session.sessionId];
        }
    }
}

- (void)p_loadLocalRecentContactsCompletion:(LoadLocalRecentCOntactsCompletion)completion
{
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    [[DDDatabaseUtil instance] loadRecentUsersCompletion:^(NSArray *contacts,NSError* error) {
        [contacts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[UserEntity class]])
            {
                UserEntity* user = (UserEntity*)obj;
                if ([userModule isInIgnoreUserList:user.userId])
                {
                    return;
                }
                if (!userModule.recentlyUserIds)
                {
                    userModule.recentlyUserIds = [[NSMutableArray alloc] init];
                }
                [userModule.recentlyUserIds addObject:user.userId];
                [userModule addUser:user];
            }
            else if ([obj isKindOfClass:[GroupEntity class]])
            {
                GroupEntity* group = (GroupEntity*)obj;
                if (!groupModule.recentlyGroupIds)
                {
                    groupModule.recentlyGroupIds = [[NSMutableArray alloc] init];
                }
                [groupModule addGroup:group];
                [[SpellLibrary instance] addSpellForObject:group];
                [groupModule.recentlyGroupIds addObject:group.groupId];
            }
        }];
        completion();
    }];
    /*
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    NSString *plistPath = [self p_plistPath];
    
    if([fileManager fileExistsAtPath:plistPath])
    {
        NSArray* array = [[NSArray alloc] initWithContentsOfFile:plistPath];
        DDUserlistModule* userModule = [DDUserlistModule shareInstance];
        DDGroupModule* groupModule = [DDGroupModule shareInstance];
        [[DDSundriesCenter instance] pushTaskToSynchronizationSerialQUeue:^{

            [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary* dic = (NSDictionary*)obj;
                int type = [dic[@"EntityType"] intValue];
                if (type == 2)
                {
                    UserEntity* user = [[UserEntity alloc] init];
                    user.userId = dic[@"ID"];
                    user.name = dic[@"name"];
                    user.userUpdated = [dic[@"lastTime"] intValue];
                    user.userRole = [dic[@"userRole"] intValue];
                    user.avatar = dic[@"avatar"];
                    if ([userModule isInIgnoreUserList:user.userId])
                    {
                        return;
                    }
                    if (!userModule.recentlyUserIds)
                    {
                        userModule.recentlyUserIds = [[NSMutableArray alloc] init];
                    }
                    [userModule.recentlyUserIds addObject:user.userId];
                    [userModule addUser:user];
                }
                else
                {
                    GroupEntity* group = [[GroupEntity alloc] init];
                    group.groupId = dic[@"ID"];
                    group.name = dic[@"name"];
                    group.groupUserIds = dic[@"grouMembers"];
                    group.groupType = [dic[@"type"] intValue];
                    group.groupUpdated = [dic[@"lastTime"] intValue];
                    group.groupCreatorId = dic[@"creatorId"];
                    
                    if (!groupModule.recentlyGroupIds)
                    {
                        groupModule.recentlyGroupIds = [[NSMutableArray alloc] init];
                    }
                    [groupModule addGroup:group];
                    [[SpellLibrary instance] addSpellForObject:group];
                    [groupModule.recentlyGroupIds addObject:group.groupId];
                }
            }];
        }];

    }*/
}


- (NSString*)p_plistPath
{
    DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
    NSString* myName = [[userListModule myUser] userId];
    
    NSString* directorPath = [[DDPathHelp applicationSupportDirectory] stringByAppendingPathComponent:myName];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    BOOL isDirector = NO;
    BOOL isExiting = [fileManager fileExistsAtPath:directorPath isDirectory:&isDirector];
    
    if (!(isExiting && isDirector))
    {
        BOOL createDirection = [fileManager createDirectoryAtPath:directorPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
        if (!createDirection)
        {
            DDLog(@"create director");
        }
    }
    
    
    NSString *plistPath = [directorPath stringByAppendingPathComponent:RECETNT_CONTACTS_PLIST_FILE];
    return plistPath;
}

- (void)p_loadTopSession:(LoadTopSessionCompletion)completion
{
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    
    DDSetting* setting = [DDSetting instance];
    NSArray* topSession = [setting getTopSessionIDs];
    __block NSUInteger finishedCount = 0;
    NSUInteger count = [topSession count];
    if (count == 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
        return;
    }
    for (NSUInteger index = 0; index < [topSession count]; index ++)
    {
        NSString* ID = topSession[index];
        if (![groupModule getGroupByGId:ID] && ![userModule getUserById:ID])
        {
            if ([ID hasPrefix:GROUP_PRE])
            {
                DDGroupInfoAPI* groupInfo = [[DDGroupInfoAPI alloc] init];
                [groupInfo requestWithObject:[ID substringFromIndex:[GROUP_PRE length]] Completion:^(id response, NSError *error)
                 {
                     finishedCount ++;
                     if (!error)
                     {
                         [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                             GroupEntity* group = (GroupEntity*)response;
                             if (![groupModule.recentlyGroupIds containsObject:group.groupId])
                             {
                                 [groupModule addGroup:group];
                                 [[SpellLibrary instance] addSpellForObject:group];
                                 [groupModule.recentlyGroupIds addObject:group.groupId];
                             }
                             if (finishedCount == count)
                             {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     completion();
                                 });
                             }
                         }];
                         
                     }
                 }];
            }
            else
            {
                DDUserInfoAPI* userInfo = [[DDUserInfoAPI alloc] init];
                [userInfo requestWithObject:@[ID] Completion:^(id response, NSError *error)
                 {
                     finishedCount ++;
                     if (!error)
                     {
                         [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                             UserEntity* user = (UserEntity*)response[0];
                             if (![userModule.recentlyUserIds containsObject:user.userId])
                             {
                                 [userModule addUser:user];
                                 [userModule.recentlyUserIds addObject:user.userId];
                             }
                             if (finishedCount == count)
                             {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     completion();
                                 });
                             }
                         }];
                     }
                 }];
            }
        }
        else
        {
            finishedCount ++;
            if (finishedCount == count)
            {
                if (finishedCount == count)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            }
        }
    }
}
@end
