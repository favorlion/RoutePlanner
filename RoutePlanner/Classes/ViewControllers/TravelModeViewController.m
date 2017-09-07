//
//  TravelModeViewController.m
//  RoutePlanner
//
//  Created by Favor on 8/23/16.
//  Copyright © 2016 Favor. All rights reserved.
//

#import "TravelModeViewController.h"

@interface TravelModeViewController ()

@end

@implementation TravelModeViewController

- (void)viewDidLoad {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UITableViewCell *cell= [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:travelMode inSection:0]];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    travelMode = (int)indexPath.row;
    for(int i = 0; i < 4; i ++) {
        [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].accessoryType = UITableViewCellAccessoryNone;
    }
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
