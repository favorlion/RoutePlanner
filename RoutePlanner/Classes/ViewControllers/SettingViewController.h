//
//  SettingViewController.h
//  RoutePlanner
//
//  Created by Favor on 8/23/16.
//  Copyright © 2016 Favor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "MainViewController.h"

@interface SettingViewController : UITableViewController

@property(strong, nonatomic) IBOutlet UISwitch *switchGeocoder;

@end