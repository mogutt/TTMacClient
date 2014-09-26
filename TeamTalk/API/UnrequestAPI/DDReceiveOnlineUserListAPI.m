//
//  DDReceiveOnlineUserListAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-8.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDReceiveOnlineUserListAPI.h"

@implementation DDReceiveOnlineUserListAPI
/**
 *  数据包中的serviceID
 *
 *  @return serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_FRIENDLIST;
}

/**
 *  数据包中的commandID
 *
 *  @return commandID
 */
- (int)responseCommandID
{
    return CMD_FRI_USERLIST_ONLINE_STATE;
}

/**
 *  解析数据包
 *
 *  @return 解析数据包的block
 */
- (UnrequestAPIAnalysis)unrequestAnalysis
{
    UnrequestAPIAnalysis analysis = (id)^(NSData* data)
    {
        DataInputStream* bodyData = [DataInputStream dataInputStreamWithData:data];
        NSMutableDictionary* dictStatus = [[NSMutableDictionary alloc] init];
        [bodyData readShort]; //NSInteger listType ,这里只是读出.
        NSInteger friendCnt = [bodyData readInt];
        DDLog(@" \n\n\n\n\n\n在线好友状态列表:%ld",friendCnt);
        for(int i =0;i<friendCnt;i++)
        {
            NSString *userId= [bodyData readUTF];
            int32_t onlineStatus = [bodyData readInt];
            [dictStatus setObject: [NSNumber numberWithInt:onlineStatus] forKey:userId];
        }
        return dictStatus;
    };
    return analysis;
}

@end
