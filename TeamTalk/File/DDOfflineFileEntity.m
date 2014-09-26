//
//  DDOfflineFileEntity.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-22.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDOfflineFileEntity.h"

@implementation DDOfflineFileEntity
- (id)initWithFromUserID:(NSString*)fromUserID taskID:(NSString*)taskID fileName:(NSString*)fileName fileSize:(int)fileSize ipArray:(NSArray*)ips port:(uint16)port
{
    self = [super init];
    if (self)
    {
        _fromUserID = [fromUserID copy];
        _taskID = [taskID copy];
        _fileName = [fileName copy];
        _fileSize = fileSize;
        _ipArray = [ips mutableCopy];
        _port = port;
    }
    return self;
}
@end
