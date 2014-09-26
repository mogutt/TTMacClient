//
//  DDRecentContactsCell.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-30.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDRecentContactsCell.h"
#import "SessionEntity.h"
#import "AvatorImageView.h"
#import "DDSetting.h"
#import "DDMessageModule.h"
#import "StateMaintenanceManager.h"
#import "DDServiceAccountModule.h"
#import <Quartz/Quartz.h>

CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

NSNumber* DegreesToNumber(CGFloat degrees) {
    return [NSNumber numberWithFloat: DegreesToRadians(degrees)];
}

@implementation DDRecentContactsCell

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
    }
    return self;
}
-(void)mouseDown:(NSEvent *)theEvent
{
    NSLog(@"---->");
    [super mouseDown:theEvent];
}
- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}
- (void)awakeFromNib
{
//    CALayer* layer = [[CALayer alloc] init];
//    [layer setFrame:avatarImageView.frame];
    [avatarImageView setWantsLayer:YES];
    [avatarImageView.layer setCornerRadius:3.0];
}

-(void)clearUnreadCount{
    [unreadMessageLabel setStringValue:@""];
    [unreadMessageLabel setHidden:YES];
    [unreadMessageBackground setHidden:YES];
}

- (void)configeCellWithObject:(SessionEntity*)object
{
    //头像和在线状态
    if ([object.sessionId hasPrefix:@"group"])
    {
        [avatarImageView setType:GroupAvator];
        [nameTextField setTextColor:[NSColor blackColor]];
    }
    else
    {
        [avatarImageView setType:UserAvator];
        if ([[StateMaintenanceManager instance] getUserStateForUserID:object.sessionId] == USER_STATUS_OFFLINE)
        {
            [nameTextField setTextColor:[NSColor grayColor]];
        }
        else
        {
            [nameTextField setTextColor:[NSColor blackColor]];
        }
    }
    if ([object.name isEqualToString:@"小T"])
    {
        DDLog(@"ad");
    }
    
    [avatarImageView setSession:object];

    if (object.name)
    {
        [nameTextField setStringValue:object.name];
    }
    else
    {
        [nameTextField setStringValue:@""];
    }
    
    //置顶图标
    NSArray* topSessions = [[DDSetting instance] getTopSessionIDs];
    if ([topSessions containsObject:object.sessionId])
    {
        [topIconImageView setHidden:NO];
    }
    else
    {
        [topIconImageView setHidden:YES];
    }
    
    //屏蔽图标
    NSArray* shieldSessions = [[DDSetting instance] getShieldSessionIDs];
    if ([shieldSessions containsObject:object.sessionId])
    {
        [shieldIconImageView setImage:[NSImage imageNamed:@"shield"]];
        [shieldIconImageView setHidden:NO];
    }
    else
    {
        [shieldIconImageView setHidden:YES];
    }
    
    //显示未读消息数
    DDMessageModule* messageModule = [DDMessageModule shareInstance];
    NSInteger unreadCount = [messageModule countMessageBySessionId:object.sessionId];
    NSString* unreadCountString;
    if (unreadCount == 0)
    {
        [unreadMessageLabel setHidden:YES];
        [unreadMessageLabel setStringValue:@""];
        [unreadMessageBackground setHidden:YES];
    }
    else if (unreadCount < 99)
    {
        [unreadMessageBackground setHidden:NO];
        [unreadMessageLabel setHidden:NO];
        unreadCountString = [NSString stringWithFormat:@"%li",(long)unreadCount];
        [unreadMessageLabel setStringValue:unreadCountString];
    }
    else
    {
        [unreadMessageBackground setHidden:NO];
        [unreadMessageLabel setHidden:NO];
        unreadCountString = @"99+";
        [unreadMessageLabel setStringValue:unreadCountString];
    }
    self.tempColor=nameTextField.textColor;
    
    if ([[DDServiceAccountModule shareInstance] isServiceAccount:object.sessionId])
    {
        if (unreadCount > 0)
        {
//            float width = avatarImageView.bounds.size.width;
//            float height = avatarImageView.bounds.size.height;
//            float x = avatarImageView.frame.origin.x;
//            float y = avatarImageView.frame.origin.y;
            
            CAAnimationGroup* group = [[CAAnimationGroup alloc] init];
            group.duration = 1;
            group.repeatCount = 10000;
            CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
//            [animation setDuration:1];
//            [animation setRepeatCount:10000];
            NSMutableArray *values = [NSMutableArray array]; // Turn right
            [values addObject:@(1)]; // Turn left
            [values addObject:@(0.8)]; // Turn right
            [values addObject:@(1)];
            [animation setValues:values];
            group.animations = @[animation];
            [avatarImageView.layer addAnimation:group forKey:@"T"];
        }
        else
        {
            [avatarImageView.layer removeAllAnimations];
        }
    }
}
- (void) setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    NSTableRowView *row = (NSTableRowView*)self.superview;
    //NSColor *tempColor = nameTextField.textColor;
    if (row.isSelected) {
        nameTextField.textColor = [NSColor whiteColor];
    } else {
        nameTextField.textColor = self.tempColor;
    }
    
}
- (void)setTopIconHidden:(BOOL)hidden
{
    [topIconImageView setHidden:hidden];
}
@end
