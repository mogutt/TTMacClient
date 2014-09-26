//
//  DDFileSendManager.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDFileEntity.h"
#import "DDPullFileDataEntity.h"

typedef void(^DDReceiveCompletion)();

@interface DDFileSendManager : NSObject
@property(nonatomic,copy)DDReceiveCompletion receiveCompletion;

- (BOOL)addFileToSendQueue:(DDFileEntity*)fileEntity;
- (void)continueSendFileForTaskID:(DDPullFileDataEntity*)pullFileEntity;

- (BOOL)addFileToReceiveQueue:(DDFileEntity*)fileEntity;
- (void)beginReceiveFileForTaskID:(DDFileEntity*)fileEntity;
@end
