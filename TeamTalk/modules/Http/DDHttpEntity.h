/************************************************************
 * @file         DDHttpEntity.h
 * @author       快刀<kuaidao@mogujie.com>
 ************************************************************/

#import <Foundation/Foundation.h>
#import "MGJEntity.h"

@interface StatusEntity : MGJEntity

@property (assign, nonatomic) NSInteger code;
@property (strong, nonatomic) NSString *msg;
@property (strong, nonatomic) NSDictionary *userInfo;

@end

@interface DDHttpEntity : MGJEntity

@property (strong, nonatomic) StatusEntity *status;
@property (strong, nonatomic) NSDictionary *result;

@end
