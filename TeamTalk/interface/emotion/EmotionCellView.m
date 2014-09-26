//
//  EmotionCellView.m
//  Duoduo
//
//  Created by jianqing.du on 14-1-21.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "EmotionCellView.h"
#import "EmotionViewController.h"


@implementation EmotionCellView {
    BOOL drawRect;
    NSBezierPath *path;
}

@synthesize emotionViewController;
@synthesize emotionFile;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    if (drawRect && self.imageView.objectValue) {
        NSRect bounds = [self bounds];

        [[NSColor blueColor] set];
        [path removeAllPoints];
        [path appendBezierPathWithRect:bounds];
        [path stroke];
    } else {
        [path removeAllPoints];
        [path stroke];
    }
}

- (void)awakeFromNib
{
    NSTrackingArea *trackArea =
    [[NSTrackingArea alloc] initWithRect:[self bounds]
                                 options:NSTrackingMouseEnteredAndExited |  NSTrackingActiveInKeyWindow
                                   owner:self
                                userInfo:nil];
    [self addTrackingArea:trackArea];
    
    path = [NSBezierPath bezierPath];
    [path setLineWidth:1.5];
    self.button =[[NSButton alloc] initWithFrame:self.frame];
    [self.button setTitle:@""];
    [self.button setBordered:NO];
    [ self.button  setTarget:self];
    [ self.button setAction:@selector(buttonClick)];
   [self addSubview:self.button positioned:NSWindowAbove relativeTo:self.imageView];
}
-(void)buttonClick
{
       [emotionViewController clickEmotionView:self];
}
- (void)mouseEntered:(NSEvent *)theEvent
{
    //DDLog(@"mouseEntered");
    drawRect = YES;
    [self setNeedsDisplay:YES];
    [emotionViewController showEmotionPreview:self];
    
}

- (void)mouseExited:(NSEvent *)theEvent
{
    //DDLog(@"mouseExited");
    drawRect = NO;
    [self setNeedsDisplay:YES];
    [emotionViewController hiddenEmotionPreview];
}

//- (void)mouseDown:(NSEvent *)theEvent
//{
//    DDLog(@"move down in cell view");
//    [super mouseDown:theEvent];
//    [emotionViewController clickEmotionView:self];
//}


@end
