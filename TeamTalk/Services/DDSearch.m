//
//  DDSearch.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-22.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDSearch.h"
#import "DDUserlistModule.h"
#import "DDGroupModule.h"
#import "UserEntity.h"
#import "GroupEntity.h"
#import "SessionEntity.h"
#import "SpellLibrary.h"
@interface DDSearch(PrivateAPI)

- (NSArray*)p_getAllUsersAndGroups;
- (NSString*)p_getIDForObject:(id)sender;

@end

@implementation DDSearch
{
    NSArray* _allUsersAndGroups;
}
+ (instancetype)instance
{
    static DDSearch* g_search;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_search = [[DDSearch alloc] init];
    });
    return g_search;
}

#pragma mark - Public API
- (void)searchContent:(NSString*)content completion:(SearchCompletion)completion
{
    content = [content lowercaseString];
    [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
        NSMutableArray* matchesIDArray = [[NSMutableArray alloc] init];
        if (!_allUsersAndGroups || [_allUsersAndGroups count] == 0)
        {
            _allUsersAndGroups = [self p_getAllUsersAndGroups];
        }
        NSMutableArray*	matches = NULL;
        NSUInteger	i,count;
        NSString*		string;
        
        count         = [_allUsersAndGroups count];
        matches       = [NSMutableArray array];
        
        // find any match in our keyword array against what was typed -
        for (i=0; i< count; i++)
        {
            NSObject* user = [_allUsersAndGroups objectAtIndex:i];
            string = [(UserEntity*)user name];
            NSString* objectID = [self p_getIDForObject:user];

            if ([string rangeOfString:content].length > 0)
            {
                if (![matches containsObject:user])
                {
                    [matches addObject:user];
                    [matchesIDArray addObject:objectID];
                }
            }
        }
        NSString* partialSpell = [[SpellLibrary instance] getSpellForWord:content];
        NSArray* userInSpellLibaray = [[SpellLibrary instance] checkoutForWordsForSpell:partialSpell];
        
        if ([userInSpellLibaray count] > 0)
        {
            [userInSpellLibaray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSString* objectID = [self p_getIDForObject:obj];
                if (!objectID)
                {
                    return;
                }
                if (![matches containsObject:obj] && ![matchesIDArray containsObject:objectID]) {
                    [matches addObject:obj];
                    [matchesIDArray addObject:objectID];
                }
            }];
        }
        
        [matches sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 isKindOfClass:NSClassFromString(@"UserEntity")])
            {
                return NSOrderedAscending;
            }
            else
            {
                return NSOrderedDescending;
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(matches,nil);
        });
    }];
    
//    if (!_allUsersAndGroups || [_allUsersAndGroups count] == 0)
//    {
//        _allUsersAndGroups = [self p_getAllUsersAndGroups];
//    }
//    [self searchContent:content inRange:_allUsersAndGroups completion:completion];
}

- (void)searchContent:(NSString *)content inRange:(NSArray*)ranges completion:(SearchCompletion)completion
{
    [[DDSundriesCenter instance] pushTaskToSerialQueue:^{
        NSUInteger	i,count;
        NSString*		string;
        
        count         = [ranges count];
        NSMutableArray* matches = [[NSMutableArray alloc] init];
        
        // find any match in our keyword array against what was typed -
        for (i=0; i< count; i++)
        {
            UserEntity* user = [ranges objectAtIndex:i];
            string = user.name;
            if ([string rangeOfString:content].length > 0)
            {
                if (![matches containsObject:user])
                {
                    [matches addObject:user];
                }
            }
        }
        NSString* partialSpell = [[SpellLibrary instance] getSpellForWord:content];
        NSArray* userInSpellLibaray = [[SpellLibrary instance] checkoutForWordsForSpell:partialSpell];
        
        NSMutableArray* rangsIDs = [[NSMutableArray alloc] init];
        [ranges enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* ID = [self p_getIDForObject:obj];
            [rangsIDs addObject:ID];
        }];
        
        if ([userInSpellLibaray count] > 0)
        {
            for (NSInteger index = 0; index < [userInSpellLibaray count]; index ++)
            {
                id object = userInSpellLibaray[index];
                NSString* objectID = [self p_getIDForObject:object];
                if (!objectID) {
                    continue;
                }
                if (![matches containsObject:object] && [rangsIDs containsObject:objectID]) {
                    [matches addObject:object];
                }
            }
//            [userInSpellLibaray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//                NSString* objectID = [self p_getIDForObject:obj];
//                if (!objectID)
//                {
//                    return;
//                }
//                if (![matches containsObject:obj] && [ranges containsObject:obj]) {
//                    [matches addObject:[obj copy]];
//                }
//            }];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(matches,nil);
        });
    }];
}

#pragma mark PrivateAPI
- (NSArray*)p_getAllUsersAndGroups
{
    //导入所有的用户
    DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
    NSMutableArray* allSessions = [NSMutableArray arrayWithArray:[userListModule getAllUsers]];
    
    //添加所有组别
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    NSArray* groups = [groupModule getAllGroups];
    [groups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        GroupEntity* group = (GroupEntity*)obj;
        if (![allSessions containsObject:group])
        {
            [allSessions addObject:group];
        }
    }];
    
    
    NSArray* fixedGroups = [groupModule getAllFixedGroups];
    [fixedGroups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        GroupEntity* group = (GroupEntity*)obj;
        if (![allSessions containsObject:group])
        {
            [allSessions addObject:group];
        }
    }];
    return allSessions;
}

- (NSString*)p_getIDForObject:(id)sender
{
    NSString* objectID = nil;
    if ([sender isKindOfClass:NSClassFromString(@"UserEntity")])
    {
        objectID = [(UserEntity*)sender userId];
    }
    else if ([sender isKindOfClass:NSClassFromString(@"GroupEntity")])
    {
        objectID = [(GroupEntity*)sender groupId];
    }
    else if ([sender isKindOfClass:NSClassFromString(@"SessionEntity")])
    {
        objectID = [(SessionEntity*)sender sessionId];
    }
    return objectID;
}
@end
