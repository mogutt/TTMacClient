//
//  DDMsgServer.h
//  Duoduo
//
//  Created by 独嘉 on 14-4-5.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UserEntity;
typedef void(^DDMsgServerCheckCompletion)(UserEntity* user,NSError* error);

@interface DDMsgServer : NSObject
/**
 *  连接消息服务器
 *  在内部使用
 *  @param userID  用户ID
 *  @param token   token
 *  @param success 连接成功执行的block
 *  @param failure 连接失败执行的block
 */
-(void)checkUserID:(NSString*)userID
                            token:(NSString*)token
                          success:(void(^)(id object))success
                          failure:(void(^)(id object))failure;

/**
 *  开源项目登录消息服务器验证
 *
 *  @param userName      用户名
 *  @param password      密码
 *  @param onlineState   在线状态
 *  @param clientType    客户端类型
 *  @param clientVersion 客户端版本
 *  @param completion    验证完成
 */
- (void)checkUSerName:(NSString*)userName
             password:(NSString*)password
          onlineState:(int)onlineState
           clientType:(int)clientType
        clientVersion:(NSString*)clientVersion
           completion:(DDMsgServerCheckCompletion)completion;
@end
