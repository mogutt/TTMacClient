//
//  DDReceiveP2PMessageAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-12.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDReceiveP2PMessageAPI.h"

@implementation DDReceiveP2PMessageAPI
/**
 *  数据包中的serviceID
 *
 *  @return serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_P2P;
}

/**
 *  数据包中的commandID
 *
 *  @return commandID
 */
- (int)responseCommandID
{
    return CMD_P2P_CMD_DATA;
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
        uint32_t seqNo = [bodyData readInt];
        NSString *fromUserId = [bodyData readUTF];
        NSString *toId = [bodyData readUTF];
        NSString *content = [bodyData readUTF];
        
        return @{@"seqNo":@(seqNo),
                 @"fromUserID":fromUserId,
                 @"toUserId":toId,
                 @"content":content};
    };
    return analysis;
}

@end
