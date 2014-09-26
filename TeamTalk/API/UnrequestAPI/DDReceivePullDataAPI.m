//
//  DDReceivePullDataAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDReceivePullDataAPI.h"
@implementation DDReceivePullDataAPI
/**
 *  数据包中的serviceID
 *
 *  @return serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_FILETRANSFER;
}

/**
 *  数据包中的commandID
 *
 *  @return commandID
 */
- (int)responseCommandID
{
    return CMD_FILE_PULLDATA_REQ;
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
        NSString *taskID = [bodyData readUTF];
        NSString *userID = [bodyData readUTF];
        int mode = [bodyData readInt];
        int offSet = [bodyData readInt];
        int dataSize = [bodyData readInt];
        DDPullFileDataEntity* pullFileDataEntity = [[DDPullFileDataEntity alloc] initWithTaskID:taskID userID:userID mode:mode offset:offSet dataSize:dataSize];
        return pullFileDataEntity;
    };
    return analysis;
}
@end
