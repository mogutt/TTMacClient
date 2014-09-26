//
//  DDServiceAccountModule.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-10.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDServiceAccountModule.h"
#import "DDMessageSendManager.h"
#import "DDSessionModule.h"
#import "DDUserInfoManager.h"
#import "DDUserlistModule.h"
#import "MessageEntity.h"
#import "DDMessageModule.h"
#define DD_LAST_LOGIN_DATE_KEY                                 @"LastLoginDate"
#define DD_TT_ACTION_KEY                @"TT_Action"
#define DD_TT_ACTION_CONTENT            @"TT_Content"
@interface DDServiceAccountModule(privateAPI)

- (void)p_registerAPI;
- (void)n_receiveUserLoginSuccessNotification:(NSNotification*)notification;

- (void)p_performActionBangWithContent:(NSString*)content;

@end

@implementation DDServiceAccountModule
{
    NSArray* _serviceAccountArray;
}
+ (instancetype)shareInstance
{
    static DDServiceAccountModule* g_serviceAccountModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_serviceAccountModule = [[DDServiceAccountModule alloc] init];
    });
    return g_serviceAccountModule;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _serviceAccountArray = @[@"11m2ec4"];
        
    }
    return self;
}

- (BOOL)isServiceAccount:(NSString*)userID
{
    return [_serviceAccountArray containsObject:userID];
}

- (void)sendAlmanac
{

    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    SessionEntity* sessionEntity = [sessionModule getSessionBySId:@"11m2ec4"];
    NSAttributedString* content = [[NSAttributedString alloc] initWithString:@"#老黄历#"];
    [[DDMessageSendManager instance] sendMessage:content forSession:sessionEntity success:^(NSString *sendedContent) {
        DDLog(@"已请求老黄历");
    } failure:^(NSString *error) {
        DDLog(@"%@",error);
    }];
}

- (void)sendBang
{
    DDSessionModule* sessionModule = [DDSessionModule shareInstance];
    SessionEntity* sessionEntity = [sessionModule getSessionBySId:@"11m2ec4"];
    NSAttributedString* content = [[NSAttributedString alloc] initWithString:@"#摇一摇#"];
    [[DDMessageSendManager instance] sendMessage:content forSession:sessionEntity success:^(NSString *sendedContent) {
        DDLog(@"已请求摇一摇");
    } failure:^(NSString *error) {
        DDLog(@"%@",error);
    }];
}

- (ServiceAction)regcognizeTheAction:(NSString*)content
{
    //TT_Action:Bang;TT_Content:userId
    NSData* jsonData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* info = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    if (info && [info count] > 0)
    {
        if ([info[DD_TT_ACTION_KEY] isEqualToString:@"Bang"])
        {
            //摇一摇
            return ActionBang;
        }
    }
    else
    {
        return ActionNone;
    }
    return ActionNone;
}

- (NSString*)recognizeTheContent:(NSString*)sender
{
    NSData* jsonData = [sender dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* info = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    if (info && [info count] > 0)
    {
        return info[DD_TT_ACTION_CONTENT];
    }
    else
    {
        return nil;
    }
    return nil;
}

- (void)performTheAction:(ServiceAction)serviceAction withContent:(NSString*)content
{
    switch (serviceAction)
    {
        case ActionBang:
            [self p_performActionBangWithContent:content];
            break;
        case ActionNone:
            break;
    }
}

#pragma mark privateAPI
- (void)p_registerAPI
{
    
}

- (void)n_receiveUserLoginSuccessNotification:(NSNotification*)notification
{
    NSDate* date = [[NSUserDefaults standardUserDefaults] valueForKey:DD_LAST_LOGIN_DATE_KEY];
    NSCalendar *greCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [greCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekCalendarUnit | NSWeekdayCalendarUnit | NSWeekOfMonthCalendarUnit | NSWeekOfYearCalendarUnit fromDate:date];
    
    NSDate* nowDate = [NSDate date];
    NSDateComponents *nowDateComponents = [greCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekCalendarUnit | NSWeekdayCalendarUnit | NSWeekOfMonthCalendarUnit | NSWeekOfYearCalendarUnit fromDate:nowDate];
    if (!(dateComponents.year == nowDateComponents.year && dateComponents.month == nowDateComponents.month && dateComponents.day == nowDateComponents.day))
    {
        //不在同一天，发老黄历
//        [self sendAlmanac];
        [[NSUserDefaults standardUserDefaults] setValue:nowDate forKey:DD_LAST_LOGIN_DATE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    //发送版本更新推送
    NSString* feature = @"- TT最近联系人乱序的bug被修复啦~\n- 小T发消息有特权了哦，（小T说我会跳几下，赶紧读我~）\n- 小T不会每天都发老黄历骚扰大家了哦~（-。-）";
    NSString* key = @"2.64 feature";
    if (![[NSUserDefaults standardUserDefaults] valueForKey:key])
    {
        //发送推送
        MessageEntity* message = [[MessageEntity alloc] init];
        message.msgType = MESSAGE_TYPE_SINGLE;
        message.msgTime = [[NSDate date] timeIntervalSince1970];
        message.seqNo = 0;
        message.sessionId = @"11m2ec4";
        message.msgContent = feature;
        message.senderId = message.sessionId;
        [[DDMessageModule shareInstance] addUnreadMessage:message forSessionID:message.sessionId];
        [[NSUserDefaults standardUserDefaults] setValue:feature forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)p_performActionBangWithContent:(NSString*)content
{
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    UserEntity* user = [userModule getUserById:content];
    if (user)
    {
        [[DDUserInfoManager instance] showUser:user forContext:nil];
    }
}
@end
