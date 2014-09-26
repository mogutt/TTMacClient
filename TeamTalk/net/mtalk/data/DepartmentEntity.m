//
//  DepartmentEntity.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-19.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DepartmentEntity.h"

@implementation DepartmentEntity
- (id)initWithID:(NSString*)ID title:(NSString*)title description:(NSString*)description parentID:(NSString*)parentID leaderID:(NSString*)leaderID status:(NSInteger)status
{
    self = [super init];
    if (self)
    {
        _ID = [ID copy];
        _title = [title copy];
        _description = [description copy];
        _parentID = [parentID copy];
        _leaderID = [leaderID copy];
        _status = status;
    }
    return self;
}
@end
