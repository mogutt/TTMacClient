//
//  DDLeftBarViewController.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-29.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDLeftBarViewController.h"
#import "DDLeftBarItem.h"
#import <QuartzCore/QuartzCore.h>
#import "UserEntity.h"
#import "StateMaintenanceManager.h"
#import "DDClientState.h"
#import "DDLoginManager.h"
#import "DDPreferenceWinController.h"
#import "DDMessageReviewWindowController.h"
#import "DDUserlistModule.h"
#import "DDLeftBarView.h"
static CGFloat const itemUpGap = 200;
@interface DDLeftBarViewController ()

- (void)p_initialItems;
- (void)p_layoutItems;
- (void)p_initialItemSelectedBackgroundImageView;
- (void)p_selectedItemBackgroundMoveToIndex:(NSInteger)index;
- (void)p_updateMyOnlieState:(uint32)state;
- (void)p_userOffline;
- (void)p_userLoginSuccess;
- (void)n_receiveMessageNotification:(NSNotification*)notification;
@end

@implementation DDLeftBarViewController
{
    NSMutableArray* _items;
    NSImageView* _selectedImageBackground;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        [[DDClientState shareInstance] addObserver:self forKeyPath:DD_USER_STATE_KEYPATH options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        
    }
    return self;
}

- (void)awakeFromNib{
    
    _items = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_receiveMessageNotification:) name:notificationReceiveMessage object:nil];
    
    [self p_initialItemSelectedBackgroundImageView];
    [self p_initialItems];
    
    [_avatarImageView setWantsLayer:YES];
    [_avatarImageView.layer setCornerRadius:_avatarImageView.bounds.size.width / 2.0];
    [self p_userLoginSuccess];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[DDClientState shareInstance] removeObserver:self forKeyPath:DD_USER_STATE_KEYPATH];
}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:DD_USER_STATE_KEYPATH])
    {
        DDUserState oldState = [change[NSKeyValueChangeOldKey] intValue];
        switch ([DDClientState shareInstance].userState)
        {
            case DDUserOnline:
                if(oldState != DDUserOnline)
                {
                    [self p_userLoginSuccess];
                }
                break;
            default:
                if (oldState == DDUserOnline)
                {
                    [self p_userOffline];
                }
                break;
        }
    }
}

#pragma mark public
- (void)selectTheItemAtIndex:(NSInteger)index
{
    [self p_selectedItemBackgroundMoveToIndex:index];
    [self selectedItem:_items[index]];
}

- (void)setMessageCount:(NSInteger)count atIndex:(NSInteger)index
{
    if ([_items count] > index)
    {
        DDLeftBarItem* item = _items[index];
        [item hasUnreadMessage:count];
    }
}

- (IBAction)showOnlineChangedMenu:(id)sender
{
    NSRect rect =  [sender frame];
    NSPoint pt = NSMakePoint(rect.origin.x, rect.origin.y);
    pt = [[sender superview] convertPoint:pt toView:nil];
    pt.y-=4;
    pt.x -= 34;
    NSInteger winNum = [[sender window] windowNumber];
    
    
    NSEvent *event= [NSEvent mouseEventWithType:NSLeftMouseDown location:pt modifierFlags:NSLeftMouseDownMask timestamp:0 windowNumber:winNum context:[[sender window] graphicsContext] eventNumber:0 clickCount:1 pressure:1];
    [NSMenu popUpContextMenu:onlineStateMenu withEvent:event forView:sender];
}

- (IBAction)showSettingMenu:(id)sender
{
    NSRect rect =  [sender frame];
    NSPoint pt = NSMakePoint(rect.origin.x, rect.origin.y);
    pt = [[sender superview] convertPoint:pt toView:nil];
    pt.y-=4;
    pt.x -= 34;
    NSInteger winNum = [[sender window] windowNumber];
    
    
    NSEvent *event= [NSEvent mouseEventWithType:NSLeftMouseDown location:pt modifierFlags:NSLeftMouseDownMask timestamp:0 windowNumber:winNum context:[[sender window] graphicsContext] eventNumber:0 clickCount:1 pressure:1];
    [NSMenu popUpContextMenu:settingMenu withEvent:event forView:sender];
}

