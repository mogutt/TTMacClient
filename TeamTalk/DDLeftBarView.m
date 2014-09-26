//
//  DDLeftBarView.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-24.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDLeftBarView.h"

@implementation DDLeftBarView
{
    NSRect _whiteRect;
}
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _whiteRect = NSZeroRect;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor* backgroundColor = [NSColor colorWithDeviceRed:239.0 / 255.0
                                                     green:239.0 / 255.0
                                                      blue:239.0 / 255.0
                                                     alpha:1];
    [backgroundColor set];
    [[NSBezierPath bezierPath] fill];

//    NSRect sepRect1 = self.bounds;
//    sepRect1.origin.y = 0;
//    sepRect1.origin.x = self.bounds.size.width - 1;
//    sepRect1.size.height = _whiteRect.origin.y;
//    sepRect1.size.width = 1;
//    
//    NSRect sepRect2 = self.bounds;
//    sepRect2.origin.y = _whiteRect.origin.y + _whiteRect.size.height;
//    sepRect2.origin.x = self.bounds.size.width - 1;
//    sepRect2.size.height = self.bounds.size.height - _whiteRect.origin.y - _whiteRect.size.height;
//    sepRect2.size.width = 1;
//    
//    [[NSColor gridColor] set];
//    NSRectFill(sepRect1);
//    NSRectFill(sepRect2);
    
    NSRect sepRect = NSMakeRect(self.bounds.size.width - 1, 0, 1, self.bounds.size.height);
    [[NSColor gridColor] set];
    NSRectFill(sepRect);
    
    [[NSColor whiteColor] set];
    NSRectFill(_whiteRect);
    // Drawing code here.
}

- (void)setSelectIndex:(NSInteger)index
{
    CGFloat itemStartY = self.bounds.size.height - 200;
    CGFloat y = itemStartY - index * self.bounds.size.width;
    _whiteRect = NSMakeRect(0, y, self.bounds.size.width, self.bounds.size.width);
    [self needsDisplay];
}

@end
