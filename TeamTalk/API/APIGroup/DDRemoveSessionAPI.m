//
//  DDRemoveSessionAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-12.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDRemoveSessionAPI.h"

@implementation DDRemoveSessionAPI

/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutTimeInterval
{
    return 10;
}

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID
{
    return MODULE_ID_FRIENDLIST;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_FRIENDLIST;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_FRI_REMOVE_SESSION_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_FRI_REMOVE_SESSION_RES;
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
        uint32_t result = [bodyData readInt];
        NSMutableDictionary *dict = nil;
        if (result != 0)
        {
            return dict;
        }
        uint32_t sessionType = [bodyData readInt];
        NSString* sessionID = [bodyData readUTF];
        
        dict = [[NSMutableDictionary alloc] init];
        [dict setObject: [NSNumber numberWithInt:result] forKey:@"result"];
        [dict setObject: [NSNumber numberWithInt:sessionType] forKey:@"sessionType"];
        [dict setObject:sessionID forKey:@"sessionId"];
        return dict;
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
        NSString* sessionID = array[0];
        int sessionType = [array[1] intValue];
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = IM_PDU_HEADER_LEN + 8 + strLen(sessionID) ;
        
        [dataout writeInt:totalLen];
        
        int16_t  serverId = MODULE_ID_FRIENDLIST;
        int16_t  commandId = CMD_FRI_REMOVE_SESSION_REQ;
        [dataout writeTcpProtocolHeader:serverId cId:commandId seqNo:seqNo];
        [dataout writeInt:sessionType];
        [dataout writeUTF:sessionID];
        log4CInfo(@"serviceID:%i cmdID:%i -->  remove session sessionType:%i session ID: %@",serverId,commandId,sessionType,sessionID);
        return [dataout toByteArray];
    };
    return package;
}

@end
