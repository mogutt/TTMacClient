//
//  DDOrganizationAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-19.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDOrganizationAPI.h"
#import "DepartmentEntity.h"
@implementation DDOrganizationAPI
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
    return CMD_ORGANIZATION_INFO_REQ;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_ORGANIZATION_INFO_RES;
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
        
        uint32_t departmentCnt = [bodyData readInt];
        NSMutableArray *departmentList = [[NSMutableArray alloc] init];
        
        for (uint32_t i = 0; i < departmentCnt; i++) {
            NSString* departmentID = [bodyData readUTF];
            NSString* title = [bodyData readUTF];
            NSString* description = [bodyData readUTF];
            NSString* parentDepartID = [bodyData readUTF];
            NSString* leaderID = [bodyData readUTF];
            int status = [bodyData readInt];
            DepartmentEntity *department = [[DepartmentEntity alloc] initWithID:departmentID title:title description:description parentID:parentDepartID leaderID:leaderID status:status];

            [departmentList addObject:department];
        }
        
        DDLog(@"userListHandler, userCnt=%u", departmentCnt);
        return departmentList;
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
                                    cId:CMD_ORGANIZATION_INFO_REQ
                                  seqNo:seqNo];
        log4CInfo(@"serviceID:%i cmdID:%i --> get all user",MODULE_ID_FRIENDLIST,CMD_FRI_ALL_USER_REQ);
        return [dataout toByteArray];
    };
    return package;
}
@end
