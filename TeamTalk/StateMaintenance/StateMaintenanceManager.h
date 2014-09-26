//
//  StateMaintenanceManager.h
//  Duoduo
//
//  Created by 独嘉 on 14-4-4.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  用户在线状态的维护
 */
extern NSString* const notificationonlineStateChange;

typedef NS_ENUM(NSInteger, UserState){
    USER_STATUS_ONLINE = 1,
    USER_STATUS_OFFLINE = 2,
    USER_STATUS_LEAVE = 3,
};


@interface StateMaintenanceManager : NSObject
+ (instancetype)instance;

/**
 *  添加维护的用户ID
 *
 *  @param userID 用户ID
 */
- (void)addMaintenanceManagerUserID:(NSString*)userID;

/**
 *  获得用户的在线状态
 *
 *  @param userID 用户ID
 *
 *  @return 在线状态
 */
- (UserState)getUserStateForUserID:(NSString*)userID;

/**
 *  将所有用户的状态设置为离线
 */
- (void)offlineAllUser;

/**
 *  与服务器返回的在线状态进行merge,全部更新
 *
 *  @param onlineState 服务器端返回的在线状态
 */
- (void)mergerUsersOnlineState:(NSDictionary*)onlineState;

/**
 *  获取在线状态变更时更新本地维护的在线状态
 *
 *  @param onlineState 待更新的在线状态
 */
- (void)updateUsersOnlineStateForUserInDic:(NSDictionary*)onlineState;

/**
 *  获取自己的在线状态
 *
 *  @return 在线状态
 */
- (UserState)getMyOnlineState;

/**
 *  改变自己的在线状态
 *
 *  @param state 在线状态
 */
- (void)changeMyOnlineState:(UserState)state;

/**
 *  更新用户在线状态，只用于初始化获取群成员在线状态的时候被调用
 *
 *  @param userIDs 用户ID数组
 */
- (void)updateUsersOnlineState:(NSArray*)userIDs;

/**
 *  开始维护在线状态
 */
- (void)beginMaintanceOnlineState;

/**
 *  改变一个用户的展现状态，不发通知
 *
 *  @param userID      用户ID
 *  @param state       在线状态
 */
- (void)changeUserOnlineState:(NSString*)userID onlineState:(UserState)state;
@end
