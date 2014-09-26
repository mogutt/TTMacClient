
/************************************************************
 * @file         DDMessageModule.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       消息管理模块
 ************************************************************/

#import "DDMessageModule.h"
#import "MessageEntity.h"
#import "SessionEntity.h"
#import "DDDatabaseUtil.h"
#import "DDReceiveMessageAPI.h"
#import "DDSetting.h"
#import "DDUserMsgReadACKAPI.h"
#import "DDGroupMsgReadACKAPI.h"
#import "DDUserMsgReceivedACKAPI.h"
#import "DDUnreadMessageUserAPI.h"
#import "DDUsersUnreadMessageAPI.h"
#import "DDUnreadMessageGroupAPI.h"
#import "DDGroupsUnreadMessageAPI.h"
#import "DDReceiveP2PMessageAPI.h"
#import "DDSessionModule.h"
#import "DDGroupModule.h"
#import "DDUserlistModule.h"
#import "GroupEntity.h"
#import "DDSendP2PCmdAPI.h"
#import "DDClientState.h"
#import "DDServiceAccountModule.h"
static CGFloat const shouleShowTiemInterval = 120;

typedef void(^FetchHasUnreadMessageUsersCompletion)(NSArray* users);
typedef void(^FetchHasUnreadMessageGroupsCompletion)(NSArray* groups);
typedef void(^FetchUserUnreadMessageCompletion)(NSInteger lastTime);
typedef void(^FetchGroupUnreadMessageCompletion)(NSInteger lastTime);


@interface DDMessageModule(PrivateAPI)

- (void)p_RegisterAPI;
- (void)p_updateUnreadMessageInStatuAndDock;
- (void)p_fetchUnreadMessageUsers:(FetchHasUnreadMessageUsersCompletion)completion;
- (void)p_fetchUnreadMessageGroups:(FetchHasUnreadMessageGroupsCompletion)completion;
- (void)p_fetchUserUnreadMessage:(NSString*)userID completion:(FetchUserUnreadMessageCompletion)completion;
- (void)p_fetchGroupUnreadMessage:(NSString*)groupID completion:(FetchGroupUnreadMessageCompletion)completion;
- (BOOL)p_exitInUnSendAckMessages:(MessageEntity*)message;
@end

@implementation DDMessageModule

+ (instancetype)shareInstance
{
    
    static DDMessageModule* g_rootModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_rootModule = [[DDMessageModule alloc] init];
    });
    return g_rootModule;
}

-(id)init
{
    if(self = [super init])
    {
        _allUnReadedMessages = [[NSMutableDictionary alloc] init];
        _historyMsgOffset = [[NSMutableDictionary alloc] init];
        _intranetUnreadMessages = [[NSMutableDictionary alloc] init];
        _unSendAckMessages = [[NSMutableDictionary alloc] init];
        [[DDClientState shareInstance] addObserver:self
                                        forKeyPath:DD_USER_STATE_KEYPATH
                                           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                           context:nil];
        [self p_RegisterAPI];
    }
    return self;
}

- (void)dealloc
{
    [[DDClientState shareInstance] removeObserver:self forKeyPath:DD_USER_STATE_KEYPATH];
}

-(BOOL)pushMessage:(NSString*)sessionId message:(MessageEntity*)msgEntity
{
    NSMutableArray* msgEntityArray = [_allUnReadedMessages valueForKey:sessionId];
    if(!msgEntityArray)
    {
        msgEntityArray = [[NSMutableArray alloc] init];
        [_allUnReadedMessages setValue:msgEntityArray forKey:sessionId];
    }
    [msgEntityArray addObject:msgEntity];
    [self p_updateUnreadMessageInStatuAndDock];
    return YES;
}

-(BOOL)pushMessages:(NSArray*)msgEntities sessionID:(NSString*)sessionID
{
    NSMutableArray* msgEntityArray = [_allUnReadedMessages valueForKey:sessionID];
    if(!msgEntityArray)
    {
        msgEntityArray = [[NSMutableArray alloc] init];
        [_allUnReadedMessages setValue:msgEntityArray forKey:sessionID];
    }
    [msgEntityArray addObjectsFromArray:msgEntities];
    [self p_updateUnreadMessageInStatuAndDock];
    return YES;

}

