//
//  DDRecentContactsCell.h
//  Duoduo
//
//  Created by 独嘉 on 14-4-30.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AvatorImageView,SessionEntity;
@interface DDRecentContactsCell : NSTableCellView
{
    __weak IBOutlet AvatorImageView* avatarImageView;
    __weak IBOutlet NSTextField* nameTextField;
    __weak IBOutlet NSImageView* topIconImageView;
    __weak IBOutlet NSImageView* shieldIconImageView;
    __weak IBOutlet NSTextField* unreadMessageLabel;
    __weak IBOutlet NSImageView* unreadMessageBackground;
}
@property(nonatomic,strong)NSColor *tempColor;
-(void)clearUnreadCount;
- (void)configeCellWithObject:(SessionEntity*)object;
- (void)setselected:(BOOL)selected;

- (void)setTopIconHidden:(BOOL)hidden;
@end
