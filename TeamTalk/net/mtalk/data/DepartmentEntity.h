//
//  DepartmentEntity.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-19.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DepartmentEntity : NSObject
@property (nonatomic,retain)NSString* ID;
@property (nonatomic,retain)NSString* title;
@property (nonatomic,retain)NSString* description;
@property (nonatomic,retain)NSString* parentID;
@property (nonatomic,retain)NSString* leaderID;
@property (nonatomic,assign)NSInteger status;

- (id)initWithID:(NSString*)ID title:(NSString*)title description:(NSString*)description parentID:(NSString*)parentID leaderID:(NSString*)leaderID status:(NSInteger)status;
@end
