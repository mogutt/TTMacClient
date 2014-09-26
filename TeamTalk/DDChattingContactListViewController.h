//
//  DDChattingContactListViewController.h
//  Duoduo
//
//  Created by zuoye on 14-1-9.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DDTableView.h"
#import "DDUserDataWindowController.h"
#import "DDAlertWindowController.h"

@class SessionEntity,DDChattingContactListModule;
@interface DDChattingContactListViewController : NSObject<NSTableViewDataSource,NSTableViewDelegate,NSMenuDelegate>{
}

@property (nonatomic,weak) IBOutlet NSTableColumn *contactListColumn;
@property (nonatomic,weak) IBOutlet DDTableView *contactListTableView;
@property (nonatomic,weak) IBOutlet NSTextField *listViewTitleTextField;
@property (nonatomic,weak) IBOutlet NSMenu *contactListMenu;
@property (nonatomic,weak) IBOutlet NSSearchField* searchField;
@property (nonatomic,retain) DDChattingContactListModule* module;
@property (assign) BOOL needForceUpdate;
@property(nonatomic,strong)SessionEntity* sessionEntity;

-(void)updateTitle;

- (IBAction)viewUserInfo:(id)sender;

- (void)reloadContactListTableView;
@end
