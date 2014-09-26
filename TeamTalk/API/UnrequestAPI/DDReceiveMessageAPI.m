//
//  DDReceiveAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-7.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDReceiveMessageAPI.h"
#import "MessageEntity.h"
#import "DDMessageModule.h"
@implementation DDReceiveMessageAPI
/**
 *  数据包中的serviceID
 *
 *  @return serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_MESSAGE;
}


/**
 *  数据包中的commandID
 *
 *  @return commandID
 */
- (int)responseCommandID
{
    return CMD_MSG_DATA;
}

/**
 *  解析数据包
 *
 *  @return 解析数据包的block
 */
- (UnrequestAPIAnalysis)unrequestAnalysis
{
    UnrequestAPIAnalysis analysis = (id)^(NSData* data)
    {
        DataInputStream* bodyData = [DataInputStream dataInputStreamWithData:data];
        uint32 seqNo = [bodyData readInt];
        NSString *fromUserId = [bodyData readUTF];
        NSString *toUserId = [bodyData readUTF];
        uint32 msgTime = [bodyData readInt];
        uint8 msgType = [bodyData readChar];
//        uint8 msgRenderType = [bodyData readChar];
        NSString *msgContent = [bodyData readUTF];
        NSString *attach = [bodyData readUTF];
        
        MessageEntity *msg = [[MessageEntity alloc ] init];
        msg.seqNo = seqNo;
        msg.msgTime = msgTime;
        msg.msgType = msgType;
//        msg.msgRenderType = msgRenderType;
        msg.msgContent = msgContent;
        msg.attach = attach;
        if(CHECK_MSG_TYPE_GROUP(msgType))
        {
            msg.sessionId = toUserId;       //群聊时，toUserId表示会话ID
            msg.senderId = fromUserId;      //群聊时，fromUserId表示发送者ID
            log4CInfo(@"receive group msg from user%@ to user %@ content:%@",msg.sessionId,msg.sessionId,msg.msgContent);
            
        }
        else
        {
            msg.sessionId = fromUserId; //单人时，fromUserId表示发送者ID，作为会话id
            msg.senderId = fromUserId;  //单人时，fromUserId表示发送者ID
            log4CInfo(@"receive single msg from user:%@ content:%@",msg.sessionId,msg.msgContent);
            
        }
        return msg;
    };
    return analysis;
}

@end
