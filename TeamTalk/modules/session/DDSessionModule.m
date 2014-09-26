/************************************************************
 * @file         DDSessionModule.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       会话模块
 ************************************************************/

#import "DDSessionModule.h"
#import "DDMessageModule.h"
#import "DDUserlistModule.h"
#import "DDGroupModule.h"
#import "DDModuleID.h"
#import "MessageEntity.h"
#import "SessionEntity.h"
#import "GroupEntity.h"
#import "UserEntity.h"
#import "DDSetting.h"
#import "DDDatabaseUtil.h"
#import "DDGroupInfoAPI.h"
#import "DDUserInfoAPI.h"
#import "DDUserMsgReadACKAPI.h"
#import "DDGroupMsgReadACKAPI.h"
#import "DDMessageModule.h"

@interface DDSessionModule()

-(void)onHandleTcpData:(uint16)cmdId data:(id)data;

- (void)n_receiveReceiveMessageNotification:(NSNotification*)notification;

@end

@implementation DDSessionModule
{
    NSString* _chattingSessionID;
}

+ (instancetype)shareInstance
{
    
    static DDSessionModule* g_rootModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_rootModule = [[DDSessionModule alloc] init];
    });
    return g_rootModule;
}

-(id)init
{
    if(self = [super init])
    {        
        _allSessions = [[NSMutableDictionary alloc] init];
        _recentlySessionIds = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveReceiveMessageNotification:) name:notificationReceiveMessage object:nil];
        [self addObserver:self forKeyPath:@"_recentlySessionIds" options:0 context:nil];
    }
    return self;   
}

-(void) onLoadModule
{
}



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationReceiveMessage object:nil];
    [self removeObserver:self forKeyPath:@"_recentlySessionIds"];
}

#pragma mark TcpHandle
-(SessionEntity*)getSessionBySId:(NSString*)sId
{
    @synchronized(self)
    {
        return [_allSessions valueForKey:sId];
    }
}

-(BOOL)isContianSession:(NSString*)sId
{
    return ([_allSessions valueForKey:sId] != nil);
}

-(SessionEntity *)createSessionEntity:(NSString *)uid avatar:(NSString *)avatar uname:(NSString *)uname userType:(uint16)userType{
    SessionEntity* newSession = [self getSessionBySId:uid];
    if(newSession)
        return newSession;
    SessionEntity* session = [[SessionEntity alloc] init];
    session.type = SESSIONTYPE_SINGLE;
    session.sessionId = uid;

    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    UserEntity* user = [userModule getUserById:uid];
    session.lastSessionTime = user.userUpdated;
    @synchronized(self)
    {
        [_allSessions setObject:session forKey:uid];
        if (![_recentlySessionIds containsObject:uid])
        {
            [_recentlySessionIds addObject:uid];
        }
    }
    
    return session;
}

-(SessionEntity*)createSingleSession:(NSString*)sId
{

    __block SessionEntity* newSession = nil;
//    [[DDSundriesCenter instance] pushTaskToSynchronizationSerialQUeue:^{
        newSession = [self getSessionBySId:sId];
        if(newSession)
        {
            if (![_recentlySessionIds containsObject:sId])
            {
                if (sId)
                {
                    [_recentlySessionIds addObject:sId];
                }
            }
            return newSession;
        }
        newSession = [[SessionEntity alloc] init];
        newSession.type = SESSIONTYPE_SINGLE;
        newSession.sessionId = sId;
        UserEntity* user = [[DDUserlistModule shareInstance] getUserById:sId];
        newSession.lastSessionTime = user.userUpdated;
        @synchronized(self)
        {
            if (sId)
            {
                [_allSessions setObject:newSession forKey:sId];
            }
            if (![_recentlySessionIds containsObject:sId])
            {
                [_recentlySessionIds addObject:sId];
            }
        }
        
        return newSession;
//    }];
//    return newSession;
}

-(SessionEntity*)createGroupSession:(NSString*)sId type:(int)type
{
    SessionEntity* newSession = [self getSessionBySId:sId];
    if(newSession)
    {
        if (![_recentlySessionIds containsObject:sId]) {
            [_recentlySessionIds addObject:sId];

        }
        return newSession;
    }
    SessionEntity* session = [[SessionEntity alloc] init];
    if (type == 1)
    {
        session.type = SESSIONTYPE_GROUP;
    }
    session.sessionId = sId;
    session.lastSessionTime = [[NSDate date] timeIntervalSince1970];
    @synchronized(self)
    {
        [_allSessions setObject:session forKey:sId];
        if (![_recentlySessionIds containsObject:sId])
        {
            [_recentlySessionIds addObject:sId];
        }
    }
    
    return session;
}

