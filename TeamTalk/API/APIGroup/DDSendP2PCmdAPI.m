//
//  DDSendP2PCmdAPI.m
//  Duoduo
//
//  Created by jianqing.du on 14-5-12.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDSendP2PCmdAPI.h"

@implementation DDSendP2PCmdAPI

#pragma public
+ (NSString*)contentFor:(int)serverID commandID:(int)commandID content:(NSString*)content
{
    //@"{\"CmdID\":\"5308417\",\"Content\":\"shakewindow\",\"ServiceID\":\"1\"}"
    NSString* theContent = [NSString stringWithFormat:@"{\"CmdID\":%i,\"Content\":\"%@\",\"ServiceID\":%i}",commandID,content,serverID];
    return theContent;
}

#pragma APIScheduleProtocol
/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutTimeInterval
{
    return 0;
}

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID
{
    return MODULE_ID_P2P;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return 0;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_P2P_CMD_DATA;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return 0;
}

/**
 *  解析数据的block
 *
 *  @return 解析数据的block
 */
- (Analysis)analysisReturnData
{
    return nil;
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
        
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = strLen(fromId) + strLen(toId) + strLen(content) + IM_PDU_HEADER_LEN + 16;
        DDLog(@"  getSendP2PCmd: 消息长度:%d",totalLen);
        
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_P2P cId:CMD_P2P_CMD_DATA seqNo:seqNo];
        [dataout writeInt:messageSeqNo];
        [dataout writeUTF:fromId];
        [dataout writeUTF:toId];
        [dataout writeUTF:content];
        log4CInfo(@"sendP2PCmd serviceID:%i cmdID:%i",MODULE_ID_P2P, CMD_P2P_CMD_DATA);
        return [dataout toByteArray];
    };
    return package;
}

@end
