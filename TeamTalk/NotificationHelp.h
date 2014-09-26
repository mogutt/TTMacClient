//
//  NotificationHelp.h
//  Duoduo
//
//  Created by 独嘉 on 14-4-5.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const notificationTcpLinkConnectComplete;          //tcp连接建立完成
extern NSString* const notificationTcpLinkConnectFailure;           //tcp连接建立失败
extern NSString* const notificationTcpLinkDisconnect;               //tcp断开连接

extern NSString* const notificationRemoveSession;                   //移除会话成功之后的通知

extern NSString* const notificationServerHeartBeat;                 //接收到服务器端的心跳

//extern NSString* const notificationGetAllUsers;                     //获得所有用户

extern NSString* const notificationReceiveMessage;                  //收到一条消息

extern NSString* const notificationReloadTheRecentContacts;         //刷新最近联系人界面
extern NSString* const notificationReceiveP2PShakeMessage;               //收到P2P消息
extern NSString* const notificationReceiveP2PInputingMessage;       //收到正在输入消息
extern NSString* const notificationReceiveP2PStopInputingMessage;   //收到停止输入消息
extern NSString* const notificationReceiveP2PIntranetMessage;       //收到内网发帖消息
@interface NotificationHelp : NSObject

+ (void)postNotification:(NSString*)notification userInfo:(NSDictionary*)userInfo object:(id)object;

@end
