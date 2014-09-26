//
//  DDOriginzationModule.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-18.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DDOriginzationModule : NSObject
@property (nonatomic,retain)NSDictionary* originzation;
- (id)childItemAtIndex:(NSInteger)index forItem:(id)item;
@end
