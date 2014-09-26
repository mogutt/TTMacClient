//
//  DDFileModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDFileModule.h"
#import "DDFileSendAPI.h"
#import "DDReceivePullDataAPI.h"
#import "DDFileSendManager.h"
#import "DDFileTcpClient.h"
#import "DDFileServerLoginAPI.h"
#import "DDReceiveFileStateNotifyAPI.h"
#import "DDAddOfflineFileAPI.h"
#define TYPE_KEY                        @"typeKey"

#define FILE_PATH_KEY                   @"filePath"
#define TO_USER_ID_KEY                  @"toUserID"

#define RECEIVE_OBJECT_KEY              @"ReceiveFileObject"

@interface DDFileModule(privateAPI)

- (void)p_registerAPI;
- (void)p_workingForNextFile;
- (void)p_sendFileEntity:(DDFileEntity*)fileEntity;
- (void)p_receiveFileEntity:(DDFileEntity*)fileEntity;

@end

@implementation DDFileModule
{
    DDFileSendManager* _fileSendManager;
    NSMutableArray* _waitQueue;
    BOOL _working;
}
+ (DDFileModule*)shareInstance
{
    static DDFileModule* g_fileModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_fileModule = [[DDFileModule alloc] init];
    });
    return g_fileModule;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self p_registerAPI];
        _waitQueue = [[NSMutableArray alloc] init];
        _fileSendManager = [[DDFileSendManager alloc] init];
        __weak NSMutableArray* weakWaitQueue = _waitQueue;
        __weak DDFileModule* weakFileModule = self;
        _fileSendManager.receiveCompletion = ^{
            DDLog(@"**********恭喜发财，接收成功成功**************");
            
            [weakWaitQueue removeObjectAtIndex:0];
            [weakFileModule setValue:@(NO) forKeyPath:@"_working"];
        };
        [self addObserver:self forKeyPath:@"_working" options:0 context:nil];
    }
    return self;
}

- (void)sendFileEntity:(DDFileEntity*)fileEntity
{
    
    [_waitQueue addObject:fileEntity];
    if (!_working)
    {
        [self p_workingForNextFile];
    }
    
}

- (void)receiveFileEntity:(DDFileEntity*)fileEntity
{
    [_waitQueue addObject:fileEntity];
    if (!_working)
    {
        [self p_workingForNextFile];
    }
}

#pragma mark -
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"_working"])
    {
        if (!_working)
        {
            [self p_workingForNextFile];
        }
    }
}

#pragma mark privateAPI

- (void)p_registerAPI
{
    DDReceivePullDataAPI* pullDataAPI = [[DDReceivePullDataAPI alloc] init];
    [pullDataAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        DDPullFileDataEntity* pullFileDataEntity = (DDPullFileDataEntity*)object;
        //发送数据包
        [_fileSendManager continueSendFileForTaskID:pullFileDataEntity];
    }];
    
    DDReceiveFileStateNotifyAPI* receiveFileStateNotifyAPI = [[DDReceiveFileStateNotifyAPI alloc] init];
    [receiveFileStateNotifyAPI registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        if (!error)
        {
            DDFileServerNotifyEntity* notifyEntity = (DDFileServerNotifyEntity*)object;
            ClientFileState state = notifyEntity.state;
            switch (state) {
                case CLIENT_FILE_PEER_READY:
                    
                    break;
                case CLIENT_FILE_CANCEL:
                    [self setValue:@(NO) forKeyPath:@"_working"];
                    break;
                case CLIENT_FILE_REFUSE:
                    [self setValue:@(NO) forKeyPath:@"_working"];
                    break;
                case CLIENT_FILE_DONE:
                {
                    DDLog(@"**********恭喜发财，发送成功**************");
                    DDAddOfflineFileAPI* addOfflineFileAPI = [[DDAddOfflineFileAPI alloc] init];
                    [addOfflineFileAPI requestWithObject:_waitQueue[0] Completion:^(id response, NSError *error) {
                        
                    }];
                    [_waitQueue removeObjectAtIndex:0];
                    [self setValue:@(NO) forKeyPath:@"_working"];
                    break;
                }
                default:
                    break;
            }
        }
        else
        {
            
        }
    }];
}

- (void)p_workingForNextFile
{
    if ([_waitQueue count] > 0)
    {
        _working = YES;
        DDFileEntity* toWorkingObejct = _waitQueue[0];
    
        if (toWorkingObejct.fileType == SendFileType)
        {
            [self p_sendFileEntity:toWorkingObejct];
        }
        else if (toWorkingObejct.fileType == ReceiveFileType)
        {
            [self p_receiveFileEntity:toWorkingObejct];
        }
    }
}

- (void)p_sendFileEntity:(DDFileEntity*)toWorkingObejct
{
    NSString* filePath = toWorkingObejct.filePath;
    NSString* userID = toWorkingObejct.toUserID;
    NSString* fromUserID = [DDClientState shareInstance].userID;
    NSString* fileName = [filePath lastPathComponent];
    NSUInteger fileSize = toWorkingObejct.fileSize;
    DDFileSendAPI* fileSendAPI = [[DDFileSendAPI alloc] init];
    NSArray* object = @[fromUserID,userID,fileName,@(fileSize)];
    [fileSendAPI requestWithObject:object Completion:^(id response, NSError *error) {
        if (!error)
        {
            NSDictionary* info = (NSDictionary*)response;
            NSString* taskID = info[@"taskID"];
            toWorkingObejct.taskID = taskID;
            
            NSString* ip = info[@"ip"];
            int port = [info[@"port"] intValue];
            [[DDFileTcpClient shareInstance] connectIP:ip port:port completion:^(NSError *error) {
                if (!error)
                {
                    DDFileServerLoginAPI* loginAPI = [[DDFileServerLoginAPI alloc] init];
                    NSArray* object = @[fromUserID,toWorkingObejct.taskID];
                    [loginAPI requestWithObjectToFileSocket:object Completion:^(id response, NSError *error) {
                        [_fileSendManager addFileToSendQueue:toWorkingObejct];
                    }];
                }
                else
                {
                    [self setValue:@(NO) forKeyPath:@"_working"];
                }
            }];
        }else
        {
            [self setValue:@(NO) forKeyPath:@"_working"];
        }
    }];
}

- (void)p_receiveFileEntity:(DDFileEntity*)fileEntity
{
    NSArray* ips = fileEntity.ips;
    int port = fileEntity.port;
    NSString* userID = [DDClientState shareInstance].userID;
    if ([ips count] > 0)
    {
        [[DDFileTcpClient shareInstance] connectIP:ips[0] port:29800 completion:^(NSError *error) {
            if (!error)
            {
                DDFileServerLoginAPI* loginAPI = [[DDFileServerLoginAPI alloc] init];
                NSArray* object = @[userID,fileEntity.taskID];
                [loginAPI requestWithObjectToFileSocket:object Completion:^(id response, NSError *error) {
                    [_fileSendManager addFileToReceiveQueue:fileEntity];
                    [_fileSendManager beginReceiveFileForTaskID:fileEntity];
                }];
            }
            else
            {
                [self setValue:@(NO) forKeyPath:@"_working"];
            }
        }];
    }
}


@end
