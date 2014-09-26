//
//  DDImageUploader.h
//  Duoduo
//
//  Created by 独嘉 on 14-3-30.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDImageUploader : NSObject
+ (instancetype)instance;
- (void)uploadImage:(NSImage*)image success:(void(^)(NSString* imageURL))success failure:(void(^)(id error))failure;
@end
