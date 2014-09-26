/************************************************************
 * @file         DDMessageModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       消息管理模块
 ************************************************************/

#import <Foundation/Foundation.h>
#import "DDIntranetMessageEntity.h"
#import "DDRootModule.h"

#define MSG_TYPE_SINGLE_FLAG    0x00
#define MSG_TYPE_GROUP_FLAG     0x10

#define CHECK_MSG_TYPE_GROUP(msg_type) \
({\
bool bRet = false;\
if ((msg_type & MSG_TYPE_GROUP_FLAG) == MSG_TYPE_GROUP_FLAG)\
{\
bRet = true;\
}\
bRet;\
})


enum {
    
	MSG_TYPE_SINGLE_TEXT       = MSG_TYPE_SINGLE_FLAG + 0x01,
    MSG_TYPE_SINGLE_AUDIO      = MSG_TYPE_SINGLE_FLAG + 0x02,
    MSG_TYPE_GROUP_TEXT     = MSG_TYPE_GROUP_FLAG + 0x01,
    MSG_TYPE_GROUP_AUDIO    = MSG_TYPE_GROUP_FLAG + 0x02,
};

typedef void(^LoadAllUnReadMessageCompletion)(NSError* error);

@class MessageEntity;
@class SessionEntity;
@class DDSendMessageAckManager;
@interface DDMessageModule : DDRootModule
{
    NSMutableDictionary*                _allUnReadedMessages; //所有未读消息 key:session id  value:message array
    NSMutableDictionary*                _historyMsgOffset;
    DDSendMessageAckManager*            _sendMsgAckManager;
    NSMutableDictionary*                _intranetUnreadMessages;
    NSMutableDictionary*                _unSendAckMessages;
}


/**
 *  插入到未读消息维护数据中
 *
 *  @param sessionId 会话ID
 *  @param msgEntity 未读消息
 *
 *  @return 是否维护成功
 */
-(BOOL)pushMessage:(NSString*)sessionId message:(MessageEntity*)msgEntity;

/**
 *  批量插入未读消息维护数据
 *
 *  @param msgEntities 未读消息
 *  @param sessionID   会话ID
 *
 *  @return 是否维护成功
 */
-(BOOL)pushMessages:(NSArray*)msgEntities sessionID:(NSString*)sessionID;

/**
 *  获得相应会话的未读消息中的最早的一条消息,并使这条消息从未读消息中移除
 *
 *  @param sessionId 相应的会话ID
 *
 *  @return 消息
 */
-(MessageEntity*)popMessage:(NSString*)sessionId;

/**
 *  获得相应会话的未读消息中的最早的一条消息,这条消息不从未读消息中移除
 *
 *  @param sessionId 相应的会话ID
 *
 *  @return 消息
 */
//-(MessageEntity*)frontMessage:(NSString*)sessionId;

/**
 *  获得某个会话的未读消息，同时这个函数会把这些消息写入到历史消息数据库中
 *
 *  @param sessionId 会话ID
 *
 *  @return 此会话的未读消息
 */
-(NSArray*)popArrayMessage:(NSString*)sessionId;

/**
 *  从未读消息中移除相应会话的未读消息，不插入到历史消息数据库
 *
 *  @param sessionId 会话ID
 */
-(void)removeArrayMessage:(NSString*)sessionId;

/**
 *  获得相应会话的未读消息数量
 *
 *  @param sessionId 会话ID
 *
 *  @return 未读消息数量
 */
-(NSUInteger)countMessageBySessionId:(NSString*)sessionId;

/**
 *  获得所有的未读消息数量
 *
 *  @return 未读消息数量s
 */
-(NSUInteger)countUnreadMessage;

/**
 *  判断是否有未读消息
 *
 *  @return 是否有未读消息
 */
- (BOOL)hasUnreadedMessage;

- (NSArray*)haveUnreadMessagesSessionIDs;

//历史消息相关
//-(void)tcpSendHistoryMsgReq:(SessionEntity*)session msgOffset:(uint32_t)msgOffset;
-(void)countHistoryMsgOffset:(NSString*)sId offset:(uint32)offset;

//消息ack相关
-(void)fetchAllUnReadMessageCompletion:(LoadAllUnReadMessageCompletion)completion;

- (void)addUnreadMessage:(DDIntranetMessageEntity*)message inIntranetForSessionID:(NSString*)sessionID;
- (NSUInteger)countOfUnreadIntranetMessageForSessionID:(NSString*)sessionID;
- (void)clearAllUnreadMessageInIntranetForSessionID:(NSString*)sessionID;

/**
 *  模拟发送消息
 *
 *  @param message   消息
 *  @param sessionID 会话ID
 */
- (void)addUnreadMessage:(MessageEntity *)message forSessionID:(NSString *)sessionID;
@end

