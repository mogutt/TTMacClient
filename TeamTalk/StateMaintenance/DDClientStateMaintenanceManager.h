//
//  DDClientStateMaintenanceManager.h
//  Duoduo
//
//  Created by 独嘉 on 14-4-12.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDRootModule.h"
/**
 *  自身状态的维护
 */
@interface DDClientStateMaintenanceManager : DDRootModule


/**
 *  开始发送心跳包,需要在主线程上运行此函数，以添加到主线程的runloop
 */
- (void)startHeartBeat;

/**
 *  停止发送心跳包
 */
- (void)stopHeartBeat;

@end
