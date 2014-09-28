//
//  DDChattingViewController.m
//  Duoduo
//
//  Created by zuoye on 13-12-2.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import "DDChattingViewController.h"
#import "EGOImageView.h"
#import "DDUserListModule.h"
#import "UserEntity.h"
#import "DDMessageModule.h"
#import "DDSessionModule.h"
#import "DDScreenCaptureModule.h"
#import "EGOCache.h"
#import "AIImageAdditions.h"
#import "NSImage+Stretchable.h"
#import "EmotionViewController.h"
#import "DDEmotionAttachment.h"
#import "DDUserPreferences.h"
#import "NSString+DDStringAdditions.h"
#import "DDGroupInfoManager.h"
#import "DDUserInfoManager.h"
#import "DDGroupModule.h"
#import "DDChattingViewModule.h"
#import "MessageViewFactory.h"
#import "DDDatabaseUtil.h"
#import "DDSessionModule.h"
#import "DDMessageSendManager.h"
#import "GroupEntity.h"
#import "NSImage+Stretchable.h"
#import "AvatorImageView.h"
#import "StateMaintenanceManager.h"
#import "NSView+LayerAddition.h"
#import "DDSendP2PCmdAPI.h"
#import "DDServiceAccountModule.h"
#import "DDSessionModule.h"
#define IMAGE_MARK_START @"&$#@~^@[{:"
#define IMAGE_MARK_END @":}]&$~@#@"

static EmotionViewController *emotionViewController = nil;

@interface DDChattingViewController(privateAPI)

- (BOOL)sendMessageShouldShowTime;
- (BOOL)msgShouldShowTime:(MessageEntity*)message;
- (BOOL)shouldShowName:(MessageEntity*)message;
- (void)receiveTheGroupMemberNotification:(NSNotification*)notification;
- (void)receiveMsgSendAckNotification:(NSNotification*)notification;
- (void)receiveStateChangedNotification:(NSNotification*)notification;

@end

@implementation DDChattingViewController
{
    uint32_t totalMsgCnt;
    NSUInteger lastMessageDate;
    NSString* lastMessageSenderID;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _configureTextEntryView];
        lastMessageDate = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTheGroupMemberNotification:) name:MKN_DDSESSIONMODULE_GROUPMEMBER object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveStateChangedNotification:) name:notificationonlineStateChange object:nil];
    }
    return self;
}

- (void)setModule:(DDChattingViewModule *)module
{
    if (_module)
    {
        _module = nil;
    }
    _module = module;
    if (self.chattingContactListViewController)
    {
        self.chattingContactListViewController.sessionEntity = module.session;
    }
}

