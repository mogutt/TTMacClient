//
//  RTXImageSpreadView.m
//  Duoduo
//
//  Created by zuoye on 13-12-23.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "RTXImageSpreadView.h"

@implementation RTXImageSpreadView

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
    [self lockFocus];
    if (self.image !=nil) {

    }
    [self unlockFocus];
    
    /*
    rbx = rdi;
    xmm1 = var_288;
    xmm0 = var_272;
    var_256 = rbx;
    var_264 = *0x1002c3900;
    [[&var_256 super] drawRect:edx];
    [rbx lockFocus];
    if (rbx.image != 0x0) {
        [rdi size];
        var_112 = xmm0;
        var_104 = xmm1;
        var_224 = [rbx bounds];
        var_120 = var_240;
        rdi = &var_192;
        *rdi = [rbx bounds];
        asm{ divsd      xmm0, qword [ss:rbp-0x160+var_104] };
        ceil(rdi);
        var_96 = var_216;
        asm{ divsd      xmm0, qword [ss:rbp-0x160+var_112] };
        ceil(rdi);
        rax = Floor(var_120);
        var_72 = rax;
        if (rax > 0x0) {
            var_88 = Floor(var_96);
            var_80 = 0x0;
            rdx = *_OBJC_IVAR_$_RTXImageSpreadView.image;
            rsi = objc_msg_isFlipped;
            do {
                xmm1 = var_104;
                r13 = rsi;
                if (rcx > 0x0) {
                    var_96 = var_80 * var_112;
                    r14 = 0x0;
                    do {
                        r15 = *NSZeroRect;
                        var_120 = *(rbx + rdx);
                        var_160 = var_96;
                        var_168 = r14 * xmm1;
                        var_176 = var_112;
                        var_184 = xmm1;
                        var_152 = *(r15 + 0x18);
                        var_144 = *(r15 + 0x10);
                        var_136 = *(r15 + 0x8);
                        var_128 = *r15;
                        rax = (*objc_msg_isFlipped)(rbx, r13);
                        (*objc_msgSend)(var_120, @selector(drawInRect:fromRect:operation:fraction:respectFlipped:hints:), 0x2, SIGN_EXTEND(rax), 0x0, r9);
                        xmm1 = var_104;
                        rdx = rdx;
                    } while (var_88 != r14 + 0x1);
                }
                rax = var_80 + 0x1;
                var_80 = rax;
                rsi = r13;
            } while (rax != var_72);
        }
    }
    rax = [rbx unlockFocus];
    return rax;
     */
    
}

-(void)draw:(NSImage *)im imageSize:(NSRect)rect{
    /*
    var_96 = rdx * xmm0;
    var_104 = 0x0;
    var_112 = xmm0;
    var_120 = xmm1;
    rax = *NSZeroRect;
    var_88 = *(rax + 0x18);
    var_80 = *(rax + 0x10);
    var_72 = *(rax + 0x8);
    var_64 = *rax;
    rax = (*objc_msg_isFlipped)();
    rax = (*objc_msgSend)(rdi.image, @selector(drawInRect:fromRect:operation:fraction:respectFlipped:hints:), 0x2, SIGN_EXTEND(rax), 0x0, r9);
    return rax;
     */
}
@end
