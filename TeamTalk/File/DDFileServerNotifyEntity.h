//
//  DDFileServerNotifyEntity.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-22.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

typedef NS_ENUM(NSInteger, ClientFileState)
{
    CLIENT_FILE_PEER_READY = 0,
    CLIENT_FILE_CANCEL,
    CLIENT_FILE_REFUSE,
    CLIENT_FILE_DONE
};

#import <Foundation/Foundation.h>

@interface DDFileServerNotifyEntity : NSObject
@property (nonatomic,assign)ClientFileState state;
@property (nonatomic,retain)NSString* taskID;
@property (nonatomic,retain)NSString* userID;

- (id)initWithState:(ClientFileState)state taskID:(NSString*)taskID userID:(NSString*)userID;
@end