- (void)awakeFromNib{
    [self.view.layer setBackgroundColor:[NSColor colorWithCalibratedRed:207.0/255.0 green:207.0/255.0 blue:207.0/255.0 alpha:1.0].CGColor];
    if(SESSIONTYPE_GROUP == [self.module.session type])
    {
        [[self bottomRightView] setHidden:NO];
        self.chattingContactListViewController.sessionEntity = self.module.session;
        [self.chattingContactListViewController updateTitle];
        
        [[self.chattingHeadViewController addParticipantButton] setEnabled:NO ];
        [[self.chattingHeadViewController sendFilesButton] setHidden:YES];
    }
//    if (SESSIONTYPE_TEMP_GROUP == [self.module.session type])
//    {
//        [[self bottomRightView] setHidden:NO];
//        self.chattingContactListViewController.sessionEntity = self.module.session;
//        [self.chattingContactListViewController updateTitle];
//        
//        [[self.chattingHeadViewController addParticipantButton] setEnabled:YES ];
//        [self.chattingHeadViewController setAddParticipantType:1];
//        [self.chattingHeadViewController setAddGroupId:[self.module.session orginId]];
//        [[self.chattingHeadViewController sendFilesButton] setHidden:YES];
//    }
    else if(SESSIONTYPE_SINGLE == [self.module.session type])
    {
        [[self bottomRightView] setHidden:YES];
        [_chatSplitView setFrame:_bottomMainView.frame];
        
        DDUserlistModule* moduleUserlist = [DDUserlistModule shareInstance];
        UserEntity* user = [moduleUserlist getUserById:self.module.session.sessionId];
        _chattingHeadViewController.userEntity = user;
        [self.chattingHeadViewController setAddParticipantType:0];
         if((user.userRole & 0x20000000) != 0){
             [[self.chattingHeadViewController addParticipantButton] setEnabled:NO ];
               [[self.chattingHeadViewController sendFilesButton] setHidden:YES];
         }else
        if((user.userRole & 0xC0000000) != 0){
            [[self.chattingHeadViewController addParticipantButton] setEnabled:YES ];
              [[self.chattingHeadViewController sendFilesButton] setHidden:NO];
        }else{
            [[self.chattingHeadViewController addParticipantButton] setEnabled:NO ];
              [[self.chattingHeadViewController sendFilesButton] setHidden:NO];
        }
    }
    
    _drawView.delegate = self;
    [self.chattingHeadViewController.nametextField setStringValue:self.module.session.name?self.module.session.name:@""];
    [self.chattingHeadViewController setSessionName:self.module.session.name?self.module.session.name:@""];
    [self.chattingHeadViewController setSessionID:self.module.session.sessionId];
    switch (self.module.session.type)
    {
        case SESSIONTYPE_SINGLE:
        {
            [self.chattingHeadViewController.iconImage setType:UserAvator];
            [self.chattingHeadViewController.iconImage setSession:self.module.session];
        }
            break;
        case SESSIONTYPE_GROUP:
        {
            [self.chattingHeadViewController.iconImage setType:GroupAvator];
            [self.chattingHeadViewController.iconImage setSession:self.module.session];
        }
            break;
    }
    
    if (self.module.session.type != SESSIONTYPE_SINGLE)
    {
        [self.shakeButton setHidden:YES];
        [_chatContentScrollView setType:Group];
    }
    else
    {
        [_chatContentScrollView setType:User];
    }
    
    //啃爹的，草，害我找了这么久，原来是这里的问题
    
//    [_inputView setTarget:self action:@selector(sendMsgToServer:)];
    [_inputView setSessionEntity:self.module.session];
    
    
    [self.chatContentScrollView setLoadDelegate:self];
    
 
    
    //加载历史消息
    DDMessageModule* messageModule = [DDMessageModule shareInstance];
    if (totalMsgCnt == 0 && [messageModule countMessageBySessionId:self.module.session.sessionId] == 0)
    {
        [self touchToRefresh];
    }
    if (self.module.session.type == SESSIONTYPE_SINGLE)
    {
        [self.chattingHeadViewController.state setHidden:NO];
        [self receiveStateChangedNotification:nil];
    }
    else
    {
        [self.chattingHeadViewController.state setHidden:YES];
        [self.chattingHeadViewController.nametextField setFrameOrigin:NSMakePoint(65, self.chattingHeadViewController.nametextField.frame.origin.y)];
    }
    
    if (![[DDServiceAccountModule shareInstance] isServiceAccount:self.module.session.sessionId])
    {
        [self.almanceButton setHidden:YES];
        [self.bangButton setHidden:YES];
    }
    
    [[self.shakeButton cell] setHighlightsBy:NSContentsCellMask];
    [[self.screenButton cell] setHighlightsBy:NSContentsCellMask];
    [[self.emotionButton cell] setHighlightsBy:NSContentsCellMask];
    [[self.almanceButton cell] setHighlightsBy:NSContentsCellMask];
    [[self.bangButton cell] setHighlightsBy:NSContentsCellMask];
}

- (void)dealloc
{
    DDLog(@"dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MKN_DDSESSIONMODULE_GROUPMEMBER object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationonlineStateChange object:nil];
}


-(void)makeInputViewFirstResponder{
     [self.view.window makeFirstResponder:_inputView];
}

- (void)_configureTextEntryView{
    egoImageViews =[[NSMutableDictionary alloc] init];
}

-(BOOL)showChatContent:(MessageEntity *)msg{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fId = msg.sessionId;
        DDUserlistModule* moduleFriend = [DDUserlistModule shareInstance];
        UserEntity *u = [moduleFriend getUserById:fId];
        if (u)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                  [self addMessageToChatContentView:msg isHistoryMsg:NO showtime:kIgnore showName:kIgnoreThis];
            });
        }else
        {      //如果本地没有这个用户,那需要往服务端请求一下.加消息监听
            
        }
    });
  
    return YES;
}


