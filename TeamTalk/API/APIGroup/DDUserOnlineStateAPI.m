//
//  DDUserOnlineStateAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-8.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDUserOnlineStateAPI.h"

@implementation DDUserOnlineStateAPI
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
    return CMD_FRI_LIST_STATE_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_FRI_LIST_STATE_RES;
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
        uint32_t userCnt = [bodyData readInt];
        NSMutableDictionary* userListStats = [[NSMutableDictionary alloc] init];
        for (uint32_t i = 0; i < userCnt; i ++)
        {
            NSString* userID = [bodyData readUTF];
            int state = [bodyData readInt];
            [userListStats setObject:[NSNumber numberWithInt:state] forKey:userID];
        }
        return userListStats;
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
        NSArray* users = (NSArray*)object;
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        int totalLen = IM_PDU_HEADER_LEN;
        totalLen += 4;
        uint32_t userCnt = (uint32_t)[users count];
        for (uint32_t i = 0; i < userCnt; i++) {
            totalLen += 4 + strLen((NSString*)[users objectAtIndex:i]);
        }
        
        [dataout writeInt:totalLen];
        
        [dataout writeTcpProtocolHeader:MODULE_ID_FRIENDLIST
                                    cId:CMD_FRI_LIST_STATE_REQ
                                  seqNo:seqNo];
        
        [dataout writeInt:(int)[users count]];
        for (uint32_t i = 0; i < userCnt; i++) {
            NSString *userId = (NSString*)[users objectAtIndex:i];
            [dataout writeUTF:userId];
        }
        return [dataout toByteArray];
    };
    return package;
}
@end
