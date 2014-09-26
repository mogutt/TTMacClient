//
//  RTXBackgroudColorView.m
//  Duoduo
//
//  Created by zuoye on 13-12-23.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "RTXBackgroudColorView.h"

@implementation RTXBackgroudColorView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(id)initWithColor:(NSColor *)color{
    self = [super init];
    if (self) {
        [self setBackgroundColor:color];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	//[self.backgroundColor set];
    //NSRectFill([self bounds]);
}

@end