-(void)addMessageToChatContentView:(MessageEntity*)msg isHistoryMsg:(BOOL)isHistoryMsg showtime:(ShowTime)showtime showName:(ShowName)showname

{
//    if (isHistoryMsg)
//    {
//        [_chatContentScrollView stopLoading];
//    }
     [_chatContentScrollView needShowNewMsgBtn:NO];
    NSAttributedString* showContent = [self.module getAttributedStringFromShowMessage:msg];

    NSTextView* messageTextView = [[MessageViewFactory instance] produceTextViewWithMessage:showContent];
    DDUserlistModule* userList = [DDUserlistModule shareInstance];
    BOOL left = ![msg.senderId isEqualToString:userList.myUserId];

    NSString* dateString = @"";
    BOOL shouldShowTime;
    switch (showtime)
    {
        case kShowTime:
            shouldShowTime = YES;
            break;
        case kNotShowTime:
            shouldShowTime = NO;
            break;
        case kIgnore:
            shouldShowTime = [self msgShouldShowTime:msg];
            break;
    }
    if (shouldShowTime)
    {
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM-dd HH:mm"];
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:msg.msgTime];
        dateString = [dateFormatter stringFromDate:date];
    }
    if (!isHistoryMsg)
    {
        if (![_chatContentScrollView isScrollBottom]) {

            //有新消息进来并且当前不再聊天窗口底部添加气泡提示
            [_chatContentScrollView needShowNewMsgBtn:YES];
        }else
        {
            [_chatContentScrollView needShowNewMsgBtn:NO];
        }
        if (msg.msgType == MESSAGE_TYPE_SINGLE)
        {
            //不是历史消息，且是自己发的
            [_chatContentScrollView addMessageViewOnTail:messageTextView atLeft:left name:@"" time:dateString forceScroll:!left userID:nil];
        }
        else
        {
            if (!left)
            {
                //自己
                [_chatContentScrollView addMessageViewOnTail:messageTextView atLeft:left name:@"" time:dateString forceScroll:!left userID:nil];
            }
            else
            {
                NSString* name;
                switch (showname) {
                    case kShowName:
                        name = [(UserEntity*)[userList getUserById:msg.senderId] name];
                        if (!name)
                        {
                            name = [NSString stringWithFormat:@"!@#Unknow#@!%@",msg.senderId];
                        }
                        break;
                    case kNotShowName:
                        name = @"";
                        break;
                    case kIgnoreThis:
                        if ([self shouldShowName:msg])
                        {
                            name = [(UserEntity*)[userList getUserById:msg.senderId] name];
                            if (!name)
                            {
                                name = [NSString stringWithFormat:@"!@#Unknow#@!%@",msg.senderId];
                            }
                        }
                        else
                        {
                            name = @"";
                        }
                        break;
                }
                [_chatContentScrollView addMessageViewOnTail:messageTextView atLeft:left name:name time:dateString forceScroll:NO userID:msg.senderId];
            }
        }
    }
    else
    {
        

        if (msg.msgType == MESSAGE_TYPE_SINGLE)
        {
            [_chatContentScrollView addMessageViewOnHead:@[messageTextView] atLefts:@[[NSNumber numberWithBool:left]] names:@[@""] times:@[dateString] userIDs:@[msg.senderId]];
        }
        else
        {
            
            NSString* name;
            switch (showname) {
                case kShowName:
                    name = [(UserEntity*)[userList getUserById:msg.senderId] name];
                    if (!name)
                    {
                        name = [NSString stringWithFormat:@"!@#Unknow#@!%@",msg.senderId];
                    }
                    break;
                case kNotShowName:
                    name = @"";
                    break;
                case kIgnoreThis:
                    if ([self shouldShowName:msg])
                    {
                        name = [(UserEntity*)[userList getUserById:msg.senderId] name];
                        if (!name)
                        {
                            name = [NSString stringWithFormat:@"!@#Unknow#@!%@",msg.senderId];
                        }
                    }
                    else
                    {
                        name = @"";
                    }
                    break;
            }
            if (!name)
            {
                name = @"";
            }
            [_chatContentScrollView addMessageViewOnHead:@[messageTextView] atLefts:@[[NSNumber numberWithBool:left]] names:@[name] times:@[dateString] userIDs:@[msg.senderId]];
        }
    }
    totalMsgCnt ++;
}

