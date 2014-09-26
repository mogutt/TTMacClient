/************************************************************
 * @file         DDLoginModule.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       登陆模块
 ************************************************************/

#import "DDLoginModule.h"
#import "LoginEntity.h"
#import "UserEntity.h"
#import "DDLoginWindowController.h"
#import "DDDictionaryAdditions.h"
#import "NSEvent+DDEventAdditions.h"
#import "DDHttpModule.h"
#import "DDUserListModule.h"
#import "CrashReportManager.h"

static NSString* const keyLastLoginUserName = @"DDLOGINMODULE_LASTLOGINNAME";
static NSString* const keyLastLoginUserPassword = @"DDLOGINMODULE_LASTLOGINPASS";
static NSString* const keyLastLoginUserAvatar = @"DDLOGINMODULE_LASTLOGINAVATAR";

@interface DDLoginModule()

-(void)onHandleTcpData:(uint16)cmdId data:(id)data;

@end

@implementation DDLoginModule
#pragma mark TcpHandle

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_lastLoginName forKey:keyLastLoginUserName];
    [aCoder encodeObject:_lastLoginPass forKey:keyLastLoginUserPassword];
    [aCoder encodeObject:_lastUseAvatar forKey:keyLastLoginUserAvatar];

}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [DDLoginModule shareInstance];
    _lastLoginName = [aDecoder decodeObjectForKey:keyLastLoginUserName];
    _lastLoginPass = [aDecoder decodeObjectForKey:keyLastLoginUserPassword];
    _lastUseAvatar = [aDecoder decodeObjectForKey:keyLastLoginUserAvatar];
    return self;
}
@end
