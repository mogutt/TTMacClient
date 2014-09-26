//
//  DDMainWindowController.h
//  Duoduo
//
//  Created by zuoye on 13-11-28.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "DDWindowController.h"
#import "EGOImageView.h"
#import "FMSearchTokenField.h"
#import "DDSearchFieldEditorDelegate.h"
#import "DDLeftBarViewController.h"
#import "DDRecentContactsViewController.h"
#import "DDGroupViewController.h"
//#import "DDIntranetViewController.h"
//#import "DDIntranetContentViewController.h"
@class DDLeftBarViewController;
@class DDSplitView;
@class DDChattingViewController,DDMainWindowControllerModule;

@interface DDMainWindowController : DDWindowController<
                                                    NSUserNotificationCenterDelegate,
                                                    NSSplitViewDelegate,
                                                    DDLeftBarViewControllerDelegate,
                                                    DDRecentContactsViewControllerDelegate,
                                                    DDGroupViewControllerDelegate>{
    @private
    __weak DDChattingViewController *currentChattingViewController;
                                                
    NSStatusItem* _statusItem;                       //状态栏图标
    NSMenu *onlineStateMenu; 
    NSInteger preOnlineMenuTag;
}

@property (nonatomic,weak) IBOutlet DDLeftBarViewController* leftBarViewController;
@property (nonatomic,strong)DDMainWindowControllerModule* module;

@property (nonatomic,weak) IBOutlet NSView *firstColumnView;
@property (nonatomic,weak) IBOutlet DDSplitView *mainSplitView;
@property (nonatomic,weak) IBOutlet NSView *chattingBackgroudView;


@property (nonatomic,weak) IBOutlet FMSearchTokenField *searchField;
@property (nonatomic,strong) IBOutlet DDSearchFieldEditorDelegate *searchFieldDelegate;
+ (instancetype)instance;

- (IBAction)showMyInfo:(id)sender;

-(void)openChat:(NSString *)sId icon:(NSImage *)icon;
-(void)openChatViewByUserId:(NSString *)userId;

-(void)notifyUserNewMsg:(NSString*)uid title:(NSString*)title content:(NSString*)content;

-(void)renderTotalUnreadedCount:(NSUInteger)count;

//
-(void)updateCurrentChattingViewController;

- (void)recentContactsSelectObject:(NSString*)sessionID;

- (void)shakeTheWindow;

- (void)leftChangeUseravatar:(NSImage*)image;
@end
