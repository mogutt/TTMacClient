//
//  DDDepartmentModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-19.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDDepartmentModule.h"
#import "DDOrganizationAPI.h"
@implementation DDDepartmentModule
{
    NSMutableDictionary* _organizationInfo;
}
+ (DDDepartmentModule*)shareInstance
{
    static DDDepartmentModule* g_departmentModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_departmentModule = [[DDDepartmentModule alloc] init];
    });
    return g_departmentModule;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _organizationInfo = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)loadAllDepartmentCompletion:(DDLoadDepartmentCompletion)completion
{
    DDOrganizationAPI* organizationAPI = [[DDOrganizationAPI alloc] init];
    [organizationAPI requestWithObject:nil Completion:^(id response, NSError *error) {
        if (!error)
        {
            NSArray* departments = (NSArray*)response;
            if ([departments isKindOfClass:[NSArray class]])
            {
                [departments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    DepartmentEntity* department = (DepartmentEntity*)obj;
                    if (department && department.ID)
                    {
                        [_organizationInfo setObject:department forKey:department.ID];
                    }
                }];
                completion(nil);
            }
            else
            {
                NSError* error = [NSError errorWithDomain:@"返回数据不是一个数组" code:0 userInfo:nil];
                completion(error);
            }
        }
        else
        {
            completion(error);
        }
    }];
}

- (DepartmentEntity*)getDepartmentForID:(NSString*)ID
{
    DepartmentEntity* department = _organizationInfo[ID];
    return department;
}

@end
