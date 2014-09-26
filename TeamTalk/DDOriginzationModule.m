//
//  DDOriginzationModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-18.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDOriginzationModule.h"
#import "DDUserlistModule.h"
@interface DDOriginzationModule(PrivateAPI)

- (void)p_loadOrganizationMembers;

@end

@implementation DDOriginzationModule
{
}
- (id)init
{
    self = [super init];
    if (self)
    {
        [self p_loadOrganizationMembers];
    }
    return self;
}

- (id)childItemAtIndex:(NSInteger)index forItem:(id)item
{
    if (!item)
    {
        return [self.originzation allKeys][index];
    }
    else if ([item isKindOfClass:[NSString class]])
    {
        NSArray* users = self.originzation[item];
        if ([users count] > index)
        {
            return users[index];
        }
        return nil;
    }
    else
    {
        return nil;
    }
}

#pragma mark privateAPI
- (void)p_loadOrganizationMembers
{
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    NSArray* allUsers = [userModule getAllUsers];
    NSMutableDictionary* origanization = [[NSMutableDictionary alloc] init];
    [allUsers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UserEntity* user = (UserEntity*)obj;
        NSString* department = user.department;
        if (department)
        {
            if ([[origanization allKeys] containsObject:department])
            {
                NSMutableArray* objects = origanization[department];
                [objects addObject:user];
            }
            else
            {
                NSMutableArray* objects = [[NSMutableArray alloc] init];
                [objects addObject:user];
                [origanization setObject:objects forKey:department];
            }
        }
        DDLog(@"%@",department);
    }];
    _originzation = [NSDictionary dictionaryWithDictionary:origanization];
    
}
@end
