//
//  DDFileTcpClient.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
typedef void(^DDFileTcpClientConnectCompletion)(NSError* error);

@interface DDFileTcpClient : NSObject<GCDAsyncSocketDelegate>
{
    GCDAsyncSocket* _socket;
}
@property(nonatomic,copy)DDFileTcpClientConnectCompletion completion;
+ (instancetype)shareInstance;
- (void)connectIP:(NSString*)ip port:(int)port completion:(DDFileTcpClientConnectCompletion)completion;
- (void)disconnected;
- (BOOL)writeData:(NSData*)data;
@end
