//
//  DDPullFileDataEntity.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-20.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDPullFileDataEntity : NSObject
@property (nonatomic,retain)NSString* taskID;
@property (nonatomic,retain)NSString* userID;
@property (nonatomic,assign)int mode;
@property (nonatomic,assign)int offset;
@property (nonatomic,assign)int dataSize;
- (id)initWithTaskID:(NSString*)taskID userID:(NSString*)userID mode:(int)mode offset:(int)offset dataSize:(int)dataSize;
@end
