//
//  DDChattingViewModule.h
//  Duoduo
//
//  Created by 独嘉 on 14-3-18.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SessionEntity,MessageEntity;
@interface DDChattingViewModule : NSObject<EGOImageViewDelegate>
@property (nonatomic,readonly)SessionEntity* session;

- (id)initWithSession:(SessionEntity*)session;


- (NSAttributedString*)getAttributedStringFromInputContent:(NSAttributedString*)inputContent compress:(BOOL)compress;
- (NSAttributedString*)getAttributedStringFromShowMessage:(MessageEntity*)message;

@end