- (void)emotionSelected:(NSString *)emotionFile
{
    
    [self makeInputViewFirstResponder];
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:emotionFile
                                                        ofType:nil];
    DDLog(@"emotion file: %@ imagePath:%@", emotionFile,imagePath);
    NSImage *image =[NSImage imageNamed:emotionFile];
   // NSImage *image =[[NSImage alloc] initWithContentsOfFile:imagePath];  //strRealPath is the absolute path of image;
    if (!image) {
        return;
    }
    
    NSURL *fileUrl = [NSURL fileURLWithPath:imagePath];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initSymbolicLinkWithDestinationURL:fileUrl];
    [fileWrapper setIcon:image];
    [fileWrapper setPreferredFilename:imagePath];
    DDEmotionAttachment *attachment = [[DDEmotionAttachment alloc] init];
    [attachment setFileWrapper:fileWrapper];
    [attachment setEmotionFileName:emotionFile];
    [attachment setEmotionPath:imagePath];
    [attachment setEmotionText:[emotionViewController getTextFrom:emotionFile]];
    
    NSMutableAttributedString *attachmentString = (NSMutableAttributedString*)[NSMutableAttributedString attributedStringWithAttachment:attachment];
    NSTextStorage* textStorage = [_inputView textStorage];
    [textStorage appendAttributedString:attachmentString];
}


- (void)scrollToMessageEnd
{
    [_chatContentScrollView scrollToDocumentEnd];
}

- (IBAction)emotionClick:(id)sender {
    if (!emotionViewController) {
        emotionViewController = [[EmotionViewController alloc] initWithNibName:@"EmotionPopover" bundle:nil];
    }
    [emotionViewController setChattingViewController:self];
    [emotionViewController showUp:sender];
}

- (IBAction)screenCaptureClick:(NSButton *)sender {

    [[DDScreenCaptureModule shareInstance] capture:sender];
    [self makeInputViewFirstResponder];
}

- (IBAction)clickTheUserIcon:(id)sender
{
    //点击用户头像
    if ([self.module.session.sessionId hasPrefix:@"group"])
    {
        //群成员查看
        DDGroupModule* groupModule = [DDGroupModule shareInstance];
        GroupEntity* groupEntity = [groupModule getGroupByGId:self.module.session.sessionId];
        [[DDGroupInfoManager instance] showGroup:groupEntity context:self];
    }
    else
    {
        //个人信息查看
        DDUserlistModule* userListModel = [DDUserlistModule shareInstance];
        UserEntity* showUser = [userListModel getUserById:self.module.session.sessionId];
        [[DDUserInfoManager instance] showUser:showUser forContext:self];
    }
}

- (IBAction)sendWindowshake:(id)sender
{
    DDSendP2PCmdAPI* p2pAPI = [[DDSendP2PCmdAPI alloc] init];
    DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
    NSString *fromUserId = userListModule.myUserId;
    NSString *toId = self.module.session.orginId;
    NSString* content = [DDSendP2PCmdAPI contentFor:SHAKE_WINDOW_SERVICEID commandID:SHAKE_WINDOW_COMMAND content:SHAKE_WINDOW];
    NSArray* object = @[fromUserId,toId,content,@(1000)];
    log4CInfo(@"message ack from userID：%@",fromUserId);
    [p2pAPI requestWithObject:object Completion:nil];
    [[DDMainWindowController instance] shakeTheWindow];
    
    [sender setEnabled:NO];
    double delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [sender setEnabled:YES];
    });
    
}

- (IBAction)almanceClick:(id)sender
{
    [[DDServiceAccountModule shareInstance] sendAlmanac];
}

- (IBAction)bangClick:(id)sender
{
    [[DDMainWindowController instance] shakeTheWindow];
    [[DDServiceAccountModule shareInstance] sendBang];
    [sender setEnabled:NO];
    double delayInSeconds = 3.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [sender setEnabled:YES];
    });
}

