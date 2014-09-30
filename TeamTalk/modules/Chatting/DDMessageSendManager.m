
//
//  DDMessageSendManager.m
//  Duoduo
//
//  Created by 独嘉 on 14-3-30.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDMessageSendManager.h"
#import "DDEmotionAttachment.h"
#import "DDImageUploader.h"
#import "DDUserlistModule.h"
#import "SessionEntity.h"
#import "MessageEntity.h"
#import "DDMessageModule.h"
#import "DDSendMessageAPI.h"
static uint32_t seqNo = 0;

@interface DDMessageSendManager(PrivateAPI)

- (void)sendSimpleMessage:(NSAttributedString *)content forSession:(SessionEntity *)session success:(void (^)(NSString *))success failure:(void(^)(NSString*))failure;
- (void)sendMixMessage:(NSAttributedString *)content forSession:(SessionEntity *)session success:(void (^)(NSString *))success failure:(void(^)(NSString*))failure;
- (MessageEntity*)messageWithSession:(SessionEntity*)session contentToSend:(NSString*)content;

@end

@implementation DDMessageSendManager
{
    NSUInteger _uploadImageCount;
}
+ (instancetype)instance
{
    static DDMessageSendManager* g_messageSendManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_messageSendManager = [[DDMessageSendManager alloc] init];
    });
    return g_messageSendManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _uploadImageCount = 0;
        _waitToSendMessage = [[NSMutableArray alloc] init];
        _sendMessageSendQueue = dispatch_queue_create("com.mogujie.Duoduo.sendMessageSend", NULL);
        
    }
    return self;
}

- (void)sendMessage:(NSAttributedString*)content forSession:(SessionEntity*)session success:(void(^)(NSString* sendedContent))success failure:(void(^)(NSString*))failure
{
    MessageType messageType = [content messageType];
    if (messageType == AllString)
    {
        [self sendSimpleMessage:content forSession:session success:^(NSString *sendedContent) {
            success(sendedContent);
        } failure:^(NSString *content) {
            failure(content);
        } ];
    }
    else if (messageType == HasImage)
    {
        [self sendMixMessage:content forSession:session success:^(NSString *sendedContent) {
            success(sendedContent);
        } failure:^(NSString *content){
            failure(content);
        }];
    }
}

#pragma mark Private API
- (void)sendSimpleMessage:(NSAttributedString *)content forSession:(SessionEntity *)session success:(void (^)(NSString *))success failure:(void(^)(NSString *content))failure
{
    dispatch_async(self.sendMessageSendQueue, ^{
        NSString* string = [content getAllStringContentFromInput];
        DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
        
        DDSendMessageAPI* sendMessageAPI = [[DDSendMessageAPI alloc] init];
        uint32_t nowSeqNo = ++seqNo;
        //
//        NSMutableData* data = [TcpProtocolPack getSendMsgData:userListModule.myUserId
//                                                       toUser:session.orginId
//                                                      content:string
//                                                  messageType:session.type
//                                                        seqNo:++seqNo];
//        
//        [[DDTcpClientManager instance] writeToSocket:data];
        //
        uint8 type;
        switch (session.type)
        {
            case SESSIONTYPE_SINGLE:
                type = MSG_TYPE_SINGLE_TEXT;
                break;
            case SESSIONTYPE_GROUP:
                type = MSG_TYPE_GROUP_TEXT;
                break;
        }
        NSArray* object = @[userListModule.myUserId,session.orginId,string,[NSNumber numberWithInt:nowSeqNo],[NSNumber numberWithInt:type]];
        [sendMessageAPI requestWithObject:object Completion:^(id response, NSError *error) {
            if (!error)
            {
                uint32_t returnSeqNo = [response intValue];
                if (returnSeqNo == nowSeqNo)
                {
                    success(string);
                }
                else
                {
                    failure(@"seqNo不同");
                    DDLog(@"different seqNo");
                }
            }
            else
            {
                failure(@"发送超时");
            }
        }];
        log4CInfo(@"send message to user:%@ :%@",session.orginId,string);
        
    });
}

