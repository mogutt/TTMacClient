//
//  DDGetOfflineFileAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-9.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDGetOfflineFileAPI.h"
#import "DDFileEntity.h"
@implementation DDGetOfflineFileAPI
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
    return MODULE_ID_FILETRANSFER;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_FILE_HAS_OFFLINE_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_FILE_HAS_OFFLINE_RES;
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
        uint32_t fileCnt = [bodyData readInt];
        NSMutableArray *fileList = [[NSMutableArray alloc] init];
        
        for (uint32_t i = 0; i < fileCnt; i++) {
            NSString *fromId = [bodyData readUTF];
            NSString* taskID = [bodyData readUTF];
            NSString *fileName = [bodyData readUTF];
            int fileSize = [bodyData readInt];
            DDFileEntity* fileEntity = [[DDFileEntity alloc] initWithType:ReceiveFileType taskID:taskID fromUserID:fromId toUserID:[DDClientState shareInstance].userID filePath:nil fileName:fileName fileSize:fileSize ips:nil port:0];
            [fileList addObject:fileEntity];
        }
        
        int ipCount = [bodyData readInt];
        NSMutableArray* ips = [[NSMutableArray alloc] init];
        uint16 port;
        for (int index = 0; index < ipCount; index ++)
        {
            NSString* ip = [bodyData readUTF];
            port = [bodyData readShort];
            [ips addObject:ip];
        }
        
        [fileList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DDFileEntity* fileEntity = (DDFileEntity*)obj;
            fileEntity.ips = ips;
            fileEntity.port = port;
        }];
        
        return fileList;
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
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        
        [dataout writeInt:IM_PDU_HEADER_LEN];
        [dataout writeTcpProtocolHeader:MODULE_ID_FILETRANSFER cId:CMD_FILE_HAS_OFFLINE_REQ seqNo:seqNo];
        return [dataout toByteArray];
    };
    return package;
}
@end
