//
//  DDTcpClientManager.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-12.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDTcpClientManager.h"
#import "NSStream+NSStreamAddition.h"
#import "SendBuffer.h"
#import "TcpProtocolHeader.h"
#import "DataInputStream.h"
#import "DDAPISchedule.h"

static const int connectTimeout = 10;

@interface DDTcpClientManager(PrivateAPI)

- (void)p_dispatchData:(NSData*)data;

@end

@implementation DDTcpClientManager
{
    NSMutableData* _buffData;
    NSUInteger _buffMaxSize;
}
+ (instancetype)shareInstance
{
    static DDTcpClientManager* g_tcpClientManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_tcpClientManager = [[DDTcpClientManager alloc] init];
    });
    return g_tcpClientManager;
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

- (void)connectIP:(NSString*)ip port:(int)port completion:(TcpClientConnectCompletion)completion
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
        [_socket readDataWithTimeout:-1 tag:10];
        [_socket writeData:data withTimeout:-1 tag:10];

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
    [NotificationHelp postNotification:notificationServerHeartBeat userInfo:nil object:nil];
    [_buffData appendData:data];
    DataInputStream* inputData = [DataInputStream dataInputStreamWithData:_buffData];
    uint32_t dataLength = [inputData readInt];
    while (dataLength <= [_buffData length]) {
        NSData* dispatchData = [_buffData subdataWithRange:NSMakeRange(0, dataLength)];
        [self p_dispatchData:dispatchData];
        NSData* leftData = [_buffData subdataWithRange:NSMakeRange(dataLength, [_buffData length] - dataLength)];
        _buffData = nil;
        _buffData = [[NSMutableData alloc] initWithData:leftData];
        if ([_buffData length] > 0)
        {
            inputData = [DataInputStream dataInputStreamWithData:_buffData];
            dataLength = [inputData readInt];
        }
        else
        {
            break;
        }
    }
    [sock readDataWithTimeout:-1 tag:0];
}

//socket断开
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    DDLog(@"-----------%li,%@",err.code,err.domain);
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    DDLog(@"-----------%li",tag);
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
    tcpHeader.serviceId = [inputData readShort];
    tcpHeader.commandId = [inputData readShort];
    tcpHeader.version = [inputData readShort];
    tcpHeader.reserved = [inputData readShort];
    
    if (tcpHeader.serviceId == 2 && tcpHeader.commandId == 15)
    {
        DDLog(@"asdasf");
    }
    
    range = NSMakeRange(IM_PDU_HEADER_LEN, pduLen - IM_PDU_HEADER_LEN);
    NSData *payloadData = [data subdataWithRange:range];
    
    ServerDataType dataType = DDMakeServerDataType(tcpHeader.serviceId, tcpHeader.commandId, tcpHeader.reserved);
    [[DDAPISchedule instance] receiveServerData:payloadData forDataType:dataType];
}
@end
