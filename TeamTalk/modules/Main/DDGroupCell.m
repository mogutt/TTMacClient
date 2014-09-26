//
//  DDGroupCell.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-30.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDGroupCell.h"
#import "GroupEntity.h"
#import "AvatorImageView.h"
#import "DDGroupModule.h"
@implementation DDGroupCell
- (void)configWithGroup:(GroupEntity*)group
{
    NSURL* imageURL = [NSURL URLWithString:group.avatar];
    [avatorImageView setType:GroupAvator];
    
    //这都是为了群头像啊
    GroupEntity* fixGroup = [[DDGroupModule shareInstance] getGroupByGId:group.groupId];
    
    [avatorImageView setGroup:fixGroup];
    [avatorImageView loadImageWithURL:imageURL setplaceholderImage:@"group_placeholder"];
    
    if (group.name)
    {
        [self.nameTextField setStringValue:group.name];
    }
    else
    {
        [self.nameTextField setStringValue:@""];
    }
    
    
}
- (void) setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    NSTableRowView *row = (NSTableRowView*)self.superview;
    if (row.isSelected) {
        self.nameTextField.textColor = [NSColor whiteColor];
    } else {
        self.nameTextField.textColor = [NSColor blackColor];
    }
    
}
@end
