//
//  DDUserDataModel.h
//  Duoduo
//
//  Created by 独嘉 on 14-2-25.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserEntity.h"
#import "TcpProtocolHeader.h"
#import "DDHttpModule.h"
@class MGJMTalkClient;


@interface DDUserDataModel : NSObject
{
    
}
@property (nonatomic,retain)UserEntity* showUser;

- (void)loadUserInfoSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
@end