- (IBAction)showPerferenceSetting:(id)sender
{
    [[DDPreferenceWinController instance] showWindow:self];
}

- (IBAction)showMessageManagerView:(id)sender
{
    [[DDMessageReviewWindowController instance] showWindow:self];
}

- (IBAction)showFileManagerView:(id)sender
{

}

-(IBAction)changeOnlineState:(NSMenuItem *)sender{
    NSInteger tag = sender.tag;
    UserState state = [[StateMaintenanceManager instance] getMyOnlineState];
    if (state == tag)
        return;
    
    StateMaintenanceManager* stateMaintenanceManager = [StateMaintenanceManager instance];
    if (tag==USER_STATUS_ONLINE)
    {
        if(USER_STATUS_OFFLINE == [stateMaintenanceManager getMyOnlineState])
        {
            [DDClientState shareInstance].userState = DDUserOffLine;
        }
        else if(USER_STATUS_LEAVE == [stateMaintenanceManager getMyOnlineState])
        {

        }
    }
    else if(tag==USER_STATUS_LEAVE)
    {
        if(USER_STATUS_OFFLINE == [stateMaintenanceManager getMyOnlineState])
        {
            DDClientState* clientState = [DDClientState shareInstance];
            clientState.userState = USER_STATUS_ONLINE;
        }
        else if(USER_STATUS_ONLINE == [stateMaintenanceManager getMyOnlineState])
        {
#warning 从在线状态到离线状态
        }
    }
    else if(tag==USER_STATUS_OFFLINE)
    {
        //断开连接.
        [DDClientState shareInstance].userState = DDUserOffLineInitiative;
    }
}

#pragma mark IBAction
- (IBAction)showPreferenceWindow:(id)sender
{
    [[DDPreferenceWinController instance] showWindow:self];
}

#pragma mark DDLeftItem Delegate
- (void)selectedItem:(DDLeftBarItem *)item
{
    NSInteger tag = item.tag;
    [self p_selectedItemBackgroundMoveToIndex:tag];
    [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DDLeftBarItem* item = (DDLeftBarItem*)obj;
        if (item.tag != tag)
        {
            [item setSelected:NO];
        }
        else
        {
            [item setSelected:YES];
            [(DDLeftBarView*)self.view setSelectIndex:idx];
        }
    }];
    [self.delegate selectedItemIndex:tag];
}

#pragma mark privateAPI
- (void)p_initialItems
{
    CGSize size = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.width);
    NSImage* recentChatImageSelected = [NSImage imageNamed:@"recent_contacts_selected"];
    NSImage* recentChatImageUnselected = [NSImage imageNamed:@"recent_contacts_unselected"];
    DDLeftBarItem* recentChat = [[DDLeftBarItem alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)
                                                       selectedImage:recentChatImageSelected
                                                     unSelectedImage:recentChatImageUnselected tag:0];
    recentChat.delegate = self;
    [_items addObject:recentChat];
    [recentChat setAutoresizingMask:NSViewMinYMargin];
    
    NSImage* groupImageSelected = [NSImage imageNamed:@"group_selected"];
    NSImage* groupImageUnselected = [NSImage imageNamed:@"group_unselected"];
    DDLeftBarItem* group = [[DDLeftBarItem alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)
                                                  selectedImage:groupImageSelected
                                                unSelectedImage:groupImageUnselected
                                                            tag:1];
    group.delegate = self;
    [_items addObject:group];
    [group setAutoresizingMask:NSViewMinYMargin];
    
    NSImage* intranentImageSelected = [NSImage imageNamed:@"organization_selected"];
    NSImage* intranentImageUnselected = [NSImage imageNamed:@"organization_unselected"];
    DDLeftBarItem* intranent = [[DDLeftBarItem alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height) selectedImage:intranentImageSelected unSelectedImage:intranentImageUnselected tag:2];
    intranent.delegate = self;
    [_items addObject:intranent];
    [intranent setAutoresizingMask:NSViewMinYMargin];
    
    [self p_layoutItems];
}

