//
//  DDPullFileDataAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-25.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDPullFileDataAPI.h"

@implementation DDPullFileDataAPI
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
    return MODULE_ID_FILETRANSFER;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_FILE_PULLDATA_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_FILE_DATA;
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
        int result = [bodyData readInt];
        NSDictionary* dictionary = nil;
        if (result == 0)
        {
            NSString* taskID = [bodyData readUTF];
            NSString* userID = [bodyData readUTF];
            int offset = [bodyData readInt];
            int dataSize = [bodyData readInt];
            NSData* data = [bodyData readLeftData];
            dictionary = @{@"taskID":taskID,
                           @"userID":userID,
                           @"offset":@(offset),
                           @"dataSize":@(dataSize),
                           @"data":data};
        }
        return dictionary;
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
        NSString* taskID = array[0];
        NSString* userID = array[1];
        int mode = [array[2] intValue];
        int offset = [array[3] intValue];
        int dataSize = [array[4] intValue];
        
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = IM_PDU_HEADER_LEN + 4 * 5 + strLen(taskID) + strLen(userID);
        
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_FILETRANSFER cId:CMD_FILE_PULLDATA_REQ seqNo:seqNo];
        [dataout writeUTF:taskID];
        [dataout writeUTF:userID];
        [dataout writeInt:mode];
        [dataout writeInt:offset];
        [dataout writeInt:dataSize];
        
        return [dataout toByteArray];
        
    };
    return package;
}
@end
