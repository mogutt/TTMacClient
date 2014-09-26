/************************************************************
 * @file         DDMainModule.h
 * @author       快刀<kuaidao@mogujie.com>
 * summery       主窗口业务模块
 ************************************************************/

#import <Foundation/Foundation.h>
#import "DDRootModule.h"
@class DDMainWindowController;
@interface DDMainModule : DDRootModule

@property(nonatomic,strong)DDMainWindowController*  mainWindowController;

-(id) initModule;
-(void) showMainWindow;

@end

extern DDMainModule* getDDMainModule();