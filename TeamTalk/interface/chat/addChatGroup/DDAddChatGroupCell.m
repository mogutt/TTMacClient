//
//  DDAddChatGroupCell.m
//  Duoduo
//
//  Created by 独嘉 on 14-3-2.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDAddChatGroupCell.h"
#import "UserEntity.h"
#import "DDAddChatGroup.h"
#import "AvatorImageView.h"
@implementation DDAddChatGroupCell

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib
{

}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    // Drawing code here.
}

- (void)setItem:(id)item
{
    if ([item isKindOfClass:NSClassFromString(@"UserEntity")])
    {
        [self.avatar setUser:item];
        [self.name setStringValue:[(UserEntity*)item name]];
    }
    if ([item isKindOfClass:NSClassFromString(@"DDAddChatGroup")])
    {
        [self.avatar setImage:[NSImage imageNamed:@"man_placeholder"]];
        [self.name setStringValue:[(DDAddChatGroup*)item name]];
    }
}

@end
