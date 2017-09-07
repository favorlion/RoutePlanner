//
//  ViewViewController.m
//  RoutePlanner
//
//  Created by Favor on 8/22/16.
//  Copyright © 2016 Favor. All rights reserved.
//

#import "ViewViewController.h"

@interface ViewViewController ()

@end

@implementation ViewViewController

- (void)viewDidLoad {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    int row = 0;
    switch (mapType) {
        case kGMSTypeNormal:
            row = 0;
            break;
        case kGMSTypeHybrid:
            row = 1;
            break;
        case kGMSTypeSatellite:
            row = 2;
            break;
        case kGMSTypeTerrain:
            row = 3;
            break;
        default:
            break;
    }
    UITableViewCell *cell= [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    for(int i = 0; i < 4; i ++) {
        [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].accessoryType = UITableViewCellAccessoryNone;
    }
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    switch (indexPath.row) {
        case 0:
        {
            mapType = kGMSTypeNormal;
            break;
        }
        case 1:
        {
            mapType = kGMSTypeHybrid;
            break;
        }
        case 2:
        {
            mapType = kGMSTypeSatellite;
            break;
        }
        case 3:
        {
            mapType = kGMSTypeTerrain;
            break;
        }
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end