-(MessageEntity*)popMessage:(NSString*)sessionId
{
    @synchronized(self)
    {
        NSMutableArray* msgEntityArray = [_allUnReadedMessages valueForKey:sessionId];
        if(msgEntityArray && msgEntityArray.count > 0)
        {
            MessageEntity* msgEntity = [msgEntityArray objectAtIndex:0];
            [msgEntityArray removeObjectAtIndex:0];
            [self p_updateUnreadMessageInStatuAndDock];
            return msgEntity;
        }
        
        return nil;
    }
}

-(MessageEntity*)frontMessage:(NSString*)sessionId
{
    @synchronized(self)
    {
        NSMutableArray* msgEntityArray = [_allUnReadedMessages valueForKey:sessionId];
        if(msgEntityArray && msgEntityArray.count > 0)
        {
            return [msgEntityArray objectAtIndex:0];
        }
        return nil;
    }
}

-(void)removeArrayMessage:(NSString*)sessionId
{
    if(!sessionId)
        return;
    @synchronized(self)
    {
        [_allUnReadedMessages removeObjectForKey:sessionId];
        [self p_updateUnreadMessageInStatuAndDock];
    }
}

-(NSArray*)popArrayMessage:(NSString*)sessionId
{
    if(!sessionId)
        return nil;
    @synchronized(self)
    {
        NSArray* msgEntityArray = [_allUnReadedMessages valueForKey:sessionId];
        [_allUnReadedMessages removeObjectForKey:sessionId];
        [self p_updateUnreadMessageInStatuAndDock];
        [[DDDatabaseUtil instance] insertMessages:msgEntityArray
                                          success:^{
                                              
                                          }
                                          failure:^(NSString *errorDescripe) {
                                              DDLog(@"%@",errorDescripe);
                                          }];
        if(![DDClientState shareInstance].userState != DDUserOnline)
        {
            //用户离线
            if (msgEntityArray)
            {
                [_unSendAckMessages setObject:msgEntityArray forKey:sessionId];
            }
        }
        return msgEntityArray;
    }
}

-(NSUInteger)countMessageBySessionId:(NSString*)sessionId
{
    @synchronized(self)
    {
        NSArray* msgEntityArray = [_allUnReadedMessages valueForKey:sessionId];
        if(msgEntityArray)
        {
            return [msgEntityArray count];
        }
        return 0;
    }
}

-(NSUInteger)countUnreadMessage
{
    @synchronized(self)
    {
        __block NSUInteger count = 0;
        [_allUnReadedMessages enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSArray* unreadMessageForSession = (NSArray*)obj;
            NSInteger messageCount = [unreadMessageForSession count];
            count += messageCount;
        }];
        return count;
    }
}

