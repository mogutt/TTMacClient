//
//  DDAppBackgroundColorView.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-30.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDAppBackgroundColorView.h"

@implementation DDAppBackgroundColorView
- (void)drawRect:(NSRect)dirtyRect
{
    NSColor* backgroundColor = [NSColor whiteColor];
    [backgroundColor set];
    [[NSBezierPath bezierPath] fill];
}
@end
