//
//  DDChattingViewController.h
//  Duoduo
//
//  Created by zuoye on 13-12-2.
//  Copyright (c) 2013年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DDChattingInputView.h"
#import "MessageEntity.h"
#import "DDChattingContentView.h"
#import "EGOImageLoader.h"
#import "RTXImageSpreadView.h"
#import "SessionEntity.h"
#import "DDChattingContactListViewController.h"
#import "DDChattingHeadViewController.h"
#import "DDChattingContentView.h"
#import "PullToRefreshScrollView.h"
#import "DrawView.h"
#import "WhiteBackgroundView.h"
#import "MessageShowView.h"
typedef enum {
    kShowTime,
    kNotShowTime,
    kIgnore
}ShowTime;

typedef enum {
    kShowName,
    kNotShowName,
    kIgnoreThis
}ShowName;
@class MessageEntity,EGOImageView,DDGroupDataWindow,MessageShowView,DDChattingViewModule,AvatorImageView;
@interface DDChattingViewController : NSViewController<NSTextViewDelegate,NSSplitViewDelegate,EGOImageViewDelegate,DrawViewDelegate,MessageShowViewDelegate>{
   // EGOImageView *temIV;
    NSMutableDictionary *egoImageViews;
    DDUserDataWindowController* userDatawindowController;
    DDGroupDataWindow* groupDataWindow;
}

@property (nonatomic,retain)DDChattingViewModule* module;

@property (nonatomic,weak) IBOutlet MessageShowView *chatContentScrollView;
@property (nonatomic,strong) IBOutlet DDChattingInputView *inputView;
@property (nonatomic,weak) IBOutlet NSSplitView *chatSplitView;
@property (nonatomic,strong) IBOutlet WhiteBackgroundView *userTypingView;
@property (nonatomic,weak) IBOutlet RTXImageSpreadView *bottomRightView;
@property (nonatomic,weak) IBOutlet NSView *bottomMainView;
@property (nonatomic,weak) IBOutlet DDChattingContactListViewController *chattingContactListViewController;
@property(nonatomic,weak) IBOutlet NSImageView *inputBgView;
@property (nonatomic,weak) IBOutlet DDChattingHeadViewController *chattingHeadViewController;
@property (nonatomic,weak) IBOutlet DrawView* drawView;
@property (nonatomic,weak) IBOutlet NSButton* shakeButton;
@property (nonatomic,weak) IBOutlet NSButton * screenButton;
@property (nonatomic,weak) IBOutlet NSButton * emotionButton;
@property (nonatomic,weak) IBOutlet NSButton* almanceButton;
@property (nonatomic,weak) IBOutlet NSButton* bangButton;
- (void)emotionSelected:(NSString *)emotionFile;
- (IBAction)emotionClick:(id)sender;
- (IBAction)screenCaptureClick:(NSButton *)sender;
- (IBAction)almanceClick:(id)sender;
- (IBAction)bangClick:(id)sender;
//-(void)showMessage;
-(void)addMessageToChatContentView:(MessageEntity*)msg isHistoryMsg:(BOOL)isHistoryMsg showtime:(ShowTime)showtime showName:(ShowName)showname;



-(void)resetHistoryMessageInsertInfo;
-(void)makeInputViewFirstResponder;

- (IBAction)clickTheUserIcon:(id)sender;

- (void)scrollToMessageEnd;

- (void)updateUI;
@end
