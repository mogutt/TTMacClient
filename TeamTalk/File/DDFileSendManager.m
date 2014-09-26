//
//  DDFileSendManager.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDFileSendManager.h"
#import "DataOutputStream.h"
#import "DDModuleID.h"
#import "TcpProtocolHeader.h"
#import "DataOutputStream+Addition.h"
#import "DDFileTcpClient.h"
#import "DDFileDataAPI.h"
#import "DDPullFileDataAPI.h"
#import "DDPathHelp.h"
#define FILE_ENTITY_KEY                 @"fileEntity"
#define FILE_OFFSET_KEY                 @"offset"
#define FILE_MAX_LENGTH                 (1024 * 4)


@interface DDFileSendManager(privateAPI)

- (BOOL)p_addMaintainFile:(DDFileEntity*)fileEntity;
- (NSData*)p_fileDataToSendForFile:(DDPullFileDataEntity*)filePullEntity;
- (void)p_sendNextFile;
@end

@implementation DDFileSendManager
{
    NSMutableDictionary* _fileSendDic;
    NSMutableDictionary* _fileHandleDic;
    NSMutableArray* _taskIDs;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _fileSendDic = [[NSMutableDictionary alloc] init];
        _fileHandleDic = [[NSMutableDictionary alloc] init];
        _taskIDs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)addFileToSendQueue:(DDFileEntity*)fileEntity
{
    if ([self p_addMaintainFile:fileEntity])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)continueSendFileForTaskID:(DDPullFileDataEntity*)pullFileEntity
{
    NSString* taskID = pullFileEntity.taskID;
    int offSet = pullFileEntity.offset;
    NSDictionary* info = _fileSendDic[taskID];
    
    DDFileEntity* fileEntity = info[FILE_ENTITY_KEY];
    int result = 0;
    NSString* fromUserID = fileEntity.fromUserID;
    NSData* data = [self p_fileDataToSendForFile:pullFileEntity];

    NSArray* object = @[@(result),taskID,fromUserID,@(offSet),data];
    DDLog(@"=====================send data offset:%i",offSet);
    DDFileDataAPI* fileDataAPI = [[DDFileDataAPI alloc] init];
    [fileDataAPI requestWithObjectToFileSocket:object Completion:^(id response, NSError *error) {
        
    }];
}

- (BOOL)addFileToReceiveQueue:(DDFileEntity*)fileEntity
{
    return [self p_addMaintainFile:fileEntity];
}

- (void)beginReceiveFileForTaskID:(DDFileEntity*)fileEntity
{
    DDPullFileDataAPI* pullDataAPI = [[DDPullFileDataAPI alloc] init];
    /*
    NSString* taskID = array[0];
    NSString* userID = array[1];
    int mode = [array[2] intValue];
    int offset = [array[3] intValue];
    int dataSize = [array[4] intValue];
     */
    NSString* taskID = fileEntity.taskID;
    NSString* userID = [DDClientState shareInstance].userID;
    int mode = 2;
    NSDictionary* info = _fileSendDic[taskID];
    int offset = [info[FILE_OFFSET_KEY] intValue];
    int dataSize = FILE_MAX_LENGTH;
    NSArray* object = @[taskID,userID,@(mode),@(offset),@(dataSize)];
    [pullDataAPI requestWithObjectToFileSocket:object Completion:^(id response, NSError *error) {
        if (!error)
        {
            if ([response count] > 0)
            {
                /*
                 dictionary = @{@"taskID":taskID,
                 @"userID":userID,
                 @"offset":@(offset),
                 @"dataSize":@(dataSize),
                 @"data":data};
                 */
                NSDictionary* result = (NSDictionary*)response;
                NSString* taskID = result[@"taskID"];
                NSString* userID = result[@"userID"];
                int offset = [result[@"offset"] intValue];
                int dataSize = [result[@"dataSize"] intValue];
                NSData* data = result[@"data"];
                
                NSFileHandle* fileHandle = _fileHandleDic[taskID];
                [fileHandle seekToFileOffset:offset];
                [fileHandle writeData:data];
                NSDictionary* newInfo = @{FILE_ENTITY_KEY:info[FILE_ENTITY_KEY],
                                          FILE_OFFSET_KEY:@(offset + dataSize)};
                [_fileSendDic setObject:newInfo forKey:taskID];
                if (offset + dataSize < fileEntity.fileSize)
                {
                    [self beginReceiveFileForTaskID:fileEntity];
                }
                else
                {
                    if (self.receiveCompletion)
                    {
                        self.receiveCompletion(nil);
                    }
                }
            }
            else
            {
                [self beginReceiveFileForTaskID:fileEntity];
            }
        }
    }];
}

#pragma mark -
#pragma mark privateAPI
- (BOOL)p_addMaintainFile:(DDFileEntity*)fileEntity
{
    //fileSendDic
    NSString* taskID = fileEntity.taskID;
    NSDictionary* info = @{FILE_ENTITY_KEY:fileEntity,
                           FILE_OFFSET_KEY:@(0)};
    
    //file
    NSFileHandle* fileHandle = nil;
    if (!fileEntity.filePath)
    {
        fileEntity.filePath = [[DDPathHelp downLoadPath] stringByAppendingPathComponent:fileEntity.fileName];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileEntity.filePath];
    }
    else
    {
        fileHandle = [NSFileHandle fileHandleForReadingAtPath:fileEntity.filePath];
    }
    if (fileHandle)
    {
        [_fileSendDic setObject:info forKey:taskID];
        [fileHandle seekToFileOffset:0];
        [_fileHandleDic setObject:fileHandle forKey:taskID];
        [_taskIDs addObject:taskID];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (NSData*)p_fileDataToSendForFile:(DDPullFileDataEntity*)filePullEntity
{
    NSFileHandle* fileHandle = _fileHandleDic[filePullEntity.taskID];
    int dataSize = filePullEntity.dataSize;
    int offset = filePullEntity.offset;
    [fileHandle seekToFileOffset:offset];
    NSData* data = [fileHandle readDataOfLength:dataSize];
    return data;
}

- (void)p_sendNextFile
{
    
}

@end
