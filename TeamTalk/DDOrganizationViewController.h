//
//  DDOrganizationViewController.h
//  Duoduo
//
//  Created by 独嘉 on 14-8-18.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DDOriginzationModule;
@interface DDOrganizationViewController : NSViewController<NSOutlineViewDataSource,NSOutlineViewDelegate>
@property(nonatomic,weak)IBOutlet NSOutlineView* outlineView;
@property(nonatomic,retain)DDOriginzationModule* module;
@end