- (BOOL)hasUnreadedMessage
{
    if ([_allUnReadedMessages count] > 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (NSArray*)haveUnreadMessagesSessionIDs
{
    return [_allUnReadedMessages allKeys];
}

-(void)countHistoryMsgOffset:(NSString*)sId offset:(uint32)offsetValue
{
    @synchronized(self)
    {
        NSNumber* offset = [_historyMsgOffset objectForKey:sId];
        if(offset)
        {
            uint32 offsetCount = (uint32)[offset integerValue];
            offsetCount += offsetValue;
            offset = nil;
            offset = [NSNumber numberWithUnsignedInteger:offsetCount];
        }
        else
        {
            offset = [NSNumber numberWithUnsignedInteger:offsetValue];
        }
        [_historyMsgOffset setObject:offset forKey:sId];
    }
}


-(void)fetchAllUnReadMessageCompletion:(LoadAllUnReadMessageCompletion)completion
{
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    [self p_fetchUnreadMessageUsers:^(NSArray *users) {
        __block int completionUsers = 0;
        [[DDSundriesCenter instance] pushTaskToSerialQueue:^{

            [users enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
                DDSetting* setting = [DDSetting instance];

                if ([userModule isInIgnoreUserList:obj])
                {
                    [self p_fetchUserUnreadMessage:obj completion:^(NSInteger lastTime) {
                        
                    }];
                }
                else if (![[setting getShieldSessionIDs] containsObject:obj])
                {
                    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
                    [userModule getUserInfoWithUserID:obj completion:^(UserEntity *user) {
                        if (user)
                        {
                            DDSessionModule* sessionModule = [DDSessionModule shareInstance];
                            SessionEntity* session = [sessionModule getSessionBySId:obj];
                            if (!session)
                            {
                                session = [sessionModule createSingleSession:obj];
                            }
                            [self p_fetchUserUnreadMessage:obj completion:^(NSInteger lastTime) {
                                session.lastSessionTime = lastTime;
                                completionUsers ++;
                                if (completionUsers == [users count])
                                {
                                    completion(nil);
                                }
                            }];
                        }
                    }];
                }
                else
                {
                    DDUserMsgReadACKAPI* userMsgReadAck = [[DDUserMsgReadACKAPI alloc] init];
                    [userMsgReadAck requestWithObject:obj Completion:nil];
                }
            }];

        }];
    }];
    
    [self p_fetchUnreadMessageGroups:^(NSArray *groups) {
        [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
            __block int completionGroups = 0;
            [groups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                DDSetting* setting = [DDSetting instance];
                NSString* groupID = [NSString stringWithFormat:@"%@%@",GROUP_PRE,obj];
                if (![[setting getShieldSessionIDs]containsObject:groupID])
                {
                    DDGroupModule* groupModule = [DDGroupModule shareInstance];
                    [groupModule getGroupInfogroupID:obj completion:^(GroupEntity *group) {
                        if (group)
                        {
                            DDSessionModule* sessionModule = [DDSessionModule shareInstance];
                            SessionEntity* session = [sessionModule getSessionBySId:groupID];
                            if (!session)
                            {
                                session = [sessionModule createGroupSession:groupID type:group.groupType];
                            }
                            [self p_fetchGroupUnreadMessage:obj completion:^(NSInteger lastTime) {
                                session.lastSessionTime = lastTime;
                                completionGroups ++;
                                if (completionGroups == [groups count])
                                {
                                    completion(nil);
                                }
                                
                            }];
                        }
                    }];
                }
                else
                {
                    DDGroupMsgReadACKAPI* groupMsgReadAck = [[DDGroupMsgReadACKAPI alloc] init];
                    [groupMsgReadAck requestWithObject:obj Completion:nil];
                }
            }];

        }];
    }];
}

- (void)addUnreadMessage:(DDIntranetMessageEntity*)message inIntranetForSessionID:(NSString*)sessionID
{
    if ([[_intranetUnreadMessages allKeys] containsObject:sessionID])
    {
        NSMutableArray* unreadMessage = _intranetUnreadMessages[sessionID];
        [unreadMessage addObject:message];
    }
    else
    {
        NSMutableArray* unreadMessage = [[NSMutableArray alloc] init];
        [unreadMessage addObject:message];
        [_intranetUnreadMessages setObject:unreadMessage forKey:sessionID];
    }
    [self p_updateUnreadMessageInStatuAndDock];
}

- (NSUInteger)countOfUnreadIntranetMessageForSessionID:(NSString*)sessionID
{
    NSArray* unreadMessages = _intranetUnreadMessages[sessionID];
    return [unreadMessages count];
}

- (void)clearAllUnreadMessageInIntranetForSessionID:(NSString*)sessionID
{
    [self p_updateUnreadMessageInStatuAndDock];
    [_intranetUnreadMessages removeAllObjects];
}

#pragma mark -
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:DD_USER_STATE_KEYPATH])
    {
        DDUserState oldState = [change[NSKeyValueChangeOldKey] intValue];
        switch ([DDClientState shareInstance].userState)
        {
            case DDUserOnline:
                if (oldState != DDUserOnline)
                {
                    
                }
                break;
            default:
                break;
        }
    }
}
- (void)addUnreadMessage:(MessageEntity *)message forSessionID:(NSString *)sessionID
{
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    SessionEntity* session = [sessionModule getSessionBySId:message.sessionId];
    if (!session)
    {
        [sessionModule createSingleSession:message.sessionId];
    }
    [self pushMessage:message.sessionId message:message];
    //发送收到消息通知
    [NotificationHelp postNotification:notificationReceiveMessage userInfo:nil object:message];
}

