/************************************************************
 * @file         NSDictionary+MGJ.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       NSDictionary的扩展
 ************************************************************/

#import "NSDictionary+MGJ.h"

@implementation NSDictionary (MGJ)

-(BOOL)containKey:(NSString *)key{
    return [[self allKeys]containsObject:key];
}

-(id)safeDataForKey:(NSString *)key{
    if ([self containKey:key]) {
        id value = [self objectForKey:key];
        
        return value;
    }
    
    return nil;
}

@end
