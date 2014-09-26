//
//  DDGroupViewController.m
//  Duoduo
//
//  Created by 独嘉 on 14-4-29.
//  Copyright (c) 2014年 zuoye. All rights reserved.
//

#import "DDGroupViewController.h"
#import "DDGroupVCModule.h"
#import "DDGroupCell.h"
@interface DDGroupViewController ()

- (void)p_clickTheTableView;

@end

@implementation DDGroupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib
{
    [_tableView setHeaderView:nil];
    [_tableView setTarget:self];
    [_tableView setAction:@selector(p_clickTheTableView)];
    
}

- (DDGroupVCModule*)module
{
    if (!_module)
    {
        _module = [[DDGroupVCModule alloc] init];
    }
    return _module;
}

#pragma mark - public
- (void)selectGroup:(NSString*)group
{
    NSInteger row = [self.module indexAtGroups:group];
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    
}


- (void)initialData
{
    [self.module loadGroupCompletion:^(NSArray *groups) {
        [_tableView reloadData];
    }];
}


#pragma mark DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    
    return [self.module.groups count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 50;
}

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString* identifier = [tableColumn identifier];
    NSString* cellIdentifier = @"GroupCellIdentifier";
    if ([identifier isEqualToString:@"GroupColumnIdentifier"])
    {
        DDGroupCell* cell = (DDGroupCell*)[tableView makeViewWithIdentifier:cellIdentifier owner:self];
        if (!cell)
        {
            NSNib* nib = [[NSNib alloc] initWithNibNamed:@"DDDepartmentTableViewCell" bundle:nil];
            [tableView registerNib:nib forIdentifier:cellIdentifier];
        }
        cell = (DDGroupCell*)[tableView makeViewWithIdentifier:cellIdentifier owner:self];
        GroupEntity* group = self.module.groups[row];
        [cell configWithGroup:group];
        return cell;
    }
    return nil;
}

#pragma mark private
- (void)p_clickTheTableView
{
    NSInteger clickRow = [_tableView selectedRow];
    if (clickRow >= 0)
    {
        GroupEntity* group = self.module.groups[clickRow];
        if (self.delegate)
        {
            [self.delegate groupViewController:self selectGroup:group];
        }
    }
}

@end