- (void)sendMixMessage:(NSAttributedString *)content forSession:(SessionEntity *)session success:(void (^)(NSString *))success failure:(void(^)(NSString* ))failure
{
    dispatch_async(self.sendMessageSendQueue, ^{
        NSString* string = [content getHasImageContentFromInput];
        DDUserlistModule* userListModule = [DDUserlistModule shareInstance];

        DDSendMessageAPI* sendMessageAPI = [[DDSendMessageAPI alloc] init];
        uint32_t nowSeqNo = ++seqNo;
        uint8 type;
        switch (session.type)
        {
            case SESSIONTYPE_SINGLE:
                type = MSG_TYPE_SINGLE_TEXT;
                break;
            case SESSIONTYPE_GROUP:
                type = MSG_TYPE_GROUP_TEXT;
                break;
        }
        NSArray* object = @[userListModule.myUserId,session.orginId,string,[NSNumber numberWithInt:nowSeqNo],[NSNumber numberWithInt:type]];
        
        [sendMessageAPI requestWithObject:object Completion:^(id response, NSError *error) {
            if (!error)
            {
                uint32_t returnSeqNo = [response intValue];
                if (returnSeqNo == nowSeqNo)
                {
                    success(string);
                }
                else
                {
                    failure(@"seqNo不同");
                    DDLog(@"different seqNo");
                }
                
            }
            else
            {
                failure(@"发送超时");
            }
        }];
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            success(string);
//        });
//        double delayInSeconds = 5.0;
//        uint32 checkSeq = seqNo;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            DDMessageModule* messageModule = getDDMessageModule();
//            BOOL sendSuccess = [messageModule sendSuccessForMsg:checkSeq];
//            if (!sendSuccess)
//            {
//                failure(string);
//            }
//        });
    });
}

- (MessageEntity*)messageWithSession:(SessionEntity*)session contentToSend:(NSString*)content
{
    MessageEntity* message = [[MessageEntity alloc] init];
    switch (session.type) {
        case SESSIONTYPE_SINGLE:
            message.msgType = MESSAGE_TYPE_SINGLE;
            break;
        case SESSIONTYPE_GROUP:
            message.msgType = MESSAGE_TYPE_GROUP;
            break;
    }
    message.sessionId = [session.orginId copy];
    message.senderId = [DDUserlistModule shareInstance].myUserId;
    message.msgContent = content;
    message.seqNo = seqNo;
    message.msgTime = [[NSDate date] timeIntervalSince1970];
    return message;
}

@end

@implementation NSAttributedString (MessageSendManager)

- (MessageType)messageType
{
    MessageType messageType = AllString;
    for (int i=0; i<self.length; i++) {
        NSTextAttachment *attachment = [self attribute:NSAttachmentAttributeName atIndex:i effectiveRange:NULL];
        if (attachment) {
            if (![attachment isKindOfClass:[DDEmotionAttachment class]])
            {
                messageType = HasImage;
            }
        }
    }
    return messageType;
}

- (NSString*)getAllStringContentFromInput
{
    NSMutableString* resultString = [[NSMutableString alloc] init];
    NSAttributedString *text = self;
    if (text.length ) {
        int index=0;
        for (int i=0; i<text.length; i++)
        {
            NSTextAttachment *attachment = [text attribute:NSAttachmentAttributeName atIndex:i effectiveRange:NULL];
            if (attachment)
            {
                if ([attachment isKindOfClass:[DDEmotionAttachment class]])
                {
                    NSString *emotionText =  [(DDEmotionAttachment *)attachment emotionText];
                    [resultString appendString:emotionText];
                    index+=[emotionText length];
                }
            }else
            {
                [resultString appendString:[[text attributedSubstringFromRange:NSMakeRange(i, 1)] string]];
            }
            
            
        }
    }
    return resultString;
}

- (NSString*)getHasImageContentFromInput
{
    NSMutableString* resultContent = [[NSMutableString alloc] init];
    NSAttributedString *text = self;
    for (int i=0; i<text.length; i++)
    {
        NSTextAttachment *attachment = [text attribute:NSAttachmentAttributeName atIndex:i effectiveRange:NULL];
        if (attachment)
        {
            if (![attachment isKindOfClass:[DDEmotionAttachment class]])
            {
                //是图片不是表情
                NSImage *image = nil;
                if ([attachment respondsToSelector:@selector(image)])
                {
                    image = [attachment performSelector:@selector(image)];
                }
                if(!image)
                {
                    if ([[attachment attachmentCell] respondsToSelector:@selector(image)])
                    {
                        image = [[attachment attachmentCell] performSelector:@selector(image)];
                    }
                }
                //上传图片
                __block BOOL finishUpLoadImage = NO;
                [[DDImageUploader instance] uploadImage:image
                                                success:^(NSString *imageURL) {
                                                    [resultContent appendString:imageURL];
                                                    finishUpLoadImage = YES;
                                                }
                                                failure:^(id error) {
                                                    finishUpLoadImage = YES;
                                                    log4Error(@"upload image error");
                                                }];
                __block double delayInSeconds = 20.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    finishUpLoadImage = YES;
                });
                while (!finishUpLoadImage)
                {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//                    DDLog(@"------------------------------<正在上传图片 ***%@>",run ? @"YES" : @"NO");

                }
            }
            else
            {
                //是表情
                NSString *emotionText =  [(DDEmotionAttachment *)attachment emotionText];
                [resultContent appendString:emotionText];
            }
        }else
        {
            //是文字
            [resultContent appendString:[[text attributedSubstringFromRange:NSMakeRange(i, 1)] string]];
        }
    }
    return resultContent;
}
@end