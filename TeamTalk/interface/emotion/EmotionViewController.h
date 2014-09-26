//
//  EmotionViewController.h
//  Duoduo
//
//  Created by jianqing.du on 14-1-21.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EmotionCellView.h"

@class DDChattingViewController;

@interface EmotionViewController : NSViewController<NSTabViewDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property NSPopover *popover;
@property (nonatomic, weak) IBOutlet NSTabView *emotionTabView;
//@property (weak) IBOutlet NSTableView *defaultTableView;
//@property (weak) IBOutlet NSTableView *moodTableView;
//@property (weak) IBOutlet NSTableView *leisureTableView;
//@property (weak) IBOutlet NSTableView *jokeTableView;
@property (nonatomic,strong) IBOutlet NSTableView *yayaTableView;
@property(nonatomic,weak)IBOutlet NSTextField *emotionPreviewBG;
@property(nonatomic,weak)IBOutlet NSImageView *emotionPreview;
- (void)setChattingViewController:(DDChattingViewController *)chatViewController;

- (void)showUp:(NSButton *)button;

- (void)clickEmotionView:(EmotionCellView *)cellView;

// input: @"[呵呵]" output: @"0.gif"
- (NSString *)getFileFrom:(NSString *)text;

// input: @"0.gif" output: @"[呵呵]"
- (NSString *)getTextFrom:(NSString *)file;
-(void)hiddenEmotionPreview;
-(void)showEmotionPreview:(EmotionCellView *)cell;

@end
