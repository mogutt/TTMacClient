//
//  DDAddChatGroupModel.m
//  Duoduo
//
//  Created by 独嘉 on 14-3-2.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDAddChatGroupModel.h"
#import "DDHttpModule.h"
#import "UserEntity.h"
#import "DDAddChatGroup.h"
#import "SpellLibrary.h"
#import "DDUserlistModule.h"
@interface  UserEntity(DDAddChatGroupModel)

- (UserEntity*)initWithUserDictionary:(NSDictionary*)userDictionary;
- (BOOL)adjustToSearchText:(NSString*)searchText;
@end

@interface DDAddChatGroupModel(PrivateAPI)

- (void)addUserToSelectUsersList:(UserEntity*)user;

@end

@implementation DDAddChatGroupModel
{
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _groups = [[NSMutableArray alloc] init];
        _selectUsers = [[NSMutableArray alloc] init];
        _selectGroups = [[NSMutableArray alloc] init];
    }
    return self;
}



- (void)loadAllWorkListSuccess:(void(^)())success Failure:(void(^)(NSError* error))failure
{
    NSArray* allUsers = [[DDUserlistModule shareInstance] getAllOrganizationMembers];
    NSMutableDictionary* allData = [[NSMutableDictionary alloc] init];
    [allUsers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UserEntity* userEntity = (UserEntity*)obj;
        if ([userEntity.userId isEqualToString:[[DDUserlistModule shareInstance] myUserId]] ||
            (userEntity.userRole & 0x20000000) != 0 ||
            !(userEntity.userRole & 0xC0000000) != 0)
        {
            return;
        }
        NSString* department = userEntity.department;
        if (!department)
        {
            DDLog(@"----------------空-------->%@",userEntity.name);
            return;
        }
        if (![[allData allKeys] containsObject:department])
        {
            NSMutableArray* usersInGroup = [[NSMutableArray alloc] init];
            [usersInGroup addObject:userEntity];
            [allData setObject:usersInGroup forKey:department];
        }
        else
        {
            NSMutableArray* usersInGroup = allData[department];
            [usersInGroup addObject:userEntity];
        }
    }];
    
    [allData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        DDAddChatGroup* group = [[DDAddChatGroup alloc] init];
        group.name = key;
        group.users = obj;
        [_groups addObject:group];
    }];
    _showGroups = _groups;

    success();
/*
    DDHttpModule *module = getDDHttpModule();
    NSMutableDictionary* dictParams = [NSMutableDictionary dictionary];
    
    [module httpPostWithUri:@"mtalk/common_internal/workerlist"
                     params:dictParams
                    success:^(NSDictionary *result)
     {
         
         NSDictionary* userList = result[@"userList"];
         [userList enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
             NSString* groupName = (NSString*)key;
             NSDictionary* users = (NSDictionary*)obj;
             NSMutableArray* usersInGroup = [[NSMutableArray alloc] init];
             [users enumerateKeysAndObjectsUsingBlock:^(id userkey, id userobj, BOOL *stop) {
                 NSString* userID = (NSString*)userkey;
                 NSDictionary* userInfo = (NSDictionary*)userobj;
                 UserEntity* user = [[UserEntity alloc] initWithUserDictionary:userInfo];
                 user.userId = userID;
                 [usersInGroup addObject:user];
//                 [[SpellLibrary instance] addSpellForObject:user];
             }];
             
             DDAddChatGroup* group = [[DDAddChatGroup alloc] init];
             group.name = groupName;
             group.users = usersInGroup;
             
             [_groups addObject:group];
         }];
         _showGroups = _groups;
         success();
     }
                    failure:^(StatusEntity *error)
     {
         
         DDLog(@"serverUser fail,error code:%ld,msg:%@ userInfo:%@",error.code,error.msg,error.userInfo);
         failure(error);
     }];
 */
}

