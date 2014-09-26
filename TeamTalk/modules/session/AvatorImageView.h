//
//  AvatorImageView.h
//  Duoduo
//
//  Created by 独嘉 on 14-4-1.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, AvatorType){
    UserAvator,
    GroupAvator
};

@class SessionEntity,UserEntity;
@interface AvatorImageView : EGOImageView
@property (nonatomic,assign)AvatorType type;
@property (nonatomic,retain)SessionEntity* session;

- (void)setSession:(SessionEntity *)session;
- (void)setGroup:(GroupEntity *)group;
- (void)setUser:(UserEntity *)user;
@end
