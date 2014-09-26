//
//  DDFileServerLoginAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-21.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDFileServerLoginAPI.h"

@implementation DDFileServerLoginAPI
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
    return MODULE_ID_FILETRANSFER;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_FILETRANSFER;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_FILE_LOGIN_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_FILE_LOGIN_RES;
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
        DataInputStream *inputData = [DataInputStream dataInputStreamWithData:data];
        uint32_t result = [inputData readInt];
        DDLog(@"handleFileLoginRes, result=%d", result);
        return [NSNumber numberWithInt:result];
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
        NSString* userId = array[0];
        NSString* taskID = array[1];
        NSString* token = @"asdcvakdsjch";
        int mode = 4;
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = 4 * 4 + IM_PDU_HEADER_LEN + strLen(userId)+ strLen(taskID) + strLen(token);
        
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_FILETRANSFER cId:CMD_FILE_LOGIN_REQ seqNo:seqNo];
        [dataout writeUTF:userId];
        [dataout writeUTF:token];
        [dataout writeUTF:taskID];
        [dataout writeInt:mode];
        return [dataout toByteArray];
    };
    return package;
}

@end
