//
//  DDSendMessageAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-8.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDSendMessageAPI.h"

@implementation DDSendMessageAPI
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
    return CMD_MSG_DATA;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_MSG_DATA_ACK;
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
        uint32_t seqNo = [bodyData readInt];
        NSString *fromUserId = [bodyData readUTF];
        log4CInfo(@"message ack from userID：%@",fromUserId);
        
        return [NSNumber numberWithInt:seqNo];
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
    Package package = (id)^(id object,uint16_t seqNo)
    {
        
        NSArray* array = (NSArray*)object;
        NSString* fromId = array[0];
        NSString* toId = array[1];
        NSString* content = array[2];
        int messageSeqNo = [array[3] intValue];
        uint8 type = [array[4] intValue];
        
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = strLen(fromId) + strLen(toId) + strLen(content) + 4 * 6 + IM_PDU_HEADER_LEN + sizeof(type);
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_MESSAGE cId:CMD_MSG_DATA seqNo:seqNo];
        [dataout writeInt:messageSeqNo];
        [dataout writeUTF:fromId];
        [dataout writeUTF:toId];
        [dataout writeInt:0];   //createTime.
        [dataout writeChar:type];
//        [dataout writeChar:1];
        [dataout writeUTF:content];
        [dataout writeInt:0];
        log4CInfo(@"sendMsg serviceID:%i cmdID:%i",MODULE_ID_MESSAGE,CMD_MSG_DATA);
        return [dataout toByteArray];
    };
    return package;
}

@end
