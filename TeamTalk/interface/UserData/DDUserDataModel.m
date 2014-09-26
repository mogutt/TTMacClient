//
//  DDUserDataModel.m
//  Duoduo
//
//  Created by 独嘉 on 14-2-25.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDUserDataModel.h"
#import "DDHttpModule.h"
#import "DDUserDetailInfoAPI.h"
@implementation DDUserDataModel

- (void)loadUserInfoSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    DDUserDetailInfoAPI* detailInfoAPI = [[DDUserDetailInfoAPI alloc] init];
    [detailInfoAPI requestWithObject:@[_showUser.userId] Completion:^(id response, NSError *error) {
        if ([response count] > 0)
        {
            NSDictionary* userInfo = response[0];
            success(userInfo);
        }
        else
        {
            failure(nil);
        }
    }];
//    DDHttpModule *module = getDDHttpModule();
//    NSMutableDictionary* dictParams = [NSMutableDictionary dictionary];
//    [dictParams setObject:_showUser.userId forKey:@"userid"];
//    [module httpPostWithUri:@"/mtalk/common_internal/workerinfo?" params:dictParams success:^(NSDictionary *result) {
//        NSDictionary* userInfo = result[@"userInfo"];
//        success(userInfo);
//        
//    } failure:^(StatusEntity *error) {
//        DDLog(@"serverUser fail,error code:%ld,msg:%@ userInfo:%@",error.code,error.msg,error.userInfo);
//        failure(error);
//    }];
}


@end
