//
//  DDLoginAPI.m
//  Duoduo
//
//  Created by 独嘉 on 14-5-6.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDLoginAPI.h"
#import "UserEntity.h"
#import "LoginEntity.h"
#import "MD5.h"
@implementation DDLoginAPI
/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutTimeInterval
{
    return 8;
}

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID
{
    return MODULE_ID_LOGIN;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return MODULE_ID_LOGIN;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CMD_LOGIN_REQ_USERLOGIN;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CMD_LOGIN_RES_USERLOGIN;
}

/**
 *  解析数据的block
 *
 *  @return 解析数据的block
 */
- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSData* data)
    {
        DataInputStream* bodyData = [DataInputStream dataInputStreamWithData:data];
        NSInteger serverTime = [bodyData readInt];
        NSInteger loginResult = [bodyData readInt];
        DDLog(@"  >>登录消息服务器返回,服务器时间:%ld 结果:%ld",serverTime,loginResult);
        LoginEntity* logEntity = [[LoginEntity alloc] init];
        logEntity.serverTime = (uint32)serverTime;
        logEntity.result = (uint32)loginResult;
        /*
         enum {
         REFUSE_REASON_NONE				= 0,
         REFUSE_REASON_NO_MSG_SERVER		= 1,
         REFUSE_REASON_MSG_SERVER_FULL 	= 2,
         REFUSE_REASON_NO_DB_SERVER		= 3,
         REFUSE_REASON_NO_LOGIN_SERVER	= 4,
         REFUSE_REASON_NO_ROUTE_SERVER	= 5,
         REFUSE_REASON_DB_VALIDATE_FAILED = 6,
         RESUSE_REASON_VERSION_TOO_OLD	= 7,
         }
         */
        if (loginResult==0)
        {
            uint32 state = [bodyData readInt];      //在线状态
            NSString* userID = [bodyData readUTF];  //ID
            NSString *nickName = [bodyData readUTF];//昵称
            NSString *avatar = [bodyData readUTF];  //头像
            NSString* title = [bodyData readUTF];   //职位
            NSString* position = [bodyData readUTF];//位置
            uint32 roleState = [bodyData readInt];  //在职状态
            uint32 sex = [bodyData readInt];
            NSString* departmentID = [bodyData readUTF];//部门ID
            uint32 jobNumber = [bodyData readInt];  //工号
            NSString* telPhone = [bodyData readUTF];//电话
            NSString* email = [bodyData readUTF];   //邮箱
            NSString* token = [bodyData readUTF];   //Token(暂时没用)
            UserEntity *user = [[UserEntity alloc] initWithUserID:userID name:nickName nickName:nickName avatar:avatar title:title position:position roleState:roleState sex:sex department:departmentID jobNum:jobNumber telphone:telPhone email:email];
            logEntity.myUserInfo = user;
            log4CInfo(@"login msg server success userID:%@ userName:%@",user.userId,user.name);
        }
        return logEntity;
    };
    return analysis;
}

/**
 *  打包数据的block
 *
 *  @return 打包数据的block
 */
- (Package)packageRequestObject
{
    Package package = (id)^(id object,uint32_t seqNo)
    {
        DataOutputStream *dataout = [[DataOutputStream alloc] init];
        
        NSArray* array = (NSArray*)object;
        
        NSString* userName = array[0];
        NSString* password = [array[1] md5];
        int onlineState = [array[2] intValue];
        int clientType = [array[3] intValue];
        NSString* clientVersion = [NSString stringWithFormat:@"%f",[array[4] floatValue]];
        
        uint32_t totalLen = IM_PDU_HEADER_LEN + strLen(userName) + strLen(password) + strLen(clientVersion) + 5 * 4;
        
        [dataout writeInt:totalLen];
        [dataout writeTcpProtocolHeader:MODULE_ID_LOGIN
                                    cId:CMD_LOGIN_REQ_USERLOGIN
                                  seqNo:seqNo];
        [dataout writeUTF:userName];
        [dataout writeUTF:password];
        [dataout writeInt:onlineState];
        [dataout writeInt:clientType];
        [dataout writeUTF:clientVersion];
        log4CInfo(@"user login -->username:%@ status:%i clientVersion:%@",userName,onlineState,clientVersion);
        return [dataout toByteArray];
    };
    return package;
}
@end
