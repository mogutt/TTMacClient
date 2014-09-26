//
//  DDFileModule.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDOfflineFileEntity.h"
#import "DDFileEntity.h"
@interface DDFileModule : NSObject
+ (DDFileModule*)shareInstance;

/**
 *  发送文件
 *
 *  @param fileEntity 文件实体
 */
- (void)sendFileEntity:(DDFileEntity*)fileEntity;

/**
 *  接收文件
 *
 *  @param fileEntity 文件实体
 */
- (void)receiveFileEntity:(DDFileEntity*)fileEntity;
@end
