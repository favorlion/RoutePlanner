//
//  AvoidViewController.m
//  RoutePlanner
//
//  Created by Favor on 8/23/16.
//  Copyright © 2016 Favor. All rights reserved.
//

#import "AvoidViewController.h"

@interface AvoidViewController ()

@end

@implementation AvoidViewController

- (void)viewDidLoad {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    for(int i = 0; i < 3; i ++) {
        UITableViewCell *cell= [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if ([avoids[i] boolValue]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([avoids[(int)indexPath.row] boolValue]) {
        avoids[(int)indexPath.row] = @(NO);
    }
    else {
        avoids[(int)indexPath.row] = @(YES);
    }
    for(int i = 0; i < 3; i ++) {
        UITableViewCell *cell= [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if ([avoids[i] boolValue]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