-(void)showMessage
{
    DDMessageModule* moduleMsg = [DDMessageModule shareInstance];
    NSArray* msgArray = [moduleMsg popArrayMessage:self.module.session.sessionId];
    //显示最新的30条
    NSUInteger messageCount = [msgArray count];
    if (messageCount > 30)
    {
        for (NSUInteger index = messageCount - 30; index < messageCount; index ++)
        {
            MessageEntity* msg = msgArray[index];
            [self showChatContent:msg];
        }
    }
    else
    {
        for (MessageEntity* msg in msgArray)
        {
            [self showChatContent:msg];
        }
    }
}

- (void)updateUI
{
    [_chattingContactListViewController updateTitle];
    [_chattingContactListViewController reloadContactListTableView];
}

#pragma mark TextView Delegate
- (void)textView:(NSTextView *)textView
   clickedOnCell:(id<NSTextAttachmentCell>)cell
          inRect:(NSRect)cellFrame
         atIndex:(NSUInteger)charIndex
{
    //    selectImageRect = cellFrame;
    self.inputView.currentIndex = charIndex;
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray *)affectedRanges replacementStrings:(NSArray *)replacementStrings
{
    if (![self.module.session.sessionId hasPrefix:GROUP_PRE])
    {
        DDSendP2PCmdAPI* p2pAPI = [[DDSendP2PCmdAPI alloc] init];
        DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
        NSString *fromUserId = userListModule.myUserId;
        NSString *toId = self.module.session.orginId;
        NSString* content = [DDSendP2PCmdAPI contentFor:INPUTING_SERVICEID commandID:INPUTING_COMMAND content:INPUTING];
        NSArray* object = @[fromUserId,toId,content,@(1000)];
        log4CInfo(@"message ack from userID：%@",fromUserId);
        [p2pAPI requestWithObject:object Completion:nil];
    }
    return YES;
}

//- (void)textViewDidChangeSelection:(NSNotification *)notification
//{
//    DDLog(@"asd");
//}