#pragma mark privateAPI
- (void)p_RegisterAPI
{
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    DDGroupModule* grouModule = [DDGroupModule shareInstance];
    DDReceiveMessageAPI* receiveMessageAPI = [[DDReceiveMessageAPI alloc] init];
    [receiveMessageAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        MessageEntity* msg = (MessageEntity*)object;
        if(nil == msg)
            return;
        //判断是不是服务消息
        if ([[DDServiceAccountModule shareInstance] isServiceAccount:msg.senderId])
        {
            ServiceAction serviceAction = [[DDServiceAccountModule shareInstance]regcognizeTheAction:msg.msgContent];
            if (serviceAction != ActionNone)
            {
                NSString* actionContent = [[DDServiceAccountModule shareInstance] recognizeTheContent:msg.msgContent];
                [[DDServiceAccountModule shareInstance] performTheAction:serviceAction withContent:actionContent];
                DDUserMsgReadACKAPI* readACK = [[DDUserMsgReadACKAPI alloc] init];
                [readACK requestWithObject:msg.sessionId Completion:nil];
                return;
            }
        }
        //判断是否在屏蔽的会话列表中
        NSArray* shieldSessions = [[DDSetting instance] getShieldSessionIDs];
        if ([shieldSessions containsObject:msg.sessionId] || [userModule isInIgnoreUserList:msg.sessionId])
        {
            //插入历史消息数据库
            [[DDDatabaseUtil instance] insertMessage:msg success:^{
                //发送已读确认
                if (msg.msgType == MESSAGE_TYPE_SINGLE)
                {
                    DDUserMsgReadACKAPI* readACK = [[DDUserMsgReadACKAPI alloc] init];
                    [readACK requestWithObject:msg.sessionId Completion:nil];
                }
                else
                {
                    DDGroupMsgReadACKAPI* readACK = [[DDGroupMsgReadACKAPI alloc] init];
                    [readACK requestWithObject:msg.orginId Completion:nil];
                }

            } failure:^(NSString *errorDescripe) {
                DDLog(@"%@",errorDescripe);
            }];
            return;
        }
        
        if ([msg.sessionId hasPrefix:GROUP_PRE])
        {
            if (![grouModule isInIgnoreGroups:msg.sessionId])
            {
                DDGroupModule* groupModule = [DDGroupModule shareInstance];
                [groupModule getGroupInfogroupID:msg.orginId completion:^(GroupEntity *group) {
                    if (group)
                    {
                        DDLog(@"收到群消息通知－－－－");
                        DDSessionModule* sessionModule = [DDSessionModule shareInstance];
                        SessionEntity* session = [sessionModule getSessionBySId:msg.sessionId];
                        if (!session)
                        {
                            [sessionModule createGroupSession:msg.sessionId type:group.groupType];
                        }
                        
                        [self pushMessage:msg.sessionId message:msg];
                        //发送收到消息通知
                        [NotificationHelp postNotification:notificationReceiveMessage userInfo:nil object:msg];
                    }
                }];
            }
        }
        else
        {
            if (![userModule isInIgnoreUserList:msg.sessionId])
            {
                [userModule getUserInfoWithUserID:msg.orginId completion:^(UserEntity *user) {
                    if (user)
                    {
                        DDSessionModule* sessionModule = [DDSessionModule shareInstance];
                        SessionEntity* session = [sessionModule getSessionBySId:msg.sessionId];
                        if (!session)
                        {
                            [sessionModule createSingleSession:msg.sessionId];
                        }
                        [self pushMessage:msg.sessionId message:msg];
                        //发送收到消息通知
                        [NotificationHelp postNotification:notificationReceiveMessage userInfo:nil object:msg];
                    }
                }];
            }
        }
        
        if(MESSAGE_TYPE_SINGLE == msg.msgType)
        {
            
            DDUserMsgReceivedACKAPI* receivedACK = [[DDUserMsgReceivedACKAPI alloc] init];
            NSArray* array = @[msg.orginId,[NSNumber numberWithInt:msg.seqNo]];
            [receivedACK requestWithObject:array Completion:nil];
        }
        
    }];
    
    DDReceiveP2PMessageAPI* receiveP2PMessageAPI = [[DDReceiveP2PMessageAPI alloc] init];
    [receiveP2PMessageAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        
        NSDictionary* dic = (NSDictionary*)object;
        NSData* contentData = [dic[@"content"] dataUsingEncoding:NSUTF8StringEncoding];
        if (!contentData)
        {
            return;
        }
        NSDictionary* contentDic = [NSJSONSerialization JSONObjectWithData:contentData options:0 error:nil];
        if (!contentDic)
        {
            return;
        }
        NSMutableDictionary* newDic = [[NSMutableDictionary alloc] initWithDictionary:object];
        [newDic setObject:contentDic forKey:@"content"];
        //{\"CmdID\":\"%i\",\"Content\":\"%@\",\"ServiceID\":\"%i\"}
        NSUInteger cmdID = [contentDic[@"CmdID"] integerValue];
        NSUInteger serviceID = [contentDic[@"ServiceID"] integerValue];
        
        if (cmdID == SHAKE_WINDOW_COMMAND && serviceID == SHAKE_WINDOW_SERVICEID)
        {
            //收到抖屏
            
            [NotificationHelp postNotification:notificationReceiveP2PShakeMessage userInfo:nil object:newDic];
            
        }
        else if (cmdID == INPUTING_COMMAND && serviceID == INPUTING_SERVICEID)
        {
            //正在输入
            [NotificationHelp postNotification:notificationReceiveP2PInputingMessage userInfo:nil object:newDic];
        }
        else if (cmdID == STOP_INPUTTING_COMMAND && serviceID == INPUTING_SERVICEID)
        {
            //停止正在输入
            [NotificationHelp postNotification:notificationReceiveP2PStopInputingMessage userInfo:nil object:newDic];
        }
        else if (cmdID == INTRANET_COMMAND && serviceID == INTRANET_SERVICEID)
        {
            NSDictionary* content = newDic[@"content"];
            NSString* author = content[@"Author"];
            NSString* contentString = content[@"Content"];
            NSUInteger time = [content[@"Time"] integerValue];
            NSString* fromUserID = newDic[@"fromUserID"];
            DDIntranetMessageEntity* intranetMessage = [[DDIntranetMessageEntity alloc] initWithAuthor:author content:contentString time:time fromUserID:fromUserID];
            [self addUnreadMessage:intranetMessage inIntranetForSessionID:fromUserID];
            DDUserMsgReadACKAPI* userMsgReadACK = [[DDUserMsgReadACKAPI alloc] init];
            [userMsgReadACK requestWithObject:fromUserID Completion:^(id response, NSError *error) {
                
            }];
            [NotificationHelp postNotification:notificationReceiveP2PIntranetMessage userInfo:nil object:newDic];
        }
    }];
    
