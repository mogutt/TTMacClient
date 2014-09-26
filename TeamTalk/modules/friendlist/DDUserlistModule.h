/************************************************************
 * @file         DDFriendlistModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       成员列表管理模块
 ************************************************************/

#import <Foundation/Foundation.h>
#import "UserEntity.h"
#import "DDRootModule.h"
typedef void (^GetAllUserCompletion)(NSArray* allusers, NSError* error);
typedef void (^GetUserInfoCompletion)(UserEntity* user);

@interface DDUserlistModule : DDRootModule
{
    NSMutableDictionary*            _allUsers;          //用户信息列表,key:user id value:UserEntity
    
    NSArray*            _organizationMembers;//组织架构成员
}
@property(nonatomic,strong)NSString*            myUserId;           //我的用户ID
@property(nonatomic,strong,readonly)UserEntity*  myUser;             //我的用户信息
@property(nonatomic,strong)NSMutableArray*      recentlyUserIds;    //最近联系人id列表


-(BOOL)isInIgnoreUserList:(NSString*)userID;

-(void)addUser:(UserEntity*)newUser;

-(void)setOrganizationMembers:(NSArray*)users;

- (NSArray*)getAllUsers;
- (NSArray*)getAllOrganizationMembers;
-(UserEntity *)getUserById:(NSString *)uid;
-(BOOL)isContianUser:(NSString*)uId;

-(void)tcpGetUnkownUserInfo:(NSString*)uId;

-(NSString *)passwordForUserName:(NSString *)userName;
-(void)setPassword:(NSString *)inPassword forUserName:(NSString *)userName;

//- (void)getAllUsersCompletion:(GetAllUserCompletion)commpletion;
- (void)getUserInfoWithUserID:(NSString*)userID completion:(GetUserInfoCompletion)completion;
@end

