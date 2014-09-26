//
//  DDAppDelegate.h
//  Duoduo
//
//  Created by maye on 13-10-30.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DDAccountControllerProtocol;
@class DDLoginWindowController;
@interface DDAppDelegate : NSObject <NSApplicationDelegate,DDDuoduoProtocol>
{
    IBOutlet DDInterfaceController *interfaceController;
}

@property(nonatomic,strong)DDLoginWindowController* loginWindowController;

- (void)showMainWindowController;

@end