-(BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector{
    NSEvent *currentEvent = [[self.inputView window] currentEvent];
    unichar character = [[currentEvent charactersIgnoringModifiers] characterAtIndex:0];
    NSUInteger flags = [currentEvent modifierFlags];
    if ((@selector(insertNewline:) !=commandSelector) && @selector(insertLineBreak:) != commandSelector) {
        if ((@selector(insertNewlineIgnoringFieldEditor:) != commandSelector) && (character != 0x3)){
            commandSelector = nil;
            if (character != 0xd){
                return NO;
            }
        }
    }
    if([[DDUserPreferences defaultInstance] msgSendKey]==1){       //commond + enter
        if ((((character == 0x3) || (character == 0xd))) && ((flags & 0x100000) != 0x0)) {
           [self sendMsgToServer:nil];
            return YES;
        }
        [self.inputView insertLineBreak:nil];
        commandSelector=nil;
        return YES;
    }else{      //enter
        if ((((character == 0x3) || (character == 0xd))) && ((flags & 0x1e0000) == 0x0)) {
            [self sendMsgToServer:nil];
            return YES;
        }
        [self.inputView insertLineBreak:nil];
        commandSelector=nil;
        return YES;
    }
}

-(void)sendMsgToServer:(id)sender
{
    DDUserlistModule* moduleFriend = [DDUserlistModule shareInstance];
    UserState myOnlineState = [[StateMaintenanceManager instance] getMyOnlineState];
    if (USER_STATUS_OFFLINE == myOnlineState) {
        DDLog(@"你已经处于离线状态，无法发送消息，请上线后再次尝试.\n");
        [_chatContentScrollView addHintWithContent:@"你已经处于离线状态，无法发送消息，请上线后再次尝试.\n"];
        return;
    }
    
    NSAttributedString *text = _inputView.textStorage;
    if ([[text string] allSpaceAllNewLine]) {
        DDLog(@"不能发送全部是空格或者换行的内容哦");
        return;
    }
    
    NSAttributedString* showInContentViewAttribute = [self.module getAttributedStringFromInputContent:text compress:YES];
    
    NSTextView* messageTextView = [[MessageViewFactory instance] produceTextViewWithMessage:showInContentViewAttribute];
    
    BOOL shouldShowTime = [self sendMessageShouldShowTime];
    NSString* time = @"";
    if (shouldShowTime)
    {
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM-dd HH:mm"];
        time = [dateFormatter stringFromDate:[NSDate date]];
    }
    log4CInfo(@"-------------------->user send message in UI");
        [_chatContentScrollView addMessageViewOnTail:messageTextView atLeft:NO name:@"" time:time forceScroll:YES userID:nil];

    NSAttributedString* sendContentAttribute = [self.module getAttributedStringFromInputContent:text compress:NO];
    //更新会话时间
    lastMessageDate = [[NSDate date] timeIntervalSince1970];
    lastMessageSenderID = moduleFriend.myUserId;
    self.module.session.lastSessionTime = lastMessageDate;
    SessionEntity* session = [[DDSessionModule shareInstance] getSessionBySId:self.module.session.sessionId];
    session.lastSessionTime = [[NSDate date] timeIntervalSince1970];
    [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:@{@"ScrollToSelected" : @(YES)} object:nil];
    
    [[DDMessageSendManager instance] sendMessage:sendContentAttribute forSession:self.module.session success:^(NSString *sendedContent) {

        DDMessageModule* moduleMess = [DDMessageModule shareInstance];
        [moduleMess countHistoryMsgOffset:self.module.session.sessionId offset:1];
        
        //保存在历史消息数据库
        totalMsgCnt ++;
        MessageEntity* message = [[MessageEntity alloc] init];
        switch (self.module.session.type) {
            case SESSIONTYPE_SINGLE:
                message.msgType = MESSAGE_TYPE_SINGLE;
                break;
            case SESSIONTYPE_GROUP:
                message.msgType = MESSAGE_TYPE_GROUP;
                break;
        }
        message.sessionId = [self.module.session.orginId copy];
        message.senderId = moduleFriend.myUserId;
        message.msgContent = sendedContent;
        message.msgTime = [[NSDate date] timeIntervalSince1970];
        [[DDDatabaseUtil instance] insertMessage:message
                                         success:^{
                                             
                                         } failure:^(NSString *errorDescripe) {
                                             DDLog(@"%@",errorDescripe);
                                         }];
    } failure:^(NSString *content) {
        log4Error(@"send message error,content:%@",content);
        
        NSError* error = NULL;
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"&\\$#@~\\^@\\[\\{:[\\w|\\W]+?:\\}\\]&\\$~@#@"
                                                                               options:0
                                                                                 error:&error];
        NSString* result = [regex stringByReplacingMatchesInString:content
                                                           options:0
                                                             range:NSMakeRange(0, content.length)
                                                      withTemplate:@"[图片]"];
        
        NSString* showMessage = [result length] > 10 ? [result substringToIndex:10] : result;
        NSString* hint = [NSString stringWithFormat:@"消息发送失败“%@”",showMessage];
        [_chatContentScrollView addHintWithContent:hint];
        
    }];

    [_inputView setString:@""];
    [self.undoManager removeAllActions];
}


-(void)imageViewLoadedImage:(EGOImageView *)imageView{
//    [_txtContent replaceImage:imageView.imageLocalPath atIndex:imageView.imageIndex fromUser:imageView.fromUserId];
    [egoImageViews removeObjectForKey:[NSString stringWithFormat:@"%ld", imageView.imageIndex]];
}
-(void)imageViewFailedToLoadImage:(EGOImageView *)imageView error:(NSError *)error{
    DDLog(@"  \n\n\n\n  imageViewFailedToLoadImage:%@ \nerror:%@\n\n\n",imageView,error);
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return proposedMinimumPosition + (_chatSplitView.frame.size.height-160);
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return proposedMaximumPosition - 80;
}