//    DDReceiveP2PWritingMessageAPI* receiceP2PWritingAPI = [[DDReceiveP2PWritingMessageAPI alloc] init];
//    [receiceP2PWritingAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
//        [NotificationHelp postNotification:notificationReceiveP2PInputingMessage userInfo:nil object:object];
//    }];
//    
//    DDReceiveP2PStopWritingMessageAPI* receiveStopWritingAPI = [[DDReceiveP2PStopWritingMessageAPI alloc] init];
//    [receiveStopWritingAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
//        [NotificationHelp postNotification:notificationReceiveP2PStopInputingMessage userInfo:nil object:object];
//    }];
}

- (void)p_updateUnreadMessageInStatuAndDock
{
    NSInteger count = [self countUnreadMessage];
    [[DDMainWindowController instance] renderTotalUnreadedCount:count];
}

- (void)p_fetchUnreadMessageUsers:(FetchHasUnreadMessageUsersCompletion)completion
{
    DDUnreadMessageUserAPI* unreadMessageUserAPI = [[DDUnreadMessageUserAPI alloc] init];
    [unreadMessageUserAPI requestWithObject:nil Completion:^(id response, NSError *error) {
        if (!error)
        {
            completion(response);
        }
        else
        {
            [self p_fetchUnreadMessageUsers:completion];
            DDLog(@"error:%@",[error domain]);
        }
    }];
}

- (void)p_fetchUnreadMessageGroups:(FetchHasUnreadMessageGroupsCompletion)completion
{
    DDUnreadMessageGroupAPI* unreadMessageGroupAPI = [[DDUnreadMessageGroupAPI alloc] init];
    [unreadMessageGroupAPI requestWithObject:nil Completion:^(id response, NSError *error) {
        if (!error)
        {
            NSArray* groups = (NSArray*)response;
            [groups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj isEqualToString:@"14cp2"])
                {
                    DDLog(@"asd");
                }
                DDLog(@"%@",obj);
            }];
            completion(groups);
        }
        else
        {
            [self p_fetchUnreadMessageGroups:completion];
            DDLog(@"error:%@",error);
        }
    }];
}

