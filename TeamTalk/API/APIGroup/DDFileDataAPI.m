//
//  DDFileDataAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDFileDataAPI.h"

@implementation DDFileDataAPI
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
    return MODULE_ID_FILETRANSFER;
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
    return CMD_FILE_DATA;
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
        int result = [array[0] intValue];
        NSString* taskID = array[1];
        NSString* toUserID = array[2];
        uint32 fileOffset = [array[3] intValue];
        NSData* data = array[4];
        
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = IM_PDU_HEADER_LEN + 4 * 5 + strLen(taskID) + strLen(toUserID) + [data length];
        
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_FILETRANSFER cId:CMD_FILE_DATA seqNo:seqNo];
        [dataout writeInt:result];
        [dataout writeUTF:taskID];
        [dataout writeUTF:toUserID];
        [dataout writeInt:fileOffset];
        [dataout writeBytes:data];
        
        return [dataout toByteArray];

    };
    return package;
}

@end
