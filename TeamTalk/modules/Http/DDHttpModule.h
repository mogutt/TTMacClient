/************************************************************
 * @file         DDHttpModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       http模块，基于AFNetworking的实现
 ************************************************************/

#import <Foundation/Foundation.h>
#import "DDHttpEntity.h"
#import "DDRootModule.h"
typedef void(^SuccessBlock)(NSDictionary *result);
typedef void(^FailureBlock)(StatusEntity* error);

@class AFHTTPClient;
@interface DDHttpModule : DDRootModule
{
    AFHTTPClient *_httpClient;
}

-(void)httpPostWithUri:(NSString *)uri params:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure;
-(void)httpGetWithUri:(NSString *)uri params:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure;

@end

