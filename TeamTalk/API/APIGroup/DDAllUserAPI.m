//
//  DDAllUserAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-7.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDAllUserAPI.h"
#import "UserEntity.h"

@implementation DDAllUserAPI
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
    return CMD_FRI_ALL_USER_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_FRI_ALL_USER_RES;
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
        NSMutableArray *userList = [[NSMutableArray alloc] init];
        
        for (uint32_t i = 0; i < userCnt; i++) {
            UserEntity *user = [[UserEntity alloc] init];
            user.userId = [bodyData readUTF];
            user.name = [bodyData readUTF];
            user.nick = [bodyData readUTF];
            user.avatar = [bodyData readUTF];
            user.title = [bodyData readUTF];
            user.position = [bodyData readUTF];
            user.roleStatus = [bodyData readInt];
            user.sex = [bodyData readInt];
            user.department = [bodyData readUTF];
            user.jobNum = [bodyData readInt];
            user.telphone = [bodyData readUTF];
            user.email = [bodyData readUTF];
            [userList addObject:user];
        }
        
        DDLog(@"userListHandler, userCnt=%u", userCnt);
        return userList;
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
        
        [dataout writeInt:IM_PDU_HEADER_LEN];
        [dataout writeTcpProtocolHeader:MODULE_ID_FRIENDLIST
                                    cId:CMD_FRI_ALL_USER_REQ
                                  seqNo:seqNo];
        log4CInfo(@"serviceID:%i cmdID:%i --> get all user",MODULE_ID_FRIENDLIST,CMD_FRI_ALL_USER_REQ);
        return [dataout toByteArray];
    };
    return package;
}
@end
