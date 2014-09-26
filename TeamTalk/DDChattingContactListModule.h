//
//  DDChattingContactListModule.h
//  Duoduo
//
//  Created by 独嘉 on 14-4-22.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^Completion)();

@class SessionEntity;
@interface DDChattingContactListModule : NSObject
@property (nonatomic,retain)SessionEntity* session;
- (void)searchContent:(NSString*)searchContent completion:(Completion)completion;
- (NSArray*)showGroupMembers;
- (void)sortGroupUserCompletion:(Completion)completion;;
- (void)updateGroupMembersData:(Completion)completion;


@end
