/************************************************************
 * @file         DDSessionModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       会话模块
 ************************************************************/

#import <Foundation/Foundation.h>
#import "DDRootModule.h"
//module key names
static NSString* const MKN_DDSESSIONMODULE_GROUPMSG = @"DDSESSIONMODULE_GROUPMSG";          //群消息到达
static NSString* const MKN_DDSESSIONMODULE_SINGLEMSG = @"DDSESSIONMODULE_SGINGLEMSG";       //个人息到达
static NSString* const MKN_DDSESSIONMODULE_HISTORYMSG = @"DDSESSIONMODULE_HISTORYMSG";       //历史消息到达

static NSString* const MKN_DDSESSIONMODULE_MERGERECENTLYLIST = @"DDSESSIONMODULE_MERGERECENTLYLIST";//合并最近联系人+最近联系群
static NSString* const MKN_DDSESSIONMODULE_RECENTLYLIST = @"DDSESSIONMODULE_RECENTLYLIST";  //最近联系会话列表（单个人+群）
static NSString* const MKN_DDSESSIONMODULE_FIXGROUPLIST = @"DDSESSIONMODULE_FIXGROUPLIST";

static NSString* const MKN_DDSESSIONMODULE_GROUPMEMBER = @"DDSESSIONMODULE_GROUPMEMBER";    //群成员改变

static NSString* const MKN_DDSESSIONMODULE_DELETEDFROMGROUP = @"DDSESSIONMODULE_DELETEDFROMGROUP"; //自己被提出群
static NSString* const MKN_DDSESSIONMODULE_SENDMSG_FAILED = @"DDSESSIONMODULE_SENDMESSAGE_FAILED";

@class SessionEntity;
@interface DDSessionModule : DDRootModule
{
    NSMutableDictionary*            _allSessions;   //所有的会话信息 key:session id value:SessionEntity
}
@property(nonatomic,strong) NSMutableArray*     recentlySessionIds;//最近联系会话id列表
@property(nonatomic,strong) NSString* chatingSessionID;



-(SessionEntity*)getSessionBySId:(NSString*)sId;
-(BOOL)isContianSession:(NSString*)sId;
-(SessionEntity*)createSingleSession:(NSString*)sId;
-(SessionEntity*)createGroupSession:(NSString*)sId type:(int)type;
-(void)sortRecentlySessions;
-(void)sortAllGroupUsers;
-(void)tcpSendReadedAck:(SessionEntity*)session;
-(NSArray *)getAllSessions;
/**
 *  获取最新的会话，这里没有置顶会话
 *
 *  @return SessionID
 */
-(NSString*)getLastSession;
-(void)addSession:(SessionEntity*)session;

@end
