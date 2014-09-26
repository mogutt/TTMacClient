//
//  DDFileServerNotifyEntity.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-22.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDFileServerNotifyEntity.h"

@implementation DDFileServerNotifyEntity
- (id)initWithState:(ClientFileState)state taskID:(NSString*)taskID userID:(NSString*)userID
{
    self = [super init];
    if (self)
    {
        _state = state;
        _taskID = [taskID copy];
        _userID = [userID copy];
    }
    return self;
}
@end
