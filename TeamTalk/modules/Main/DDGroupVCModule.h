//
//  DDGroupVCModule.h
//  Duoduo
//
//  Created by 独嘉 on 14-4-29.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^LoadGroupCompletion)(NSArray* groups);
@interface DDGroupVCModule : NSObject
@property (nonatomic,retain)NSArray* groups;

- (void)loadGroupCompletion:(LoadGroupCompletion)completion;
- (NSInteger)indexAtGroups:(NSString*)groupID;
@end
