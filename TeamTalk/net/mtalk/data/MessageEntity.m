/************************************************************
 * @file         MessageEntity.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       消息实体信息
 ************************************************************/

#import "MessageEntity.h"
#import "GroupEntity.h"
#import "DDMessageModule.h"
@implementation MessageEntity

//注：由于groupId和userId会存在重复情况，对groupId加个前缀
-(void)setSessionId:(NSString*)sId;
{
    if(CHECK_MSG_TYPE_GROUP(_msgType))
    {
        _sessionId = [NSString stringWithFormat:@"%@%@",GROUP_PRE,sId];
    }
    else
    {
        _sessionId = sId;
    }
}

-(NSString*)orginId
{
    if(CHECK_MSG_TYPE_GROUP(_msgType))
    {
        return [_sessionId substringFromIndex:[GROUP_PRE length]];
    }
    else
    {
        return _sessionId;
    }
}

- (BOOL)isEqualToMessage:(MessageEntity*)object
{
    if (self == object)
    {
        return YES;
    }
    if (![self.msgContent isEqualToString:object.msgContent])
    {
        return NO;
    }
    if (self.msgTime != object.msgTime)
    {
        return NO;
    }
    return YES;
}

- (BOOL)isEqual:(id)object
{
    if ([object class] == [self class])
    {
        return [self isEqualToMessage:(MessageEntity*)object];
    }
    else
    {
        return [super isEqual:object];
    }
}

@end
