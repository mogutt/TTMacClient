//
//  DDFileEntity.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDFileEntity.h"

@implementation DDFileEntity
- (id)initWithType:(FileType)fileType taskID:(NSString*)taskID fromUserID:(NSString*)fromUserID toUserID:(NSString*)toUserID filePath:(NSString*)filePath fileName:(NSString*)fileName fileSize:(NSInteger)fileSize ips:(NSArray*)ips port:(int)port
{
    self = [super init];
    if (self)
    {
        _fileType = fileType;
        _taskID = [taskID copy];
        _fromUserID = [fromUserID copy];
        _toUserID = [toUserID copy];
        _filePath = [filePath copy];
        _fileName = [fileName copy];
        if (_filePath && fileSize == 0)
        {
            _fileSize = [[self class] getFileSize:_filePath];
        }
        else
        {
            _fileSize = fileSize;
        }
        _ips = [ips mutableCopy];
        _port = port;
    }
    return self;
}

+ (NSUInteger)getFileSize:(NSString *)path
{
    NSUInteger size = 0;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        size = (uint32_t)[fileHandle offsetInFile];
    }
    [fileHandle closeFile];
    
    return size;
}

@end
