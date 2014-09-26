//
//  DDGroupVCModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-29.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDGroupVCModule.h"
#import "DDGroupModule.h"
#import "DDFixedGroupAPI.h"
#import "GroupEntity.h"
#import "DDDeleteMemberFromGroupAPI.h"
#import "SpellLibrary.h"
@implementation DDGroupVCModule
{
    
}

- (id)init
{
    self = [super init];
    if (self)
    {
        DDGroupModule* groupModule = [DDGroupModule shareInstance];
        self.groups = [groupModule getAllFixedGroups];
    }
    return self;
}

- (void)loadGroupCompletion:(LoadGroupCompletion)completion
{
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    DDFixedGroupAPI* api = [[DDFixedGroupAPI alloc] init];
    [api requestWithObject:nil Completion:^(id response, NSError *error) {
        if (!error)
        {
            for (GroupEntity* group in response)
            {
                [groupModule addFixedGroup:group];
                [groupModule addGroup:group];
                [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
                    [[SpellLibrary instance] addSpellForObject:group];
                }];

//                if ([group.name isEqualToString:@"创业大群"])
//                {
//                    NSArray* groupUsers = group.groupUserIds;
//                    NSString* groupID = @"14fj6";
//                    DDDeleteMemberFromGroupAPI* deleteMemberFromAPI = [[DDDeleteMemberFromGroupAPI alloc] init];
//                    [deleteMemberFromAPI requestWithObject:@[groupID,groupUsers] Completion:^(id response, NSError *error) {
//                        if (!error)
//                        {
//                            DDLog(@"success");
//                        }
//                        else
//                        {
//                            DDLog(@"error:%@",[error domain]);
//                        }
//                    }];
//                }
            }
            self.groups = response;
            completion(response);
        }
        else
        {
            [self loadGroupCompletion:completion];
            DDLog(@"error:%@",[error domain]);
        }
    }];
}

- (NSInteger)indexAtGroups:(NSString*)groupID
{
    __block NSInteger index = -1;
    [self.groups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        GroupEntity* group = (GroupEntity*)obj;
        if ([group.groupId isEqualToString:groupID])
        {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

@end
