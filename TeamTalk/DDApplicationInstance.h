/************************************************************
 * @file         DDApplicationInstance.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       多多应用程序级别相关的业务处理
 ************************************************************/

#import <Foundation/Foundation.h>

@class DDMainWindowController;
@interface DDApplicationInstance : NSObject

+(DDApplicationInstance*)instance;
//初始化应用程序级别业务，如DDLogic框架初始化
-(BOOL)startup;
-(void)shutdown;

//登陆
-(BOOL)doLogin;

@end
