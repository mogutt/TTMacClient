//
//  DDFileTcpClient.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDFileTcpClient.h"
#import "DataOutputStream+Addition.h"
#import "DataInputStream.h"
#import "DDAPISchedule.h"
static const int connectTimeout = 10;

@interface DDFileTcpClient(PrivateAPI)

- (void)p_dispatchData:(NSData*)data;


@end

@implementation DDFileTcpClient
{
    NSMutableData* _buffData;
    NSUInteger _buffMaxSize;
}
+ (instancetype)shareInstance
{
    static DDFileTcpClient* g_fileTcpClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_fileTcpClient = [[DDFileTcpClient alloc] init];
    });
    return g_fileTcpClient;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_socket readDataWithTimeout:-1 tag:1];
        _buffData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)connectIP:(NSString*)ip port:(int)port completion:(DDFileTcpClientConnectCompletion)completion
{
    if (![_socket isConnected])
    {
        NSError* error;
        [_socket connectToHost:ip onPort:port error:&error];
        if (error)
        {
            completion(error);
            return;
        }
        else
        {
            self.completion = completion;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(connectTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.completion)
                {
                    NSError* error = [NSError errorWithDomain:@"连接文件服务器超时" code:0 userInfo:nil];
                    self.completion(error);
                    self.completion = nil;
                }
            });
        }
    }
    else
    {
        completion(nil);
    }
}

- (void)disconnected
{
    if ([_socket isConnected])
    {
        [_socket disconnect];
    }
}

- (BOOL)writeData:(NSData*)data
{
    if ([_socket isConnected])
    {
        [_socket writeData:data withTimeout:-1 tag:10];
        [_socket readDataWithTimeout:-1 tag:10];
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma marj GCDSocket Delegate
//socket 连接成功
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    [sock readDataWithTimeout:-1 tag:0];
    if (self.completion)
    {
        self.completion(nil);
        self.completion = nil;
    }
}

//socket收到数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    DataInputStream *inputData = nil;
    if ([_buffData length] == 0)
    {
        inputData = [DataInputStream dataInputStreamWithData:data];
        
        uint32_t pduLen = [inputData readInt];
        _buffMaxSize = pduLen;
        if (pduLen > [data length])
        {
            [_buffData appendData:data];
            if (_buffMaxSize == [_buffData length])
            {
                //开始分发
                NSData* data = [NSData dataWithData:_buffData];
                [self p_dispatchData:data];
                _buffData = [[NSMutableData alloc] init];
            }
        }
        else
        {
            //开始分发
            [self p_dispatchData:data];
            _buffData = [[NSMutableData alloc] init];
        }
    }
    else
    {
        [_buffData appendData:data];
        if (_buffMaxSize == [_buffData length])
        {
            //开始分发
            NSData* data = [NSData dataWithData:_buffData];
            [self p_dispatchData:data];
            _buffData = [[NSMutableData alloc] init];
        }
    }
    [sock readDataWithTimeout:-1 tag:0];
}

//socket断开
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    DDLog(@"-----------%i,%@",err.code,err.domain);
}

#pragma mark -
#pragma mark privateAPI
- (void)p_dispatchData:(NSData*)data
{
    NSRange range = NSMakeRange(0, IM_PDU_HEADER_LEN);
    //            [[DDAPISchedule instance] receiveServerData:_receiveBuffer];
    
    
    DataInputStream *inputData = [DataInputStream dataInputStreamWithData:data];
    
    uint32_t pduLen = [inputData readInt];
    
    if (pduLen > [data length])
    {
        
    }
    
    TcpProtocolHeader* tcpHeader = [[TcpProtocolHeader alloc] init];
    tcpHeader.version = [inputData readShort];
    tcpHeader.flag = [inputData readShort];
    tcpHeader.serviceId = [inputData readShort];
    tcpHeader.commandId = [inputData readShort];
    tcpHeader.error = [inputData readShort];
    tcpHeader.reserved = [inputData readShort];
    
    NSLog(@"serviceID:%i ------------- cmdID:%i",tcpHeader.serviceId,tcpHeader.commandId);
    range = NSMakeRange(IM_PDU_HEADER_LEN, pduLen - IM_PDU_HEADER_LEN);
    NSData *payloadData = [data subdataWithRange:range];
    
    ServerDataType dataType = DDMakeServerDataType(tcpHeader.serviceId, tcpHeader.commandId, tcpHeader.reserved);
    [[DDAPISchedule instance] receiveServerData:payloadData forDataType:dataType];
}


@end
