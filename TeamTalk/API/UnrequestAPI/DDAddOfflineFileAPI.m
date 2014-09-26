//
//  DDAddOfflineFileAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-12.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDAddOfflineFileAPI.h"
#import "DDFileEntity.h"
@implementation DDAddOfflineFileAPI
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
    return CMD_FILE_ADD_OFFLINE_REQ;
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
        DDFileEntity* fileEntity = (DDFileEntity*)object;
    
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = IM_PDU_HEADER_LEN + 5 * 4 +
        strLen(fileEntity.fromUserID) + strLen(fileEntity.toUserID) + strLen(fileEntity.taskID) + strLen(fileEntity.fileName) ;
        
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_FILETRANSFER cId:CMD_FILE_ADD_OFFLINE_REQ seqNo:seqNo];
        
        [dataout writeUTF:fileEntity.fromUserID];
        [dataout writeUTF:fileEntity.toUserID];
        [dataout writeUTF:fileEntity.taskID];
        [dataout writeUTF:fileEntity.fileName];
        [dataout writeInt:(int)fileEntity.fileSize];
        
        return [dataout toByteArray];
    };
    return package;
}
@end
