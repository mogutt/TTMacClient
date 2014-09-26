//
//  DDRecentConactsAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-24.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDRecentConactsAPI.h"
#import "UserEntity.h"
@implementation DDRecentConactsAPI

#pragma mark - DDAPIScheduleProtocol

- (int)requestTimeOutTimeInterval
{
    return 8;
}

- (int)requestServiceID
{
    return MODULE_ID_FRIENDLIST;
}

- (int)responseServiceID
{
    return MODULE_ID_FRIENDLIST;
}

- (int)requestCommendID
{
    return CMD_FRI_REQ_RECENT_LIST;
}

- (int)responseCommendID
{
    return CMD_FRI_RECENT_CONTACTS;
}

- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSData* data)
    {
        DataInputStream* bodyData = [DataInputStream dataInputStreamWithData:data];
        NSInteger userCnt = [bodyData readInt];
        //  NSInteger userCnt = 29;
        DDLog(@"    **** 返回最近联系人列表,有%ld个最近联系人.",userCnt);
        log4CInfo(@"get recent contacts count:%i",userCnt);
        NSMutableArray* recentlyContactContent = [[NSMutableArray alloc] init];
        for (int i=0; i<userCnt; i++) {
            NSString* userID = [bodyData readUTF];
            int userUpdate = [bodyData readInt];
            DDLog(@"%@",userID);
            [recentlyContactContent addObject:userID];
        }
        
        return recentlyContactContent;
    };
    return analysis;
}

- (Package)packageRequestObject
{
    Package package = (id)^(id object,uint32_t seqNo)
    {
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        uint32_t totalLen = IM_PDU_HEADER_LEN + 4;
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_FRIENDLIST cId:CMD_FRI_REQ_RECENT_LIST seqNo:seqNo];
        [dataout writeInt:0];
        log4CInfo(@"get recently users list serviceID:%i cmdID:%i",MODULE_ID_FRIENDLIST,CMD_FRI_REQ_RECENT_LIST);
        return [dataout toByteArray];
    };
    return package;
}
@end
