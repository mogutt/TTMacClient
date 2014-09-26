//
//  DDOfflineFileEntity.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-22.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDOfflineFileEntity : NSObject
@property (nonatomic,retain)NSString* fromUserID;
@property (nonatomic,retain)NSString* taskID;
@property (nonatomic,retain)NSString* fileName;
@property (nonatomic,assign)int fileSize;
@property (nonatomic,retain)NSArray* ipArray;
@property (nonatomic,assign)uint16 port;
- (id)initWithFromUserID:(NSString*)fromUserID taskID:(NSString*)taskID fileName:(NSString*)fileName fileSize:(int)fileSize ipArray:(NSArray*)ips port:(uint16)port;
@end
