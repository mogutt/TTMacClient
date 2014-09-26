//
//  User.h
//  mtalk
//
//  Created by maye on 13-10-25.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserEntity : NSObject

@property(nonatomic,strong) NSString *userId;       //用户ID
@property(nonatomic,strong) NSString *name;         //用户名
@property(nonatomic,strong) NSString *nick;         //用户昵称
@property(nonatomic,strong) NSString *avatar;       //用户头像
@property(nonatomic,strong) NSString *department;   //用户部门
@property(nonatomic,assign) int userRole;        //用户角色(待删除)
@property(nonatomic,assign) int userUpdated;     //用户最近联系时间（待删除）
@property(nonatomic,strong) NSString* title;        //职务
@property(nonatomic,strong) NSString* position;     //位置
@property(nonatomic,assign) int roleStatus;      //用户在职状态
@property(nonatomic,assign) int sex;            //性别
@property(nonatomic,assign) int jobNum;         //工号
@property(nonatomic,strong) NSString* telphone; //电话号码
@property(nonatomic,strong) NSString* email;    //邮箱



-(void)copyContent:(UserEntity*)entity;
-(NSString*)userInfoAvatar;

- (instancetype)initWithUserID:(NSString*)userID name:(NSString*)name nickName:(NSString*)nickName avatar:(NSString*)avatar title:(NSString*)title position:(NSString*)posistion roleState:(int)roleState sex:(int)sex department:(NSString*)department jobNum:(int)jobNum telphone:(NSString*)telPhone email:(NSString*)email;
@end
