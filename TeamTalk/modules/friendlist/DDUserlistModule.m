
/************************************************************
 * @file         DDFriendlistModule.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       成员列表管理模块
 ************************************************************/

#import "DDUserlistModule.h"
#import "DDSessionModule.h"
#import "DDGroupModule.h"
#import "UserEntity.h"
#import "GroupEntity.h"
#import "DDKeychain.h"
#import "SpellLibrary.h"
#import "SessionEntity.h"
#import "StateMaintenanceManager.h"
#import "DDUserInfoAPI.h"

static NSInteger const getAllUsersTimeout = 5;

@interface DDUserlistModule(PrivateAPI)

-(void)onHandleTcpData:(uint16)cmdId data:(id)data;
//-(void)syncStatusToUserlist;
-(void)offlineAllUserlist;

- (void)n_receiveGetAllUsersNotification:(NSNotification*)notification;

@end

@implementation DDUserlistModule
{
    NSArray* _ignoreUserList;
}

+ (instancetype)shareInstance
{
    
    static DDUserlistModule* g_rootModule;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_rootModule = [[DDUserlistModule alloc] init];
    });
    return g_rootModule;
}

-(id) init
{
    if(self = [super init])
    {
        _allUsers = [[NSMutableDictionary alloc ] init];
        _ignoreUserList = @[@"1szei2"];
    }
    return self;
}

#pragma mark Public

-(BOOL)isInIgnoreUserList:(NSString*)userID
{
    if ([_ignoreUserList containsObject:userID])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(void)addUser:(UserEntity*)newUser
{
    if (newUser)
    {
        if (newUser.userUpdated == 0)
        {
            [_allUsers setObject:newUser forKey:newUser.userId];
        }
        else
        {
            [_allUsers setObject:newUser forKey:newUser.userId];
        }
    }
}

-(void)setOrganizationMembers:(NSArray*)users
{
    if (_organizationMembers)
    {
        _organizationMembers = nil;
    }
    _organizationMembers = users;
}

- (NSArray*)getAllUsers
{
    NSMutableArray* allUsers = [[NSMutableArray alloc] init];
    [_allUsers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//        if ([[(UserEntity*)obj name] isEqualToString:@"千凡"])
//        {
//            DDLog(@"asd");
//        }
        [allUsers addObject:obj];
    }];
    return allUsers;
}
- (NSArray*)getAllOrganizationMembers
{
    return _organizationMembers;
}

-(UserEntity*)myUser
{
    return [_allUsers objectForKey:self.myUserId];
}

-(BOOL)isContianUser:(NSString*)uId
{
     return ([_allUsers valueForKey:uId] != nil);
}

-(UserEntity *)getUserById:(NSString *)uid
{
    return [_allUsers objectForKey:uid];
}

-(NSString *)passwordForUserName:(NSString *)userName{
    NSError *error =nil;
    DDKeychain *keychain = [DDKeychain defaultKeychain_error:&error];
    NSString *password = [keychain internetPasswordForServer:@"duoduo" account:userName protocol:FOUR_CHAR_CODE('DDIM') error:&error ];
    if (error) {
        OSStatus err = (OSStatus)[error code];
        NSDictionary *userInfo = [error userInfo];
        DDLog(@"could not retrieve password for account %@: %@ returned %ld (%@)",userName, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], (long)err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
    }
    return  password;
}

- (void)setPassword:(NSString *)inPassword forUserName:(NSString *)userName
{
	NSError *error = nil;
	[[DDKeychain defaultKeychain_error:&error] setInternetPassword:inPassword
														 forServer:@"duoduo"
														   account:userName
														  protocol:FOUR_CHAR_CODE('DDIM')
															 error:&error];
	if (error) {
		OSStatus err = (OSStatus)[error code];
		/*errSecItemNotFound: no entry in the keychain. a harmless error.
		 *we don't ignore it if we're trying to set the password, though (because that would be strange).
		 *we don't get here at all for noErr (error will be nil).
		 */
		if (inPassword || (err != errSecItemNotFound)) {
			NSDictionary *userInfo = [error userInfo];
			DDLog(@"could not %@ password for account %@: %@ returned %ld (%@)", inPassword ? @"set" : @"remove", userName, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_SECURITYFUNCTIONNAME], (long)err, [userInfo objectForKey:AIKEYCHAIN_ERROR_USERINFO_ERRORDESCRIPTION]);
		}
	}
}

- (void)getUserInfoWithUserID:(NSString*)userID completion:(GetUserInfoCompletion)completion
{
    UserEntity* user = [self getUserById:userID];
    if (user)
    {
        completion(user);
        return;
    }
    DDUserInfoAPI* userInfoAPI = [[DDUserInfoAPI alloc] init];
    [userInfoAPI requestWithObject:@[userID] Completion:^(id response, NSError *error) {
        if (!error)
        {
            [self addUser:response[0]];
            completion(response[0]);
        }
        else
        {
            DDLog(@"error%@ userID:%@",[error domain],userID);
            [self getUserInfoWithUserID:userID completion:completion];
        }
    }];
}

#pragma mark PrivateAPI
@end
