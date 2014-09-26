/************************************************************
 * @file         DDLoginModule+UserManager.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       登陆模块，用户信息扩展 注：需要用DDlogic序列化机制重构
 ************************************************************/

#import "DDLoginModule.h"

#define LOGIN_PREFERENCES_FILE_NAME @"Login Preferences"	//Login preferences file name
#define LOGIN_SHOW_WINDOW 			@"Show Login Window"	//Should hide the login window

#define LOGIN_LAST_USER				@"Last Login Name"		//Last logged in user
#if defined (DEBUG_BUILD) && ! defined (RELEASE_BUILD)
#	define LOGIN_LAST_USER_DEBUG	@"Last Login Name-Debug"//Last logged in user - debug
#endif

@interface DDLoginModule(UserInfoManager)

@property (nonatomic, readonly) NSString *userDirectory;
@property (nonatomic, readonly) NSString *currentUser;
@property (nonatomic, readonly) NSArray *userArray;     //多帐号.

-(void)addUser:(NSString *)inUserName;
-(void)deleteUser:(NSString *)inUserName;
-(void)renameUser:(NSString *)oldName to:(NSString *)newName;

@end
