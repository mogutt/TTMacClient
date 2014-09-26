//
//  AvatorImageView.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-1.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "AvatorImageView.h"
#import "SessionEntity.h"
#import "UserEntity.h"
#import "GroupEntity.h"
#import "DDUserlistModule.h"
#import "DDGroupModule.h"

static CGFloat const cornerRadius = 5.0;

@interface AvatorImageView(privateAPI)

- (void)loadUserAvator:(SessionEntity*)session;
- (void)loadGroupAvator:(SessionEntity*)session;

@end

@implementation AvatorImageView

- (void)setSession:(SessionEntity *)session
{
    switch (_type)
    {
        case UserAvator:
            [self loadUserAvator:session];
            break;
        case GroupAvator:
            [self loadGroupAvator:session];
            break;
        default:
            break;
    }
}

- (void)setGroup:(GroupEntity *)group
{
    NSMutableArray* subviews= [[NSMutableArray alloc] initWithArray:[self subviews]];
    for (EGOImageView* view in subviews)
    {
        [view removeFromSuperview];
    }
    [self setImage:nil];
    
    int count = 0;
    for (int index = 0; index < [group.fixGroupUserIds count]; index ++)
    {
        NSString* userID = group.fixGroupUserIds[index];
        UserEntity* user = [[DDUserlistModule shareInstance] getUserById:userID];
        if (user.avatar && [user.avatar length] > 0)
        {
            CGFloat x = (count % 2) * (self.frame.size.width / 2.0);
            CGFloat y = count > 1 ? (self.frame.size.height / 2.0) : 0;
            CGFloat width = self.frame.size.width / 2.0;
            CGFloat height = self.frame.size.height / 2.0;
            NSRect frame = NSMakeRect(x, y, width, height);
            EGOImageView* imageView = [[EGOImageView alloc] initWithFrame:frame];
            NSURL* avatorURL = [NSURL URLWithString:user.avatar];
            [imageView loadImageWithURL:avatorURL setplaceholderImage:@"recent_default_avatar"];
            [self addSubview:imageView];
            count ++;
            
        }
        if (count >= 4)
        {
            break;
        }
    }
}

- (void)setUser:(UserEntity *)user
{
    NSMutableArray* subviews= [[NSMutableArray alloc] initWithArray:[self subviews]];
    if ([subviews count] > 1)
    {
        for (EGOImageView* view in subviews)
        {
            [view removeFromSuperview];
        }
    }
    [self setImage:nil];
    
    NSString* avator = user.avatar;
    
    NSURL* url = [NSURL URLWithString:avator];
    [self loadImageWithURL:url setplaceholderImage:@"recent_default_avatar"];
}

- (void)loadUserAvator:(SessionEntity*)session
{
    NSMutableArray* subviews= [[NSMutableArray alloc] initWithArray:[self subviews]];
    if ([subviews count] > 1)
    {
        for (EGOImageView* view in subviews)
        {
            [view removeFromSuperview];
        }
    }
    [self setImage:nil];
    NSString* userID = session.sessionId;
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    
    UserEntity* user = [userModule getUserById:userID];
    NSString* avator = user.avatar;
    
    NSURL* url = [NSURL URLWithString:avator];
    //fixme:这尼玛，怎么搞，先这么弄着，不应该在上面加一层imageview的
//    EGOImageView* imageView = [[EGOImageView alloc] initWithFrame:self.bounds];
//    [imageView loadImageWithURL:url setplaceholderImage:@"man_placeholder"];
//    [self addSubview:imageView];
    [self loadImageWithURL:url setplaceholderImage:@"recent_default_avatar"];
    
}

- (void)loadGroupAvator:(SessionEntity*)session
{
    NSMutableArray* subviews= [[NSMutableArray alloc] initWithArray:[self subviews]];
    for (EGOImageView* view in subviews)
    {
        [view removeFromSuperview];
    }
    [self setImage:nil];
    NSString* groupID = session.sessionId;
    DDGroupModule* groupModule = [DDGroupModule shareInstance];
    
    GroupEntity* group = [groupModule getGroupByGId:groupID];
    
    int count = 0;
    for (NSInteger index = 0; index < [group.fixGroupUserIds count]; index ++)
    {
        NSString* userID = group.fixGroupUserIds[index];
        UserEntity* user = [[DDUserlistModule shareInstance] getUserById:userID];
        if (user.avatar && [user.avatar length] > 0)
        {
            CGFloat x = (count % 2) * (self.frame.size.width / 2.0);
            CGFloat y = count > 1 ? (self.frame.size.height / 2.0) : 0;
            CGFloat width = self.frame.size.width / 2.0;
            CGFloat height = self.frame.size.height / 2.0;
            NSRect frame = NSMakeRect(x, y, width, height);
            EGOImageView* imageView = [[EGOImageView alloc] initWithFrame:frame];
            NSURL* avatorURL = [NSURL URLWithString:user.avatar];
            [imageView loadImageWithURL:avatorURL setplaceholderImage:@"recent_default_avatar"];
            [self addSubview:imageView positioned:NSWindowBelow relativeTo:nil];
//            [self addSubview:imageView];
            count ++;

        }
        if (count >= 4)
        {
            break;
        }
    }
  
    
}

@end
