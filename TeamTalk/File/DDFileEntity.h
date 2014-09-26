//
//  DDFileEntity.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FileType)
{
    SendFileType,
    ReceiveFileType
};

@interface DDFileEntity : NSObject
@property(nonatomic,assign)FileType fileType;
@property(nonatomic,retain)NSString* taskID;
@property(nonatomic,retain)NSString* fromUserID;
@property(nonatomic,retain)NSString* toUserID;
@property(nonatomic,retain)NSString* filePath;
@property(nonatomic,retain)NSString* fileName;
@property(nonatomic,assign)NSInteger fileSize;
@property(nonatomic,retain)NSArray* ips;
@property(nonatomic,assign)int port;

- (id)initWithType:(FileType)fileType taskID:(NSString*)taskID fromUserID:(NSString*)fromUserID toUserID:(NSString*)toUserID filePath:(NSString*)filePath fileName:(NSString*)fileName fileSize:(NSInteger)fileSize ips:(NSArray*)ips port:(int)port;
//- (id)initWithTaskID:(NSString*)taskID toUserID:(NSString*)toUserID filePath:(NSString*)filePath;
@end
