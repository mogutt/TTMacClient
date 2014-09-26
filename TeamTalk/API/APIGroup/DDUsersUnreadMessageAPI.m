//
//  DDUsersUnreadMessageAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-7.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDUsersUnreadMessageAPI.h"
#import "MessageEntity.h"
@implementation DDUsersUnreadMessageAPI
/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutTimeInterval
{
    return 8;
}

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID
{
    return MODULE_ID_MESSAGE;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_MESSAGE;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_MSG_UNREAD_MSG_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_MSG_GET_2_UNREAD_MSG;
}

/**
 *  解析数据的block
 *
 *  @return 解析数据的block
 */
- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSData* data)
    {
        DataInputStream* bodyData = [DataInputStream dataInputStreamWithData:data];
        NSMutableDictionary* msgDict = [[NSMutableDictionary alloc] init];
        NSMutableArray* msgArray = [[NSMutableArray alloc] init];
        NSString *sessionId = [bodyData readUTF];
        uint32_t msgCnt = [bodyData readInt];
        DDLog(@"msgList for session: %@", sessionId);
        
        for (uint32_t i = 0; i < msgCnt; i++)
        {
            NSString *fromUserId = [bodyData readUTF];
            /*NSString *fromUserName = */[bodyData readUTF];
            /*NSString *fromNickName = */[bodyData readUTF];
            /*NSString *fromAvatar = */[bodyData readUTF];
            uint32_t createTime = [bodyData readInt];
            uint8_t msgType = [bodyData readChar];
            NSString *msgContent = [bodyData readUTF];
            
            MessageEntity *msg = [[MessageEntity alloc ] init];
            msg.msgTime = createTime;
            msg.msgType = msgType;
            msg.msgContent = msgContent;
            msg.sessionId = fromUserId;
            msg.senderId = fromUserId;
            
            [msgArray addObject:msg];
            log4CInfo(@"receive msg from:%@ content:%@",fromUserId,msgContent);
        }
        [msgDict setObject:sessionId forKey:@"sessionId"];
        [msgDict setObject:msgArray forKey:@"msgArray"];
        
        return msgDict;
    };
    return analysis;
}

/**
 *  打包数据的block
 *
 *  @return 打包数据的block
 */
- (Package)packageRequestObject
{
    Package package = (id)^(id object,uint32_t seqNo)
    {
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = IM_PDU_HEADER_LEN + 4 + strLen(object);
        
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_MESSAGE
                                    cId:CMD_MSG_UNREAD_MSG_REQ
                                  seqNo:seqNo];
        [dataout writeUTF:object];
        
        log4CInfo(@"serviceID:%i cmdID:%i --> get unread msg from user:%@",MODULE_ID_MESSAGE,CMD_MSG_UNREAD_MSG_REQ,object);
        
        return [dataout toByteArray];
    };
    return package;
}

@end
