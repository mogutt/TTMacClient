//
//  DDMessageSendManager.h
//  Duoduo
//
//  Created by 独嘉 on 14-3-30.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger, MessageType)
{
    AllString,
    HasImage
};

@class MessageEntity,SessionEntity;
@interface DDMessageSendManager : NSObject
@property (nonatomic,readonly)dispatch_queue_t sendMessageSendQueue;
@property (nonatomic,readonly)NSMutableArray* waitToSendMessage;
+ (instancetype)instance;

/**
 *  发送消息
 *
 *  @param content 发送内容，是富文本
 *  @param session 所属的会话
 */
- (void)sendMessage:(NSAttributedString*)content forSession:(SessionEntity*)session success:(void(^)(NSString* sendedContent))success  failure:(void(^)(NSString*))failure;

@end

@interface NSAttributedString(MessageSendManager)

- (MessageType)messageType;
- (NSString*)getAllStringContentFromInput;
- (NSString*)getHasImageContentFromInput;
@end