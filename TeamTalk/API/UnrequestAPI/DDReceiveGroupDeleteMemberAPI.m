//
//  DDReceiveGroupDeleteMemberAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-8.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDReceiveGroupDeleteMemberAPI.h"
#import "DDGroupModule.h"
#import "GroupEntity.h"
@implementation DDReceiveGroupDeleteMemberAPI
/**
 *  数据包中的serviceID
 *
 *  @return serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_GROUP;
}

/**
 *  数据包中的commandID
 *
 *  @return commandID
 */
- (int)responseCommandID
{
    return CMD_ID_GROUP_QUIT_GROUP_RES;
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
        uint32_t result = [bodyData readInt];
        GroupEntity *groupEntity = nil;
        if (result != 0)
        {
            return groupEntity;
        }
        NSString *groupId = [bodyData readUTF];
        uint32_t userCnt = [bodyData readInt];
        DDGroupModule* groupModule =  [DDGroupModule shareInstance];
        groupEntity =  [groupModule getGroupByGId:[NSString stringWithFormat:@"group_%@",groupId]];
        if (groupEntity) {
            for (uint32_t i = 0; i < userCnt; i++) {
                NSString* userId = [bodyData readUTF];
                if ([groupEntity.groupUserIds containsObject:userId])
                {
                    [groupEntity.groupUserIds removeObject:userId];
                }
                log4CInfo(@"delete group member success userID:%@",userId);
            }
        }
        
        NSLog(@"result: %d, goupId: %@", result, groupId);
        return groupEntity;
    };
    return analysis;
}
@end