- (void)p_layoutItems
{
    CGFloat itemStartY = self.view.bounds.size.height - itemUpGap;
    for (NSInteger index = 0; index < [_items count]; index ++)
    {
        DDLeftBarItem* item = _items[index];
        CGSize size = item.bounds.size;
        CGFloat y = itemStartY - index * size.height;
        [item setFrame:NSMakeRect(0, y, size.width, size.height)];
        [self.view addSubview:item];
    }
}

- (void)p_initialItemSelectedBackgroundImageView
{
    _selectedImageBackground = [[NSImageView alloc] init];
//    NSImage* image = [NSImage imageNamed:@"left-bar-selected-background"];
    CGSize size = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.width);
    CGFloat itemStartY = self.view.bounds.size.height - itemUpGap;
    [_selectedImageBackground setFrame:NSMakeRect(0, itemStartY, size.width, size.height)];
//    [_selectedImageBackground setImage:image];
    [_selectedImageBackground setAutoresizingMask:NSViewMinYMargin];
    
    [self.view addSubview:_selectedImageBackground positioned:NSWindowBelow relativeTo:nil];
    
}

- (void)p_selectedItemBackgroundMoveToIndex:(NSInteger)index
{
    CGFloat itemStartY = self.view.bounds.size.height - itemUpGap;

    NSViewAnimation *theAnim;
    NSRect firstViewFrame;
    NSRect newViewFrame;
    NSMutableDictionary* firstViewDict;
    

        // Create the attributes dictionary for the first view.
        firstViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        firstViewFrame = [_selectedImageBackground frame];
        
        // Specify which view to modify.
        [firstViewDict setObject:_selectedImageBackground forKey:NSViewAnimationTargetKey];
        
        // Specify the starting position of the view.
        [firstViewDict setObject:[NSValue valueWithRect:firstViewFrame]
                          forKey:NSViewAnimationStartFrameKey];
        
        // Change the ending position of the view.
        newViewFrame = firstViewFrame;
        CGFloat y = itemStartY - index * _selectedImageBackground.bounds.size.height;

        newViewFrame.origin.x = 0;
        newViewFrame.origin.y = y;
        [firstViewDict setObject:[NSValue valueWithRect:newViewFrame]
                          forKey:NSViewAnimationEndFrameKey];
    
    // Create the view animation object.
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray
                                                               arrayWithObjects:firstViewDict, nil]];
    
    // Set some additional attributes for the animation.
    [theAnim setDuration:0];    // One and a half seconds.
    [theAnim setAnimationCurve:NSAnimationEaseIn];
    
    // Run the animation.
    [theAnim startAnimation];
    
    // The animation has finished, so go ahead and release it.
}

- (void)p_userOffline
{
    [self p_updateMyOnlieState:USER_STATUS_OFFLINE];
    
    [[StateMaintenanceManager instance] changeMyOnlineState:USER_STATUS_OFFLINE];
}

-(void)p_updateMyOnlieState:(uint32)state
{
    if(USER_STATUS_ONLINE == state)
    {
        NSImage* icon = [NSImage imageNamed:@"state-online"];
        [self.stateButton setImage:icon];
    }
    else if(USER_STATUS_LEAVE == state)
    {
        NSImage* icon = [NSImage imageNamed:@"state-leave"];
        [self.stateButton setImage:icon];
    }
    else
    {
        NSImage* icon = [NSImage imageNamed:@"state-offline"];
        [self.stateButton setImage:icon];
    }
}


- (void)p_userLoginSuccess
{
    [self p_updateMyOnlieState:USER_STATUS_ONLINE];
    [[StateMaintenanceManager instance] changeMyOnlineState:USER_STATUS_ONLINE];
    NSString* currentUserID = [DDClientState shareInstance].userID;
    UserEntity* user = [[DDUserlistModule shareInstance] getUserById:currentUserID];
    NSString* avatar =user.avatar;//for test
    NSURL* avatarURL = [NSURL URLWithString:avatar];
    [_avatarImageView loadImageWithURL:avatarURL setplaceholderImage:@"group_unselected"];
    
}

- (void)n_receiveMessageNotification:(NSNotification*)notification
{
    DDLeftBarItem* firstItem = _items[0];
    [firstItem hasUnreadMessage:YES];
}

@end
