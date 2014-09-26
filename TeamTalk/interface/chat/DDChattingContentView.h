//
//  DDChattingContentView.h
//  Duoduo
//
//  Created by jianqing.du on 14-1-13.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SessionEntity.h"

typedef enum {
    MSG_TYPE_TEXT   = 1,
    MSG_TYPE_IMAGE  = 2,
    // for internal user
    MSG_TYPE_DATE   = 3,    // dispaly a date in center
    MSG_TYPE_NAME   = 4,    // display a username in left for group
} MsgType;

@interface DDChattingContentView : NSTextView <NSTextViewDelegate>

- (void)setGroupFlag:(BOOL)groupFlag;
- (void)setSessionEntity: (SessionEntity *)session;

- (void)addMsg:(NSString *)msgData
        ofType:(MsgType)msgType
      fromUser:(NSString *)fromUserId   // set fromUserId to nil for self
          date:(NSDate *)date
       atIndex:(NSUInteger *)indexPointer   // used to replace asyn image
         atEnd:(BOOL)atEnd              // insert at begin or end
    isComplete:(BOOL)isComplete;        // is the the last part of the message

- (void)replaceImage:(NSString *)imagePath
             atIndex:(NSUInteger)index
            fromUser:(NSString *)fromUserId;

- (void)resetHistoryMsgInsertInfo;

- (void)requestHistoryMessage;

- (void)displaySystemTips:(NSString *)tips;

@end