- (void)p_fetchUserUnreadMessage:(NSString*)userID completion:(FetchUserUnreadMessageCompletion)completion
{
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    DDUsersUnreadMessageAPI* usersUnreadMessageAPI = [[DDUsersUnreadMessageAPI alloc] init];
    [usersUnreadMessageAPI requestWithObject:userID Completion:^(id response, NSError *error) {
        if (!error)
        {
            if ([userModule isInIgnoreUserList:userID])
            {
                NSArray* messages = response[@"msgArray"];
                [messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    MessageEntity* message = (MessageEntity*)obj;
                    NSString* content = message.msgContent;
                    NSData* contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary* contentDic = [NSJSONSerialization JSONObjectWithData:contentData options:0 error:nil];
                    if (contentDic)
                    {
                        NSString* author = contentDic[@"Author"];
                        NSString* contentString = contentDic[@"Content"];
                        NSUInteger time = [contentDic[@"Time"] integerValue];
                        DDIntranetMessageEntity* intranetMessageEntity = [[DDIntranetMessageEntity alloc] initWithAuthor:author content:contentString time:time fromUserID:userID];
                        [self addUnreadMessage:intranetMessageEntity inIntranetForSessionID:userID];
                    }
                }];
            }
            else
            {
                NSDictionary* dic = (NSDictionary*)response;
                NSString* sessionID = dic[@"sessionId"];
                NSArray* messages = dic[@"msgArray"];
                [self removeArrayMessage:sessionID];
                NSInteger lastTime = 0;
                NSMutableArray* messageEntities = [NSMutableArray array];
                for (NSInteger index = [messages count] - 1; index >= 0; index --)
                {
                    MessageEntity* message = messages[index];
                    //判断未读消息是否在用户离线的情况下已读了
                    if (![self p_exitInUnSendAckMessages:message])
                    {
                        [messageEntities addObject:message];
                    }
                    lastTime = message.msgTime;
                }
                [self pushMessages:messageEntities sessionID:sessionID];
                completion(lastTime);
            }
        }
        else
        {
            [self p_fetchUserUnreadMessage:userID completion:completion];
            DDLog(@"error:%@",[error domain]);
        }
    }];
}

- (void)p_fetchGroupUnreadMessage:(NSString*)groupID completion:(FetchGroupUnreadMessageCompletion)completion
{
    DDGroupsUnreadMessageAPI* groupsUnreadMessageAPI = [[DDGroupsUnreadMessageAPI alloc] init];
    [groupsUnreadMessageAPI requestWithObject:groupID Completion:^(id response, NSError *error) {
        if (!error)
        {
            NSDictionary* dic = (NSDictionary*)response;
            NSString* sessionID = dic[@"sessionId"];
            NSArray* messages = dic[@"msg"];
            //TODO:如果群不存在
            [self removeArrayMessage:sessionID];
            NSInteger lastTime = 0;
            NSMutableArray* messageEntities = [NSMutableArray array];
            for (NSInteger index = [messages count] - 1; index >= 0; index --)
            {
                MessageEntity* message = messages[index];
                if (![self p_exitInUnSendAckMessages:message])
                {
                    [messageEntities addObject:message];
                }
                lastTime = message.msgTime;

            }
            [self pushMessages:messageEntities sessionID:sessionID];
            completion(lastTime);
        }
        else
        {
            [self p_fetchGroupUnreadMessage:groupID completion:completion];
            DDLog(@"error:%@",[error domain]);
        }
        
    }];
}

- (BOOL)p_exitInUnSendAckMessages:(MessageEntity*)message
{
    NSString* sessionID = message.sessionId;
    NSArray* messages = _unSendAckMessages[sessionID];
    __block BOOL exit = NO;
    [messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MessageEntity* objectMessage = (MessageEntity*)obj;
        if ([objectMessage isEqualToMessage:message])
        {
            exit = YES;
            *stop = YES;
        }
    }];
    return exit;
}

@end
