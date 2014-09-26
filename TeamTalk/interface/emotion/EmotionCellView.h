//
//  EmotionCellView.h
//  Duoduo
//
//  Created by jianqing.du on 14-1-21.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EmotionViewController;
@interface EmotionCellView : NSTableCellView {
    EmotionViewController *emotionViewController;
    NSString *emotionFile;
}
@property(nonatomic,assign)NSInteger colTag;
@property(nonatomic,strong) EmotionViewController *emotionViewController;
@property(nonatomic,strong) NSString *emotionFile;
@property(nonatomic,strong)NSButton *button;
@end
