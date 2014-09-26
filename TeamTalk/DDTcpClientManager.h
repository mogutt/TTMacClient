//
//  DDTcpClientManager.h
//  Duoduo
//
//  Created by 独嘉 on 14-4-12.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

typedef void(^TcpClientConnectCompletion)(NSError* error);

@interface DDTcpClientManager : NSObject<NSStreamDelegate>
{
    GCDAsyncSocket* _socket;
}
@property(nonatomic,copy)TcpClientConnectCompletion completion;
+ (instancetype)shareInstance;
- (void)connectIP:(NSString*)ip port:(int)port completion:(TcpClientConnectCompletion)completion;
- (void)disconnected;
- (BOOL)writeData:(NSData*)data;


@end
