//
//  DDChattingContactListCell.h
//  Duoduo
//
//  Created by 独嘉 on 14-3-14.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UserEntity.h"
@interface DDChattingContactListCell : NSTableCellView
{
    __weak IBOutlet NSImageView* _stateImageView;
    __weak IBOutlet NSTextField* _userNameTextField;
}

- (void)configeWithUser:(UserEntity*)user;
@end
