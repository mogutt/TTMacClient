//
//  DDReceiveStateChangedAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-8.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDReceiveStateChangedAPI.h"

@implementation DDReceiveStateChangedAPI
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
    return CMD_FRI_USER_STATE_CHANGE;
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
        NSString *userId = [bodyData readUTF];
        uint32 onlineStatus = [bodyData readInt];
        [dictStatus setObject: [NSNumber numberWithInt:onlineStatus] forKey:userId];
        
        return dictStatus;
    };
    return analysis;
}
@end