- (void)selectItem:(id)item
{
    _lastSelectedOne = item;
    if ([item isKindOfClass:NSClassFromString(@"UserEntity")])
    {
        UserEntity* user = (UserEntity*)item;
        if([self.initialGroupUsersIDs containsObject:user.userId])
        {
            return;
        }
        [self addUserToSelectUsersList:user];
        NSMutableArray* deselectedGroups = [[NSMutableArray alloc] init];
        for (DDAddChatGroup* group in _selectGroups)
        {
            BOOL deselectGroup = YES;
            for (UserEntity* user in group.users)
            {
                if ([_selectUsers containsObject:user])
                {
                    deselectGroup = NO;
                    break;
                }
            }
            if (deselectGroup)
            {
                [deselectedGroups addObject:group];
            }
        }
        [_selectGroups removeObjectsInArray:deselectedGroups];
    }
    else if([item isKindOfClass:NSClassFromString(@"DDAddChatGroup")])
    {
        DDAddChatGroup* group = (DDAddChatGroup*)item;
        if (![_selectGroups containsObject:group])
        {
            [_selectGroups addObject:group];
            for (UserEntity* user in group.users)
            {
                if (![self.selectUsers containsObject:user] && ![self.initialGroupUsersIDs containsObject:user.userId])
                {
                    [self.selectUsers addObject:user];
                }
            }
        }
        else
        {
            [_selectGroups removeObject:group];
            for (UserEntity* user in group.users)
            {
                if ([self.selectUsers containsObject:user])
                {
                    [self.selectUsers removeObject:user];
                }
            }
        }
    }
}

- (BOOL)exitInSelectedUsers:(id)item
{
    if ([item isKindOfClass:NSClassFromString(@"UserEntity")])
    {
        if([self.initialGroupUsersIDs containsObject:[(UserEntity*)item userId]])
        {
            return YES;
        }
    }
    if ([self.selectUsers containsObject:item] || [self.selectGroups containsObject:item])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)couldSelected:(id)item
{
    if ([item isKindOfClass:NSClassFromString(@"UserEntity")])
    {
        if ([self.initialGroupUsersIDs containsObject:[(UserEntity*)item userId]])
        {
            return NO;
        }
    }
    return YES;
}

- (void)searchUser:(NSString* )sender
{
    if ([sender length] == 0)
    {
        _showGroups = _groups;
        return;
    }
    else
    {
        _showGroups = [[NSMutableArray alloc] init];
    }
    for (DDAddChatGroup * group in _groups)
    {
        DDAddChatGroup* newGroup = [[DDAddChatGroup alloc] init];
        newGroup.name = group.name;
        NSMutableArray* users = [[NSMutableArray alloc] init];
        
        [group.users enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UserEntity* user = (UserEntity*)obj;            
            if ([user adjustToSearchText:sender])
            {
                [users addObject:user];
            }
        }];
        newGroup.users = users;
        if ([users count] > 0)
        {
            [_showGroups addObject:newGroup];
        }
    }
}

#pragma mark Private API
- (void)addUserToSelectUsersList:(UserEntity*)user
{
    if ([self.selectUsers containsObject:user]) {
        [self.selectUsers removeObject:user];
    }
    else
    {
        [self.selectUsers addObject:user];
    }
}

@end

@implementation UserEntity(DDAddChatGroupModel)

- (UserEntity*)initWithUserDictionary:(NSDictionary*)userDictionary
{
    self = [super init];
    if (self)
    {
        NSString* avatar = userDictionary[@"avatar"];
        self.avatar = avatar;
        
//        NSString* gender = userDictionary[@"gender"];
        
//        NSNumber* onlineStatus = userDictionary[@"onlineStatus"];
//        self.onlineStatus = [onlineStatus intValue];
        
        NSString* uname = userDictionary[@"uname"];
        self.name = uname;
        
    }
    return self;
}

- (BOOL)adjustToSearchText:(NSString*)searchText
{
    NSString* name = self.name;
    if ([name rangeOfString:searchText].length > 0)
    {
        return YES;
    }
    
    NSMutableArray* spells = [NSMutableArray array];
    for (int index = 0; index < [name length]; index ++)
    {
        NSString* wordAtIndex = [name substringWithRange:NSMakeRange(index, 1)];
        NSString* spellAtIndex = [[SpellLibrary instance] getSpellForWord:wordAtIndex];
        [spells addObject:spellAtIndex];
    }
    
    for (int count = 0; count < [spells count] + 1; count ++)
    {
        NSString* spell = [[SpellLibrary instance] briefSpellWordFromSpellArray:spells fullWord:count];
        if ([spell rangeOfString:searchText].length > 0)
        {
            return YES;
        }
    }
    return NO;
}
@end