#pragma mark DDMessageShow Delegate
- (void)touchToRefresh
{

    [[DDDatabaseUtil instance] loadMessageBySessionId:self.module.session.sessionId
                                            msgOffset:totalMsgCnt
                                             msgCount:15
                                              success:^(NSArray *messages) {

      for(NSInteger index = 0; index < [messages count] ; index ++)
      {
          MessageEntity* msg = messages[index];
          if (index == [messages count] - 1)
          {
              //最顶部的消息
              [self addMessageToChatContentView:msg isHistoryMsg:YES showtime:kShowTime showName:kShowName];
          }
          else
          {
              ShowTime showtime;
              ShowName showname;
              MessageEntity* nextMessage = messages[index + 1];
              showtime = msg.msgTime - nextMessage.msgTime > 120 ? kShowTime : kNotShowTime;
              showname = [nextMessage.senderId isEqualToString:msg.senderId] ? kNotShowName : kShowName;
              [self addMessageToChatContentView:msg isHistoryMsg:YES showtime:showtime showName:showname];
          }
      }
      [_chatContentScrollView loadMessageFinishForCount:[messages count]];

                                              } failure:^(NSString *errorDescripe) {

                                              }];
}
#pragma mark DrawView Delegate
- (void)drawFileInTo:(NSString*)file
{
    SessionEntity* currentSession = self.module.session;
    //group 不支持文件传输
    if ([currentSession type] == SESSIONTYPE_GROUP)
        return ;
    // 离线不支持文件传输
    UserState myOnlineState = [[StateMaintenanceManager instance] getMyOnlineState];
    if (myOnlineState == USER_STATUS_OFFLINE) {
        return;
    }
//    DDFileTransferModule* module = getDDFileTransferModule();
//    [module sendFile:file toUserId:currentSession.orginId];
}

#pragma mark MessageShowView Delegate
- (void)messageShowView:(MessageShowView*)messageView selectTheUserID:(NSString*)userID forOperation:(UserOperation)operation
{
    DDUserlistModule* userListModule = [DDUserlistModule shareInstance];
    UserEntity* user = [userListModule getUserById:userID];
    if (!user)
    {
        DDLog(@"此用户不存在");
        return;
    }
    switch (operation)
    {
        case Chat:
        {
        
            DDSessionModule* sessionModule = [DDSessionModule shareInstance];
            if (![sessionModule.recentlySessionIds containsObject:userID])
            {
                [sessionModule createSingleSession:userID];
                [NotificationHelp postNotification:notificationReloadTheRecentContacts userInfo:nil object:nil];
            }
            [[DDMainWindowController instance] recentContactsSelectObject:userID];
            [[DDMainWindowController instance] openChatViewByUserId:userID];
        }
            break;
        case View:
        {
            DDUserInfoManager* userInfoManager = [DDUserInfoManager instance];
            [userInfoManager showUser:user forContext:nil];
        }
            break;
    }
}

#pragma mark privateAPI
- (BOOL)sendMessageShouldShowTime
{
    NSUInteger now = [[NSDate date] timeIntervalSince1970];
    if (now - self.module.session.lastSessionTime > 120)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)msgShouldShowTime:(MessageEntity*)message
{
    if (message.msgTime - lastMessageDate > 120)
    {
        lastMessageDate = message.msgTime;
        return YES;
    }
    else
    {
        lastMessageDate = message.msgTime;
        return NO;
    }
}

- (BOOL)shouldShowName:(MessageEntity*)message
{
    if ([message.senderId isEqualToString:lastMessageSenderID])
    {
        return NO;
    }
    else
    {
        lastMessageSenderID = [message.senderId copy];
        return YES;
    }
}

- (void)receiveTheGroupMemberNotification:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSString* sessionID = userInfo[@"notification_sid"];
    if ([self.module.session.sessionId isEqualToString:sessionID])
    {
        NSString* sessionID = self.module.session.sessionId;
        GroupEntity* group = [[DDGroupModule shareInstance] getGroupByGId:sessionID];
        if (group)
        {
            [group sortGroupUsers];
            [_chattingContactListViewController reloadContactListTableView];
        }
    }
    return;
}

- (void)receiveStateChangedNotification:(NSNotification *)notification
{
    NSString* uid = self.module.session.sessionId;
    UserState state = [[StateMaintenanceManager instance] getUserStateForUserID:uid];
    NSImage* image;
    switch (state)
    {
        case USER_STATUS_LEAVE:
            image = [NSImage imageNamed:@"state-leave"];
            break;
        case USER_STATUS_OFFLINE:
            image = [NSImage imageNamed:@"state-offline"];
            break;
        case USER_STATUS_ONLINE:
            image = [NSImage imageNamed:@"state-online"];
            break;
        default:
            break;
    }
    [self.chattingHeadViewController.state setImage:image];
}
@end
