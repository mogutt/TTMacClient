//
//  DDMsgServerIPAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-6.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDMsgServerIPAPI.h"
#import "LoginEntity.h"
@implementation DDMsgServerIPAPI
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
    return MODULE_ID_LOGIN;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_LOGIN;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_LOGIN_REQ_MSGSERVER;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_LOGIN_RES_MSGSERVER;
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
        NSInteger result = [bodyData readInt];
        LoginEntity* logEntity = [[LoginEntity alloc] init];
        logEntity.result = result;
        if (result == 0)
        {
            logEntity.ip1 = [bodyData readUTF];
            logEntity.ip2 = [bodyData readUTF];
            logEntity.port = [bodyData readShort];
        }
        return logEntity;
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
        uint32_t totalLen = IM_PDU_HEADER_LEN;
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_LOGIN cId:CMD_LOGIN_REQ_MSGSERVER seqNo:seqNo];
        DDLog(@"login msgServer serviceID:%i cmdID:%i",MODULE_ID_LOGIN,CMD_LOGIN_REQ_MSGSERVER);
        NSData* data = [dataout toByteArray];
        log4CInfo(@"login msgServer serviceID:%i cmdID:%i",MODULE_ID_LOGIN,CMD_LOGIN_REQ_MSGSERVER);
        return [dataout toByteArray];
    };
    return package;
}
@end
