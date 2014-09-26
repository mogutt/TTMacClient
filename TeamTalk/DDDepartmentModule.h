//
//  DDDepartmentModule.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-19.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDRootModule.h"
#import "DepartmentEntity.h"
typedef void(^DDLoadDepartmentCompletion)(NSError* error);

@interface DDDepartmentModule : DDRootModule
+ (DDDepartmentModule*)shareInstance;
- (void)loadAllDepartmentCompletion:(DDLoadDepartmentCompletion)completion;
- (DepartmentEntity*)getDepartmentForID:(NSString*)ID;
@end
