//
//  DDLoginManager.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-5.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDLoginManager.h"
#import "DDHttpServer.h"
#import "DDTokenManager.h"
#import "DDMsgServer.h"
#import "DDTcpServer.h"
#import "DDLoginServer.h"
#import "LoginEntity.h"
#import "UserEntity.h"
#import "DDReceiveKickAPI.h"
#import "DDDatabaseUtil.h"
@interface DDLoginManager(privateAPI)

- (void)p_registerAPI;
- (void)reloginAllFlowSuccess:(void(^)())success failure:(void(^)())failure;
- (void)p_loginSuccess:(UserEntity*)user;

@end

@implementation DDLoginManager
{
    NSString* _lastLoginPassword;
    NSString* _lastLoginUserName;
    NSString* _dao;
    
    BOOL _relogining;
}
+ (instancetype)instance
{
    static DDLoginManager *g_LoginManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_LoginManager = [[DDLoginManager alloc] init];
    });
    return g_LoginManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _httpServer = [[DDHttpServer alloc] init];
        _tokenServer = [[DDTokenManager alloc] init];
        _msgServer = [[DDMsgServer alloc] init];
        _tcpServer = [[DDTcpServer alloc] init];
        _loginServer = [[DDLoginServer alloc] init];
        _relogining = NO;
        [self p_registerAPI];
    }
    return self;
}

- (NSString*)token
{
    return [_tokenServer.token copy];
}

#pragma mark Public API
- (void)loginWithUsername:(NSString*)name password:(NSString*)password success:(void(^)(UserEntity* loginedUser))success failure:(void(^)(NSString* error))failure
{
        
    //连接登录服务器
    [_tcpServer loginTcpServerIP:SERVER_IP port:SERVER_PORT Success:^{
        //获取消息服务器ip
        [_loginServer connectLoginServerSuccess:^(LoginEntity *loginEntity) {
            [_tcpServer loginTcpServerIP:loginEntity.ip2 port:loginEntity.port Success:^{
                //连接消息服务器
                [_msgServer checkUSerName:name password:password onlineState:1 clientType:CLIENT_TYPE clientVersion:CLIENT_VERSION completion:^(UserEntity *user,NSError* error) {
                    if (!error)
                    {
                        _lastLoginUserName = [name copy];
                        _lastLoginPassword = [password copy];
                        [self p_loginSuccess:user];
                        success(user);
                    }
                    else
                    {
                        DDLog(@"登录验证失败");
                        log4Error(@"登录验证失败");
                        failure(error.description);
                    }
                }];
            } failure:^{
                DDLog(@"连接消息服务器出错");
                log4Error(@"连接消息服务器出错");
                failure(@"连接消息服务器出错");
            }];
        } failure:^{
            DDLog(@"获取消息服务器IP出错");
            log4Error(@"获取消息服务器IP出错");
            failure(@"获取消息服务器IP出错");
        }];
    } failure:^{
        DDLog(@"连接登录服务器失败");
        log4Error(@"连接登录服务器失败");
        failure(@"连接登录服务器失败");
    }];
}

- (void)reloginSuccess:(void(^)())success failure:(void(^)(NSString* error))failure
{
    if (!_relogining)
    {
        DDLog(@"开始断线重连");
        log4Info(@"开始断线重连");
        _relogining = YES;
        [_tokenServer stopAutoRefreshToken];
        [_tcpServer loginTcpServerIP:SERVER_IP port:SERVER_PORT Success:^{
            //连接登录服务器
            [_loginServer connectLoginServerSuccess:^(LoginEntity *loginEntity) {
                [_tcpServer loginTcpServerIP:loginEntity.ip2 port:loginEntity.port Success:^{
                    //连接消息服务器
                    [_msgServer checkUSerName:_lastLoginUserName password:_lastLoginPassword onlineState:1 clientType:CLIENT_TYPE clientVersion:CLIENT_VERSION completion:^(UserEntity *user,NSError* error) {
                        if (!error)
                        {
                            [self p_loginSuccess:user];
                            log4Info(@"断线重连成功");
                            success(user);
                        }
                        else
                        {
                            [self reloginAllFlowSuccess:^{
                                log4Info(@"断线重连成功");
                                _relogining = NO;
                                success();
                            } failure:^{
                                _relogining = NO;
                                failure(@"登录验证失败");
                            }];
                        }
                    }];
                } failure:^{
                    DDLog(@"连接消息服务器出错");
                    log4Error(@"连接消息服务器出错");
                    _relogining = NO;
                    failure(@"连接消息服务器出错");
                }];
            } failure:^{
                DDLog(@"连接登录服务器出错");
                log4Error(@"连接登录服务器出错");
                _relogining = NO;
                failure(@"连接登录服务器出错");
            }];
        } failure:^{
            DDLog(@"TCP连接失败");
            log4Error(@"TCP连接失败");
            _relogining = NO;
            failure(@"TCP连接失败");
        }];
    }

}

- (void)offlineCompletion:(void(^)())completion
{
    [_tcpServer disconnect];
    completion();
}

#pragma mark - PrivateAPI
- (void)reloginAllFlowSuccess:(void(^)())success failure:(void(^)())failure
{
    [self loginWithUsername:_lastLoginUserName password:_lastLoginPassword success:^(UserEntity *loginedUser) {
        success();
    } failure:^(NSString *error) {
        failure();
    }];
}

- (void)p_registerAPI
{
    DDReceiveKickAPI* api = [[DDReceiveKickAPI alloc] init];
    [api registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {

    }];
}

- (void)p_loginSuccess:(UserEntity*)user
{
    //开始自动刷新Token
    [_tokenServer startAutoRefreshToken];
    //设置用户在线状态
    [DDClientState shareInstance].userID = user.userId;
    //开启当前用户的DB
    [[DDDatabaseUtil instance] openCurrentUserDB];
    //激活启动状态
    [DDClientState shareInstance].userState = DDUserOnline;
}

@end
