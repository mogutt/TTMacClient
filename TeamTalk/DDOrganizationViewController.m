//
//  DDOrganizationViewController.m
//  Duoduo
//
//  Created by 独嘉 on 14-8-18.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDOrganizationViewController.h"
#import "DDOriginzationModule.h"
#import "UserEntity.h"
#import "DDDepartmentModule.h"
@implementation DDOrganizationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

- (void)awakeFromNib
{
    [self.outlineView setHeaderView:nil];
}

- (DDOriginzationModule*)module
{
    if (!_module)
    {
        _module = [[DDOriginzationModule alloc] init];
    }
    return _module;
}

#pragma mark - NSOutlineView delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        return [self.module.originzation count];
    }
    else if([item isKindOfClass:NSClassFromString(@"NSString")])
    {
        return [self.module.originzation[item] count];
    }
    return 0;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return 36;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    return [self.module childItemAtIndex:index forItem:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (!item || [item isKindOfClass:NSClassFromString(@"NSString")])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:NSClassFromString(@"NSString")])
    {
        DepartmentEntity* department = [[DDDepartmentModule shareInstance] getDepartmentForID:item];
        if (department)
        {
            return department.title;
        }
        else
        {
            return item;
        }
    }
    else if ([item isKindOfClass:NSClassFromString(@"UserEntity")])
    {
        UserEntity* user = (UserEntity*)item;
        return user.nick;
    }
    return nil;
}

//- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
//{
//    if ([item isKindOfClass:NSClassFromString(@"UserEntity")])
//    {
//        NSString* identifier = [tableColumn identifier];
//        NSString* cellIdentifier = @"DDAddChatGroupCellIdentifier";
//        if ([identifier isEqualToString:@"NameColumn"])
//        {
//            return nil;
//        }
//    }
//    else if ([item isKindOfClass:NSClassFromString(@"DDAddChatGroup")])
//    {
//        //DDAddGroupMemberDepartmentCellIdentifier
//        NSString* identifier = [tableColumn identifier];
//        NSString* cellIdentifier = @"DDAddGroupMemberDepartmentCellIdentifier";
//        if ([identifier isEqualToString:@"NameColumn"])
//        {
//            return nil;
//        }
//    }
//    return nil;
//}
@end
