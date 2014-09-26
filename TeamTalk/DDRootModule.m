//
//  DDRootModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-12.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDRootModule.h"

@implementation DDRootModule
+ (instancetype)shareInstance
{
    
    static DDRootModule* g_rootModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_rootModule = [[[self class] alloc] init];
    });
    return g_rootModule;
}
@end
