//
//  DDPullFileDataEntity.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDPullFileDataEntity.h"

@implementation DDPullFileDataEntity
- (id)initWithTaskID:(NSString*)taskID userID:(NSString*)userID mode:(int)mode offset:(int)offset dataSize:(int)dataSize
{
    self = [super init];
    if (self)
    {
        _taskID = [taskID copy];
        _userID = [userID copy];
        _mode = mode;
        _offset = offset;
        _dataSize = dataSize;
    }
    return self;
}
@end
