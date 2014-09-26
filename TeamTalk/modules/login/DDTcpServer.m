//
//  DDTcpServer.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-5.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDTcpServer.h"
#import "DDTcpClientManager.h"

typedef void(^Success)();
typedef void(^Failure)();

static NSInteger timeoutInterval = 10;

@interface DDTcpServer(notification)

- (void)n_receiveTcpLinkConnectCompleteNotification:(NSNotification*)notification;
- (void)n_receiveTcpLinkConnectFailureNotification:(NSNotification*)notification;


@end

@implementation DDTcpServer
{
    Success _success;
    Failure _failure;
    BOOL _connecting;
    NSUInteger _connectTimes;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _connecting = NO;
        _connectTimes = 0;
    }
    return self;
}

- (void)loginTcpServerIP:(NSString*)ip port:(NSInteger)point Success:(void(^)())success failure:(void(^)())failure
{
    if (!_connecting)
    {
        _connectTimes ++;
        _connecting = YES;
        _success = [success copy];
        _failure = [failure copy];
        [[DDTcpClientManager shareInstance] disconnected];
        [[DDTcpClientManager shareInstance] connectIP:ip port:(int)point completion:^(NSError *error) {
            if (!error)
            {
                _connecting = NO;
                success();
            }
            else
            {
                _connecting = NO;
                failure();
            }
            
        }];
    }
}

- (void)dealloc
{
}
@end
