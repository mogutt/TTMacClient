//
//  DDContactObserverManager.m
//  Duoduo
//
//  Created by zuoye on 13-11-25.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "DDContactObserverManager.h"
#import "DDListObject.h"

@interface DDContactObserverManager ()
- (NSSet *)_informObserversOfObjectStatusChange:(DDListObject *)inObject withKeys:(NSSet *)modifiedKeys silent:(BOOL)silent;
- (void)_performDelayedUpdates:(NSTimer *)timer;
@property (nonatomic) NSTimer *delayedUpdateTimer;
@end


static DDContactObserverManager *sharedObserverManager = nil;

@implementation DDContactObserverManager

+ (DDContactObserverManager *)sharedManager
{
	if(!sharedObserverManager)
		sharedObserverManager = [[self alloc] init];
	return sharedObserverManager;
}

- (id)init
{
	if ((self = [super init])) {
        
    }
	
	return self;
}


@end
