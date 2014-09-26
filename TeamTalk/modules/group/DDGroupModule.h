/************************************************************
 * @file         DDGroupModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       群主列表管理
 ************************************************************/

#import <Foundation/Foundation.h>
#import "DDRootModule.h"
typedef void(^GetGroupInfoCompletion)(GroupEntity* group);

@class GroupEntity;
@interface DDGroupModule : DDRootModule
{
    NSMutableDictionary*            _allGroups;         //所有群列表,key:group id value:GroupEntity
    NSMutableDictionary*            _allFixedGroup;     //所有固定群列表
}
@property(nonatomic,strong)NSMutableArray*      recentlyGroupIds;      //最近联系群id列表

-(BOOL)isInIgnoreGroups:(NSString*)groupID;
-(GroupEntity*)getGroupByGId:(NSString*)gId;
-(BOOL)isContainGroup:(NSString*)gId;
-(NSArray*)getAllGroups;
-(NSArray*)getAllFixedGroups;
-(void)tcpGetUnkownGroupInfo:(NSString*)gId;
-(void)addGroup:(GroupEntity*)newGroup;
- (void)addFixedGroup:(GroupEntity*)newGroup;

- (void)getGroupInfogroupID:(NSString*)groupID completion:(GetGroupInfoCompletion)completion;
@end
