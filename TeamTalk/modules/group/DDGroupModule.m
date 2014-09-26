/************************************************************
 * @file         DDGroupModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       群主列表管理
 ************************************************************/

#import "DDGroupModule.h"
#import "GroupEntity.h"
#import "SessionEntity.h"
#import "MessageEntity.h"
#import "DDSessionModule.h"
#import "DDMessageModule.h"
#import "SpellLibrary.h"
#import "DDMainModule.h"
#import "DDUserlistModule.h"
#import "DDSetting.h"

#import "DDReceiveGroupAddMemberAPI.h"
#import "DDReceiveGroupDeleteMemberAPI.h"
#import "DDGroupInfoAPI.h"

@interface DDGroupModule()

-(void)onHandleTcpData:(uint16)cmdId data:(id)data;
-(void)addGroup:(GroupEntity*)newGroup;
-(void)registerAPI;


@end

@implementation DDGroupModule
{
    NSArray* _ignoreGroups;
}

+ (instancetype)shareInstance
{
    
    static DDGroupModule* g_rootModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_rootModule = [[DDGroupModule alloc] init];
    });
    return g_rootModule;
}

-(id) init
{
    if(self = [super init])
    {
        _allGroups = [[NSMutableDictionary alloc] init];
        _allFixedGroup = [[NSMutableDictionary alloc] init];
        _ignoreGroups = @[];
        [self registerAPI];
    }
    return self;
}

-(BOOL)isInIgnoreGroups:(NSString*)groupID
{
    return [_ignoreGroups containsObject:groupID];
}

-(void)addGroup:(GroupEntity*)newGroup
{
    if (!newGroup)
    {
        return;
    }
    GroupEntity* group = newGroup;
    if([self isContainGroup:newGroup.groupId])
    {
        group = [_allGroups valueForKey:newGroup.groupId];
        [group copyContent:newGroup];
    }
    [_allGroups setObject:group forKey:group.groupId];
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    NSArray* recentleSession = [sessionModule recentlySessionIds];
    if ([recentleSession containsObject:group.groupId] &&
        ![sessionModule getSessionBySId:group.groupId])
    {
        //针对最近联系人列表中出现的空白行的情况
        SessionEntity* session = [[SessionEntity alloc] init];
        session.sessionId = group.groupId;
        session.type = group.groupType + 1;
        session.lastSessionTime = group.groupUpdated;
        [sessionModule addSession:session];

        [[NSNotificationCenter defaultCenter] postNotificationName:RELOAD_RECENT_ESSION_ROW object:group.groupId];
    }
    newGroup = nil;
}

- (void)addFixedGroup:(GroupEntity*)newGroup
{
    GroupEntity* group = newGroup;
    if([self isFixGroupsContainGroup:newGroup.groupId])
    {
        group = [_allFixedGroup valueForKey:newGroup.groupId];
        [group copyContent:newGroup];
    }
    [_allFixedGroup setObject:group forKey:group.groupId];
    newGroup = nil;
}


-(GroupEntity*)getGroupByGId:(NSString*)gId
{
    return [_allGroups valueForKey:gId];
}

-(BOOL)isContainGroup:(NSString*)gId
{
    return ([_allGroups valueForKey:gId] != nil);
}

- (BOOL)isFixGroupsContainGroup:(NSString*)gId
{
    return ([_allFixedGroup valueForKey:gId] != nil);
}

-(NSArray*)getAllGroups
{
    return [_allGroups allValues];
}

-(NSArray*)getAllFixedGroups
{
    return [_allFixedGroup allValues];
}

- (void)getGroupInfogroupID:(NSString*)groupID completion:(GetGroupInfoCompletion)completion
{
    NSString* lookGroupID = [groupID hasPrefix:GROUP_PRE] ? groupID : [NSString stringWithFormat:@"%@%@",GROUP_PRE,groupID];
    GroupEntity* localGroup = [self getGroupByGId:lookGroupID];
    if (localGroup)
    {
        completion(localGroup);
        return;
    }
    DDGroupInfoAPI* groupInfo = [[DDGroupInfoAPI alloc] init];
    
    NSString* serverGroupID = [lookGroupID substringFromIndex:[GROUP_PRE length]];
    
    [groupInfo requestWithObject:serverGroupID Completion:^(id response, NSError *error) {
        if (!error)
        {
            GroupEntity* group = (GroupEntity*)response;
            if (group)
            {
                [self addGroup:group];
            }
            completion(group);
        }
        else
        {
            DDLog(@"error:%@ groupID:%@",[error domain],groupID);
            [self getGroupInfogroupID:groupID completion:completion];
        }
    }];
}

- (void)registerAPI
{
    DDReceiveGroupAddMemberAPI* addmemberAPI = [[DDReceiveGroupAddMemberAPI alloc] init];
    [addmemberAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        if (!error)
        {
            
            GroupEntity* groupEntity = (GroupEntity*)object;
            if (!groupEntity)
            {
                return;
            }
            if ([self getGroupByGId:groupEntity.groupId])
            {
                //自己本身就在组中
                [[DDMainWindowController instance] updateCurrentChattingViewController];
            }
            else
            {
                //自己被添加进组中
                
                groupEntity.groupUpdated = [[NSDate date] timeIntervalSince1970];
                [self addGroup:groupEntity];
                DDSessionModule* sessionModule = [DDSessionModule shareInstance];
                [sessionModule createGroupSession:groupEntity.groupId type:GROUP_TYPE_TEMPORARY];
                [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:nil];
            }
        }
        else
        {
            DDLog(@"error:%@",[error domain]);
        }
    }];
    
    DDReceiveGroupDeleteMemberAPI* deleteMemberAPI = [[DDReceiveGroupDeleteMemberAPI alloc] init];
    [deleteMemberAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        if (!error)
        {
            GroupEntity* groupEntity = (GroupEntity*)object;
            if (!groupEntity)
            {
                return;
            }
            DDUserlistModule* userModule = [DDUserlistModule shareInstance];
            if ([groupEntity.groupUserIds containsObject:userModule.myUserId])
            {
                //别人被踢了
                [[DDMainWindowController instance] updateCurrentChattingViewController];
            }
            else
            {
                //自己被踢了
                [self.recentlyGroupIds removeObject:groupEntity.groupId];
                DDSessionModule* sessionModule = [DDSessionModule shareInstance];
                [sessionModule.recentlySessionIds removeObject:groupEntity.groupId];
                DDMessageModule* messageModule = [DDMessageModule shareInstance];
                [messageModule popArrayMessage:groupEntity.groupId];
                [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:nil];
            }
        }
    }];
}

@end
