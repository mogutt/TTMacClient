//
//  DDTokenManager.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-5.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDTokenManager.h"
#import "DDHttpModule.h"

static NSInteger const refreshTokenTimeInterval = 60 * 30;

@interface DDTokenManager(privateAPI)

- (void)p_refreshTokenTimer:(NSTimer*)timer;

@end

@implementation DDTokenManager
{
    NSTimer* _timer;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

- (void)refreshTokenWithDao:(NSString*)dao
                    Success:(void(^)(NSString* token))success
                    failure:(void(^)(id error))failure
{
    DDHttpModule* module = [DDHttpModule shareInstance];
    NSMutableDictionary* dictParams = [NSMutableDictionary dictionary];
    [dictParams setObject:@"imclient" forKey:@"mac"];
    [dictParams setObject:dao forKey:@"dao"];
    
    [module httpPostWithUri:@"mtalk/iauth" params:dictParams
                    success:^(NSDictionary *result)
     {
         [self setToken:[result valueForKey:@"token"]];
         DDLog(@"refresh token success");
         log4Info(@"refresh token success");
         success(self.token);
     }
                    failure:^(StatusEntity *error)
     
     {
         failure(error);
         DDLog(@"refresh token failure get cookie fail,error code:%ld,msg:%@ userInfo:%@",error.code,error.msg,error.userInfo);
         log4Info(@"refresh token failure get cookie fail,error code:%ld,msg:%@ userInfo:%@",error.code,error.msg,error.userInfo);
     }];

}

- (void)startAutoRefreshToken
{
    if (!_timer && ![_timer isValid])
    {
         _timer = [NSTimer scheduledTimerWithTimeInterval:refreshTokenTimeInterval target:self selector:@selector(p_refreshTokenTimer:) userInfo:nil repeats:YES];
    }
}

- (void)stopAutoRefreshToken
{
    if (_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark privateAPI
- (void)p_refreshTokenTimer:(NSTimer *)timer
{
    [self refreshTokenWithDao:_dao Success:^(NSString *token) {
        DDLog(@"刷新Token成功");
        log4Info(@"刷新Token成功");
    } failure:^(id error) {
        DDLog(@"刷新Token失败");
        log4Error(@"刷新Token失败");
    }];
}
@end
