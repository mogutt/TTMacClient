/************************************************************
 * @file         DDScreenCaptureModule.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       截屏模块  注：移植之大子腾的截屏功能
 ************************************************************/

#import "DDScreenCaptureModule.h"
#import "CaptureWindow.h"


@interface DDScreenCaptureModule()

-(void) onLoadModule;
-(void) onUnloadModule;

@end

@implementation DDScreenCaptureModule

-(id) init
{
    if(self = [super init])
    {
        
    }
    return self;
}


- (IBAction)capture:(id)sender
{
    NSRect rect = NSMakeRect(100, 100, 600, 600);
    myWindow = [[CaptureWindow alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [myWindow makeKeyAndOrderFront:nil];
}

@end