-(void)sortRecentlySessions
{
    @autoreleasepool {
        NSArray* topSessions = [[DDSetting instance] getTopSessionIDs];
        NSMutableArray* recentlySessionIds = [[NSMutableArray alloc] initWithArray:topSessions];
        NSArray* haveUnreadMessages = [[DDMessageModule shareInstance] haveUnreadMessagesSessionIDs];
        if (!recentlySessionIds)
        {
            recentlySessionIds = [[NSMutableArray alloc] init];
        }
        [_recentlySessionIds removeObjectsInArray:recentlySessionIds];
        if([_recentlySessionIds count] > 1)
        {
            [_recentlySessionIds sortUsingComparator:
             ^NSComparisonResult(NSString* sId1, NSString* sId2)
             {
                 SessionEntity* session1 = [self getSessionBySId:sId1];
                 SessionEntity* session2 = [self getSessionBySId:sId2];
                 if ([haveUnreadMessages containsObject:sId1])
                 {
                     return NSOrderedAscending;
                 }
                 if ([haveUnreadMessages containsObject:sId2])
                 {
                     return NSOrderedDescending;
                 }
                 if(session1.lastSessionTime > session2.lastSessionTime)
                     return NSOrderedAscending;
                 else if(session1.lastSessionTime < session2.lastSessionTime)
                     return NSOrderedDescending;
                 else
                     return NSOrderedSame;
             }];
        }
        [recentlySessionIds addObjectsFromArray:_recentlySessionIds];
        _recentlySessionIds = recentlySessionIds;
    
        NSString *npcUserId = nil;
        DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
        for(int index = 0; index < [_recentlySessionIds count]; index ++)
        {
            NSString* sessionID = _recentlySessionIds[index];
            SessionEntity* session = [self getSessionBySId:sessionID];
            if (!session)
            {
                if ([sessionID hasPrefix:@"group"])
                {
                    DDGroupModule* groupModule = [DDGroupModule shareInstance];
                    GroupEntity* group = [groupModule getGroupByGId:sessionID];
                    if (group)
                    {
                        [self createGroupSession:group.groupId type:group.groupType];
                    }
                }
                else
                {
                    [self createSingleSession:sessionID];
                }
//                [_recentlySessionIds removeObject:sessionID];
            }
            UserEntity *tempUser = [userListModule getUserById:sessionID];

            if (tempUser) {
                if((tempUser.userRole & 0x20000000) != 0){
                    npcUserId=sessionID ;
                }
            }
        }
        if (npcUserId) {
            [_recentlySessionIds removeObject:npcUserId];
            [_recentlySessionIds insertObject:npcUserId atIndex:0];
        }
    }
}

-(void)sortAllGroupUsers
{
    @synchronized(self)
    {
        for(NSString* sId in _allSessions)
        {
            SessionEntity* session = [_allSessions objectForKey:sId];
            if(SESSIONTYPE_GROUP == session.type)
                [session sortGroupUsers];
        }
    }
}

-(void)tcpSendReadedAck:(SessionEntity*)session
{
    
    if (session.type == SESSIONTYPE_SINGLE)
    {
        DDUserMsgReadACKAPI* userMsgReadAck = [[DDUserMsgReadACKAPI alloc] init];
        [userMsgReadAck requestWithObject:session.sessionId Completion:nil];
    }
    else
    {
        DDGroupMsgReadACKAPI* groupMsgReadAck = [[DDGroupMsgReadACKAPI alloc] init];
        [groupMsgReadAck requestWithObject:session.orginId Completion:nil];
        
    }
}

-(NSArray *)getAllSessions{
    return [_allSessions allValues];
}

-(NSString*)getLastSession
{
    //因为npc的lastSessionTime是最大的所以这里要把npc排除在外
    NSString* lastSessionID = nil;
    NSInteger updateTime = 0;
    for (NSString* sessionID in _recentlySessionIds)
    {
        DDSessionModule* sessionModule = [DDSessionModule shareInstance];
        SessionEntity* session = [sessionModule getSessionBySId:sessionID];
        UserEntity* user = [[DDUserlistModule shareInstance] getUserById:session.orginId];
        if ((user.userRole & 0x20000000) != 0)
        {
            continue;
        }
        if (session.lastSessionTime > updateTime)
        {
            updateTime = session.lastSessionTime;
            lastSessionID = session.sessionId;
        }
    }
    return lastSessionID;
}

-(void)addSession:(SessionEntity*)session
{
    @autoreleasepool {
        [_allSessions setObject:session forKey:session.sessionId];
    }
//    [_recentlySessionIds addObject:session.sessionId];
}
#pragma mark PrivateAPI
- (void)n_receiveReceiveMessageNotification:(NSNotification*)notification
{
    //如果消息的用户信息不存在，则需要获取
    MessageEntity* msg = [notification object];
    [[DDSundriesCenter instance] pushTaskToSynchronizationSerialQUeue:^{
        
        if(![self.recentlySessionIds containsObject:msg.sessionId])
        {
            if(MESSAGE_TYPE_GROUP == msg.msgType)
            {
                DDGroupModule* groupModule = [DDGroupModule shareInstance];
                GroupEntity* group = [groupModule getGroupByGId:msg.orginId];
                if (group)
                {
                    [self createGroupSession:msg.sessionId type:msg.msgType];
                    [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:msg.sessionId];
                }
                else
                {
                    DDGroupInfoAPI* groupInfoAPI = [[DDGroupInfoAPI alloc] init];
                    [groupInfoAPI requestWithObject:msg.sessionId Completion:^(id response, NSError *error) {
                        if (!error)
                        {
                            if (response)
                            {
                                [groupModule addGroup:response];
                                [self createGroupSession:msg.sessionId type:msg.msgType];
                                [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:msg.sessionId];
                            }
                        }
                    }];
                }
            }
            else
            {
                DDUserlistModule* userModule = [DDUserlistModule shareInstance];
                UserEntity* user = [userModule getUserById:msg.orginId];
                if (user)
                {
                    [self createSingleSession:msg.sessionId];
                    [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:msg.sessionId];
                }
                else
                {
                    DDUserInfoAPI* userInfoAPI = [[DDUserInfoAPI alloc] init];
                    [userInfoAPI requestWithObject:msg.orginId Completion:^(id response, NSError *error) {
                        if (!error)
                        {
                            [userModule addUser:response];
                            [self createSingleSession:msg.sessionId];
                            [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:msg.sessionId];
                        }
                    }];
                }
            }
        }
        else
        {
            SessionEntity* session = [self getSessionBySId:msg.sessionId];
            session.lastSessionTime = [[NSDate date] timeIntervalSince1970];
            [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:nil];
        }
    }];

}

#pragma mark KVO

@end
