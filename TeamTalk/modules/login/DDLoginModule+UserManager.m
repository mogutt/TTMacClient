/************************************************************
 * @file         DDLoginModule+UserManager.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       登陆模块，用户信息扩展 注：注：需要用DDlogic序列化机制重构
 ************************************************************/
#import "DDLoginModule+UserManager.h"
#import "NSFileManager+DDFileManagerAdditions.h"

//Paths & Filenames
#define PATH_USERS 			@"/Users"		//Path of the users folder
//Other
#define DEFAULT_USER_NAME		@"Default"		//The default user name

@implementation DDLoginModule(UserInfoManager)

#pragma mark 用户数据存储
// Returns the current user's Adium home directory
- (NSString *)userDirectory
{
    return self.userDirectory;
}

- (NSString *)currentUser
{
    return self.currentUser;
}

// Creates and returns a mutable array of the login users
- (NSArray *)userArray
{
    BOOL			isDirectory;
    
    //Get the users path
    NSString *userPath = [[duoduo applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS];
    
    //Build the user array
    NSMutableArray *userArray = [NSMutableArray array];
    
	for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:userPath error:NULL]) {
        //Fetch the names of all directories
        if ([[NSFileManager defaultManager] fileExistsAtPath:[userPath stringByAppendingPathComponent:path] isDirectory:&isDirectory]) {
            if (isDirectory) {
                [userArray addObject:[path lastPathComponent]];
            }
        }
    }
    
    return userArray;
}

// Delete a user
- (void)deleteUser:(NSString *)inUserName
{
    NSString	*sourcePath;
    
    NSParameterAssert(inUserName != nil);
    
    //Create the source and dest paths
    sourcePath = [[[duoduo applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:inUserName];
	[[NSFileManager defaultManager] trashFileAtPath:sourcePath];
}

// Add a user with the specified name
- (void)addUser:(NSString *)inUserName
{
    NSString	*userPath;
    
    NSParameterAssert(inUserName != nil);
    
    //Create the user path
    userPath = [[[duoduo applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:inUserName];
    
    //Create a folder for the new user
    [[NSFileManager defaultManager] createDirectoryAtPath:userPath withIntermediateDirectories:YES attributes:nil error:NULL];
}

// Rename an existing user
- (void)renameUser:(NSString *)oldName to:(NSString *)newName
{
    NSString	*sourcePath, *destPath;
    
    NSParameterAssert(oldName != nil);
    NSParameterAssert(newName != nil);
    
    //Create the source and dest paths
    sourcePath = [[[duoduo applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:oldName];
    destPath = [[[duoduo applicationSupportDirectory] stringByAppendingPathComponent:PATH_USERS] stringByAppendingPathComponent:newName];
    
    //Rename the user's folder (by moving it to a path with a different name)
    [[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:destPath error:NULL];
}

@end
