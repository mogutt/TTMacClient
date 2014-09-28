//
//  DDChattingHeadViewController.m
//  Duoduo
//
//  Created by zuoye on 14-1-10.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDChattingHeadViewController.h"
#import "DDUserlistModule.h"
#import "DDHttpModule.h"
#import "DDAddChatGroupModel.h"
#import "MD5.h"
#import "SessionEntity.h"
#import "GroupEntity.h"
#import <QuartzCore/QuartzCore.h>
#import "DDGroupModule.h"
#import "AvatorImageView.h"
#import "NSView+LayerAddition.h"
#import "DDSendP2PCmdAPI.h"
@interface DDChattingHeadViewController(PrivateAPI)

- (void)p_receiveInputtingMessage:(NSNotification*)notification;
- (void)p_receiveStopInputtingMessage:(NSNotification*)notifictaion;

@end

@implementation DDChattingHeadViewController
{
    NSUInteger _receiveTimes;
}
- (id)init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

-(void)awakeFromNib{
    [self.view.layer setBackgroundColor:[NSColor colorWithCalibratedRed:251.0/255.0 green:251.0/255.0 blue:251.0/255.0 alpha:1].CGColor];
    _receiveTimes = 0;
    [self.line setBackgroundColor:[NSColor colorWithCalibratedRed:205.0/255.0 green:205.0/255.0 blue:205.0/255.0 alpha:1]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_receiveInputtingMessage:) name:notificationReceiveP2PInputingMessage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_receiveStopInputtingMessage:) name:notificationReceiveP2PStopInputingMessage object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationReceiveP2PInputingMessage object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationReceiveP2PStopInputingMessage object:nil];
}

- (IBAction)addParticipantToSession:(id)sender {
    //TODO ,先判断有没有权限加人到会话里
    addGroupWndController = nil;
    if(addGroupWndController==nil){
        addGroupWndController =[[DDAddChatGroupWindowController alloc] initWithWindowNibName:@"DDAddChatGroupWindowController"];
    }
    
    DDAddChatGroupModel* model = [[DDAddChatGroupModel alloc] init];
    
    [addGroupWndController setAddType:addType];
    [addGroupWndController setSessionId:sid];
    
    if (addType == 0)
    {
        //新建群
        UserEntity* mine = [[DDUserlistModule shareInstance] myUser];
        
        model.initialGroupUsersIDs = [[NSMutableArray alloc] initWithObjects:_userEntity.userId,mine.userId, nil];
        addGroupWndController.model = model;
    }
    else
    {
        //添加联系人
        DDGroupModule* groupModule = [DDGroupModule shareInstance];
        GroupEntity *groupEntity =  [groupModule getGroupByGId:[NSString stringWithFormat:@"group_%@",sid]];
        model.initialGroupUsersIDs = groupEntity.groupUserIds;
        addGroupWndController.model = model;
    }
    
    
    [NSApp beginSheet:[addGroupWndController window] modalForWindow:[self.view window] modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)sendFile:(id)sender {
    __block NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSLog(@" >>>> %lu+ %@",result,[[panel URL] path]);
        }
        panel=nil;
    }];
    
    
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
        //[[self window] orderOut:NO];
   // r14 = rdx;
    BOOL isPressOk =[addGroupWndController hasPressOK];
    if (isPressOk) {
      //  r15 = *objc_msgSend;
      //  rax = [rbx.addGroupWndController inviteDeptContactList];
      //  [rbx notifySelectedParticipants:rax];
//        [self sendRequestWithParam:@"" action:@""];
    }
 //   [addGroupWndController clearSelectedUserList];
    [sheet orderOut:self];
}

-(void)setAddParticipantType:(int)type{
    addType = type;
}
-(void)setAddGroupId:(NSString *)sessionId{
    sid=sessionId;
}

#pragma mark PrivateAPI
- (void)p_receiveInputtingMessage:(NSNotification*)notification
{
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    NSDictionary* info = [notification object];
    NSString* fromUserID = info[@"fromUserID"];
    NSString* toUserID = info[@"toUserId"];
    NSDictionary* content = info[@"content"];
    NSString* myUserID = userModule.myUserId;
    if ([toUserID isEqualToString:myUserID] && [self.sessionID isEqualToString:fromUserID] && [content[@"Content"] isEqualToString:INPUTING])
    {
        //显示正在输入
        _receiveTimes ++;
        if(![_nametextField.stringValue hasSuffix:@"正在输入。。。"])
        {
            NSString* newStringValue = [NSString stringWithFormat:@"%@  正在输入。。。",self.sessionName];
            [_nametextField setStringValue:newStringValue];
        }
        double delayInSeconds = 4.0;
        NSUInteger nowReceiveTime = _receiveTimes;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (nowReceiveTime == _receiveTimes)
            {
                if([_nametextField.stringValue hasSuffix:@"正在输入。。。"])
                {
                    [_nametextField setStringValue:self.sessionName];
                }
            }
        });
    }
}

- (void)p_receiveStopInputtingMessage:(NSNotification*)notifictaion
{
    DDUserlistModule* userModule = [DDUserlistModule shareInstance];
    NSDictionary* info = [notifictaion object];
    NSString* fromUserID = info[@"fromUserID"];
    NSString* toUserID = info[@"toUserId"];
    NSDictionary* content = info[@"content"];
    NSString* myUserID = userModule.myUserId;
    if ([toUserID isEqualToString:myUserID] && [self.sessionID isEqualToString:fromUserID] && [content[@"Content"] isEqualToString:STOP_INPUTING])
    {
        //显示取消输入
        [_nametextField setStringValue:self.sessionName];
    }
}



@end
