//
//  SettingViewController.m
//  RoutePlanner
//
//  Created by Favor on 8/23/16.
//  Copyright © 2016 Favor. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

- (void)viewDidLoad {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_switchGeocoder setOn:enableGeocoder];
}

- (IBAction)switchGocoderAction:(id)sender
{
    enableGeocoder = [(UISwitch*)sender isOn];
}

@end
