/************************************************************
 * @file         DDMainModule.m
 * @author       快刀<kuaidao@mogujie.com>
 * summery       主窗口业务模块
 ************************************************************/

#import "DDMainModule.h"
#import "DDMainWindowController.h"

@interface DDMainModule()


@end

@implementation DDMainModule

-(void) showMainWindow
{
    if(!_mainWindowController)
    {
        _mainWindowController = [[DDMainWindowController alloc] init];
    }
    [_mainWindowController showWindowInFrontIfAllowed:YES];
}


@end
