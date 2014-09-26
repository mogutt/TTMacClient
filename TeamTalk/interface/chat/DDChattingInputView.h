//
//  DDChattingInputView.h
//  Duoduo
//
//  Created by zuoye on 13-12-3.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DDSendingTextView.h"
#import "DDImageMessage.h"
#import "SessionEntity.h"


@interface DDChattingInputView : DDSendingTextView<NSTextViewDelegate>{
    NSMutableArray		*historyArray;
    NSMutableArray  *sendQueue;
    int                  currentHistoryLocation;
    SessionEntity *sessonEntity;
    DDImageMessage *imageMessage;
}
@property (nonatomic,assign)NSUInteger currentIndex;
- (void)pasteAsPlainTextWithTraits:(id)sender;
- (NSImage *)currentImage;
- (void)setSessionEntity: (SessionEntity *)session;
@end
