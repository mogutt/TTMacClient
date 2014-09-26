//
//  User.m
//  mtalk
//
//  Created by maye on 13-10-25.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "UserEntity.h"

@implementation UserEntity

-(void)copyContent:(UserEntity*)entity
{
    _userId = [entity.userId copy];
    self.name = [entity.name copy];
    self.nick = [entity.nick copy];
    self.avatar = [entity.avatar copy];
    self.department = [entity.department copy];
    self.userRole = entity.userRole;
    self.userUpdated = entity.userUpdated;
}


- (instancetype)initWithUserID:(NSString*)userID name:(NSString*)name nickName:(NSString*)nickName avatar:(NSString*)avatar title:(NSString*)title position:(NSString*)posistion roleState:(int)roleState sex:(int)sex department:(NSString*)department jobNum:(int)jobNum telphone:(NSString*)telPhone email:(NSString*)email
{
    self = [super init];
    if (self)
    {
        _userId = [userID copy];
        _name = [name copy];
        _nick = [nickName copy];
        _avatar = [avatar copy];
        _title = [title copy];
        _position = [posistion copy];
        _roleStatus = roleState;
        _sex = sex;
        _department = [department copy];
        _jobNum = jobNum;
        _telphone = [telPhone copy];
        _email = [email copy];
    }
    return self;
}

- (NSString*)avatar
{
    if (_avatar && [_avatar length] > 0)
    {
        if (![_avatar hasSuffix:@"_100x100.jpg"]) {
            _avatar = [NSString stringWithFormat:@"%@%@",_avatar,@"_100x100.jpg"];
        }
    }
    return _avatar;
}

-(NSString*)userInfoAvatar
{
    if (_avatar && [_avatar length] > 0)
    {
        if (![_avatar hasSuffix:@"_200x200.jpg"]) {
            _avatar = [NSString stringWithFormat:@"%@%@",_avatar,@"_200x200.jpg"];
        }
    }
    return _avatar;
}


@end
