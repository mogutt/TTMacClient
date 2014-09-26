//
//  DDReceiveFileStateNotifyAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-22.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDReceiveFileStateNotifyAPI.h"

@implementation DDReceiveFileStateNotifyAPI
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
    return CMD_FILE_NOTIFY_STATE;
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
        ClientFileState state = [bodyData readInt];
        NSString *taskID = [bodyData readUTF];
        NSString *userID = [bodyData readUTF];
        DDFileServerNotifyEntity* notifyEntity = [[DDFileServerNotifyEntity alloc] initWithState:state taskID:taskID userID:userID];
        return notifyEntity;
    };
    return analysis;
}

@end
