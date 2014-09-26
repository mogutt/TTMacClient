/************************************************************
 * @file         DDScreenCaptureModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       截屏模块  注：移植之大子腾的截屏功能
 ************************************************************/

#import <Foundation/Foundation.h>
#import "DDRootModule.h"
//module key names
static NSString* const MKN_DDSCREENCAPTUREMODULE_OK = @"DDLOGINMODULE_OK";        //截屏点击确定
@interface DDScreenCaptureModule : DDRootModule
{
    IBOutlet id myWindow;
}

-(id) initModule;

- (IBAction)capture:(id)sender;

@end

