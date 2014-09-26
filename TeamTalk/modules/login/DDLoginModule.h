/************************************************************
 * @file         DDLoginModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       登陆模块
 ************************************************************/

#import <Foundation/Foundation.h>
#import "DDRootModule.h"

@class DDLoginWindowController;
@class ReloginManager;
@interface DDLoginModule : DDRootModule<NSCoding>
{
    DDLoginWindowController*    _loginWindowController;
}
@property(nonatomic,strong)NSString* lastLoginName; //临时放在这里存储用户名
@property(nonatomic,strong)NSString* lastLoginPass; //临时放在这里存储密码
@property(nonatomic,strong)NSString* lastUseAvatar; //临时放在这里存储用户头像

-(id) initModule;
-(void)relogin:(BOOL)force status:(uint32)status;

@end

extern DDLoginModule* getDDLoginModule();