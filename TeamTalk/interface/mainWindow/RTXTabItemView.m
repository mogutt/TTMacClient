//
//  RTXTabItemView.m
//  Duoduo
//
//  Created by zuoye on 13-12-23.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "RTXTabItemView.h"

@implementation RTXTabItemView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //self.imageSize = 0x4044000000000000;
       
    }
    return self;
    
    /*
     var_32 = rdi;
     var_40 = *0x1002c3618;
     rax = [[&var_32 super] initWithFrame:edx];
     if (rax != 0x0) {
     rbx.imageSize = 0x4044000000000000;
     *0x0 = 0x4036000000000000;
     [rbx setTrackingMouse:0x1];
     }
     rax = rbx;
     return rax;
     */
}

- (void)drawRect:(NSRect)dirtyRect
{
    
    
    NSImage *drawImage;
	if (self.bHighetLight !=NO) {
        drawImage = self.selectImage;
    }else{
        drawImage=self.alterImage;
        if (bMouseDown) {
        }
    }
    NSPoint point= NSMakePoint(1, 0);
    [drawImage drawAtPoint:point fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
   // [drawImage drawInRect:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

-(void)mouseDown:(NSEvent *)theEvent{
    
}


-(void)mouseUp:(NSEvent *)theEvent{
    
}

-(void)mouseEntered:(NSEvent *)theEvent{
    
}

-(void)mouseExited:(NSEvent *)theEvent{
    
}
@end
