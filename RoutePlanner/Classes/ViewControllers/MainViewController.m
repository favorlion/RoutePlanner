//
//  ViewController.m
//  RoutePlanner
//
//  Created by Favor on 16/8/16.
//  Copyright © 2016 Favor. All rights reserved.
//

#import "MainViewController.h"
#import <GooglePlaces/GooglePlaces.h>
#import "MBProgressHUD+HM.h"

@interface MainViewController () <GMSAutocompleteViewControllerDelegate, CLLocationManagerDelegate>

@end

@implementation MainViewController

int mapType;
bool enableGeocoder;
int travelMode;
NSMutableArray *avoids;

GMSMarker *start_point = nil;
GMSMarker *end_point = nil;
NSString *WebServiceAPIKey = @"APIKEY3";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    avoids = [[NSMutableArray alloc] initWithObjects: @(NO), @(NO), @(NO), nil];
    travelMode = 0;
    enableGeocoder = YES;
    
    self.markers = [[NSMutableArray alloc] init];
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [self.locationManager requestWhenInUseAuthorization];
    _locationManager.delegate = self;
    
    mapType = kGMSTypeNormal;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.86
                                                            longitude:151.20
                                                                 zoom:10];
    CGRect mapFrame = self.view.frame;
    mapFrame.origin.y = self.navigationController.navigationBar.frame.size.height + 20;
    mapFrame.size.height -= self.navigationController.navigationBar.frame.size.height + 20 + _bottomView.frame.size.height;
    _mapView = [GMSMapView mapWithFrame:mapFrame camera:camera];
    _mapView.myLocationEnabled = YES;
    _mapView.accessibilityElementsHidden = NO;
    _mapView.settings.compassButton = YES;
    _mapView.settings.myLocationButton = YES;
    _mapView.settings.compassButton = YES;
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    _mapView.frame = _centerView.bounds;
    
    [_locationManager startUpdatingLocation];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:2 * 1024 * 1024 diskCapacity:10 * 1024 * 1024 diskPath:@"SessionData"];
    self.APISession = [NSURLSession sessionWithConfiguration:config];
}

- (void)viewWillAppear:(BOOL)animated {
    _mapView.mapType = mapType;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    _mapView.frame = _centerView.frame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if (enableGeocoder) {
        [MBProgressHUD showMessage:@"Geocoding..." toView:self.view];
        GMSGeocoder *geocoder = [GMSGeocoder geocoder];
        [geocoder reverseGeocodeCoordinate:coordinate completionHandler:^(GMSReverseGeocodeResponse *response, NSError *error) {
            if(response.firstResult.thoroughfare) {
                [self addMarkerWithName:response.firstResult.thoroughfare address:response.firstResult.thoroughfare coordinate:coordinate];
            }
            else if(response.firstResult.locality) {
                [self addMarkerWithName:response.firstResult.locality address:response.firstResult.locality coordinate:coordinate];
            }
            else {
                [self addMarkerWithName:@"<Unknown>" address:@"<Unknown>" coordinate:coordinate];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }];
    }
    else {
        [self addMarkerWithName:@"<Unknown>" address:@"<Unknown>" coordinate:coordinate];
    }
    
}

// Present the autocomplete view controller when the button is pressed.
- (IBAction)onAddAddressClicked:(id)sender {
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;
    [self presentViewController:acController animated:YES completion:nil];
}

// Handle the user's selection.
- (void)viewController:(GMSAutocompleteViewController *)viewController didAutocompleteWithPlace:(GMSPlace *)place {
    [self dismissViewControllerAnimated:YES completion:nil];
    // Do something with the selected place.
    [self addMarkerWithName:place.name address:place.formattedAddress coordinate:place.coordinate];
    [_mapView animateToLocation:place.coordinate];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController didFailAutocompleteWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    // TODO: handle the error.
    NSLog(@"Error: %@", [error description]);
}

// User canceled the operation.
- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Turn the network activity indicator on and off again.
- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    NSLog(@"UserLocation %f %f", [locations lastObject].coordinate.latitude, [locations lastObject].coordinate.longitude);
    [_mapView animateToLocation:[locations lastObject].coordinate];
    [_locationManager stopUpdatingLocation];
}

- (void)addMarkerWithName:(NSString *)name address:(NSString *)address coordinate:(CLLocationCoordinate2D)coordinate {
    GMSMarker *marker = [GMSMarker markerWithPosition:coordinate];
    if ([name isEqualToString:@""]) {
        marker.title = @"<Unknown>";
    }
    else {
        marker.title = name;
    }
    
    marker.snippet = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
    marker.icon = [UIImage imageNamed:@"Stop_Normal"];
    NSMutableDictionary *markerInfo = [[NSMutableDictionary alloc] init];
    [markerInfo setObject:marker forKey:@"marker"];
    [markerInfo setObject:name forKey:@"name"];
    [markerInfo setObject:address forKey:@"address"];
    [markerInfo setObject:[NSNumber numberWithDouble: coordinate.latitude] forKey:@"latitude"];
    [markerInfo setObject:[NSNumber numberWithDouble: coordinate.longitude] forKey:@"longitude"];
    [self.markers addObject:markerInfo];
    
    marker.map = _mapView;
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker {
    
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:marker.title
                                message:marker.snippet
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *set_start_point = [UIAlertAction
                         actionWithTitle:@"Set as start point"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction *action)
                         {
                             if(start_point) {
                                 if(start_point == end_point) {
                                     start_point.icon = [UIImage imageNamed:@"Stop_End"];
                                 }
                                 else {
                                     start_point.icon = [UIImage imageNamed:@"Stop_Normal"];
                                 }
                             }
                             
                             start_point = marker;
                             if(start_point == end_point) {
                                 marker.icon = [UIImage imageNamed:@"Stop_Round"];
                             }
                             else {
                                 marker.icon = [UIImage imageNamed:@"Stop_Start"];
                             }
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    UIAlertAction *unset_start_point = [UIAlertAction
                                      actionWithTitle:@"Unset start point"
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction *action)
                                      {
                                          if(start_point == end_point) {
                                              marker.icon = [UIImage imageNamed:@"Stop_End"];
                                          }
                                          else {
                                              marker.icon = [UIImage imageNamed:@"Stop_Normal"];
                                          }
                                          start_point = nil;
                                          [alert dismissViewControllerAnimated:YES completion:nil];
                                          
                                      }];
    
    UIAlertAction *set_end_point = [UIAlertAction
                                     actionWithTitle:@"Set as end point"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction *action)
                                     {
                                         if(end_point) {
                                             if(start_point == end_point) {
                                                 end_point.icon = [UIImage imageNamed:@"Stop_Start"];
                                             }
                                             else {
                                                 end_point.icon = [UIImage imageNamed:@"Stop_Normal"];
                                             }
                                         }
                                         
                                         end_point = marker;
                                         if(start_point == end_point) {
                                             marker.icon = [UIImage imageNamed:@"Stop_Round"];
                                         }
                                         else {
                                             marker.icon = [UIImage imageNamed:@"Stop_End"];
                                         }
                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction *unset_end_point = [UIAlertAction
                                        actionWithTitle:@"Unset end point"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                                        {
                                            if(start_point == end_point) {
                                                marker.icon = [UIImage imageNamed:@"Stop_Start"];
                                            }
                                            else {
                                                marker.icon = [UIImage imageNamed:@"Stop_Normal"];
                                            }
                                            end_point = nil;
                                            [alert dismissViewControllerAnimated:YES completion:nil];
                                            
                                        }];
    
    UIAlertAction *delete_point = [UIAlertAction
                                     actionWithTitle:@"Delete point"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction *action)
                                     {
                                         if(start_point == marker) {
                                             start_point = nil;
                                         }
                                         if(end_point == marker) {
                                             end_point = nil;
                                         }
                                         for(NSDictionary *m in _markers) {
                                             if([m objectForKey:@"marker"] == marker) {
                                                 [_markers removeObject:m];
                                                 break;
                                             }
                                         }
                                         marker.map = nil;
                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
    
    UIAlertAction *cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction *action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    if(marker != start_point) {
        [alert addAction:set_start_point];
    }
    
    if(marker == start_point) {
        [alert addAction:unset_start_point];
    }
    
    if(marker != end_point) {
        [alert addAction:set_end_point];
    }
    
    if(marker == end_point) {
        [alert addAction:unset_end_point];
    }
    
    [alert addAction:delete_point];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

-(IBAction)btnOptimizeAction:(id)sender {
    if(_markers.count > 1) {
        if (start_point) {
            [MBProgressHUD showMessage:@"Optimizing..." toView:self.view];
            NSString *travelModeString = @"";
            switch (travelMode) {
                case 1:
                    travelModeString = @"&mode=walking";
                    break;
                case 2:
                    travelModeString = @"&mode=bicycling";
                    break;
                case 3:
                    travelModeString = @"&mode=transit";
                    break;
                default:
                    break;
            }
            NSString *avoidString = @"";
            NSArray *avoidStrings = [[NSArray alloc] initWithObjects:@"tolls", @"highways", @"ferries", nil];
            int index = 0;
            for (NSNumber *a in avoids) {
                if ([a boolValue]) {
                    if ([avoidString isEqualToString:@""]) {
                        avoidString = [NSString stringWithFormat:@"&avoid=%@", avoidStrings[index]];
                    }
                    else {
                        avoidString = [avoidString stringByAppendingString:[NSString stringWithFormat:@"|%@", avoidStrings[index]]];
                    }
                }
                index ++;
            }
            if (end_point) {
                NSString *originString = @"";
                NSString *destinationString = @"";
                NSString *waypointsString = @"";
                NSMutableArray *waypointsStrings =[[NSMutableArray alloc] init];
                NSMutableArray *waypoints =[[NSMutableArray alloc] init];
                for (NSMutableDictionary *m in _markers) {
                    if ([m objectForKey:@"marker"] == start_point) {
                        originString = [NSString stringWithFormat:@"%@%@,%@", @"&origin=", [m valueForKey:@"latitude"], [m valueForKey:@"longitude"]];
                    }
                    if ([m objectForKey:@"marker"] == end_point) {
                        destinationString = [NSString stringWithFormat:@"%@%@,%@", @"&destination=", [m valueForKey:@"latitude"], [m valueForKey:@"longitude"]];
                    }
                    if ([m objectForKey:@"marker"] != start_point && [m objectForKey:@"marker"] != end_point) {
                        [waypointsStrings addObject:[NSString stringWithFormat:@"%@,%@",[m valueForKey:@"latitude"],[m valueForKey:@"longitude"]]];
                        [waypoints addObject:[m objectForKey:@"marker"]];
                    }
                }
                if ([waypointsStrings count] > 0) {
                    waypointsString = @"&waypoints=optimize:true|";
                    for (NSString *str in waypointsStrings) {
                        waypointsString = [waypointsString stringByAppendingString:str];
                        if ([waypointsStrings indexOfObject:str] != [waypointsStrings count] - 1) {
                            waypointsString = [waypointsString stringByAppendingString:@"|"];
                        }
                    }
                }
                NSString *URLString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?%@%@%@%@%@&key=%@", travelModeString, originString, destinationString, waypointsString, avoidString, WebServiceAPIKey];
                NSLog(@"%@", URLString);
                NSURL *APIURL = [NSURL URLWithString:[URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                NSURLSessionDataTask *task = [self.APISession dataTaskWithURL:APIURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *e) {
                    if(data) {
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        //NSLog(@"%@", json);
                        NSArray *routesArray = [json objectForKey:@"routes"];
                        if ([routesArray count] > 0)
                        {
                            NSDictionary *routeDict = [routesArray objectAtIndex:0];
                            NSArray *waypoint_order_array = [routeDict objectForKey:@"waypoint_order"];
                            NSDictionary *routeOverviewPolyline = [routeDict objectForKey:@"overview_polyline"];
                            NSString *points = [routeOverviewPolyline objectForKey:@"points"];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                for (NSNumber *i in waypoint_order_array) {
                                    NSInteger index = [waypoint_order_array indexOfObject:i];
                                    ((GMSMarker *)waypoints[[i integerValue]]).icon = [self markerImageWithText:[NSString stringWithFormat:@"%lu", index + 1]];
                                }
                                [self showPolylineWithEncodedPolyline:points];
                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                            });
                        }
                        else {
                            UIAlertController *alert = [UIAlertController
                                                        alertControllerWithTitle:@"Not available to optimize with current points and travel mode"
                                                        message:@"Please select another points or change travel mode, then try again"
                                                        preferredStyle:UIAlertControllerStyleAlert];
                            
                            
                            UIAlertAction *OK = [UIAlertAction
                                                 actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action)
                                                 {
                                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                                 }];
                            [alert addAction:OK];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                            });
                            [_APISession.configuration.URLCache removeAllCachedResponses];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }
                    else {
                        UIAlertController *alert=   [UIAlertController
                                                     alertControllerWithTitle:@"Connection Error"
                                                     message:@"Please try again"
                                                     preferredStyle:UIAlertControllerStyleAlert];
                        
                        
                        UIAlertAction *OK = [UIAlertAction
                                             actionWithTitle:@"OK"
                                             style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action)
                                             {
                                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                             }];
                        [alert addAction:OK];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                        });
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }];
                [task resume];
            }
            else{
                __block NSString *optimizedPoints = @"";
                __block long optimizedDuration = -1;
                __block NSMutableArray *optimizedWaypoint_order_array = nil;
                __block NSMutableArray *optimizedWaypoints = nil;
                __block NSMutableDictionary *optimizedEndMarker = nil;
                __block int jsonCount = 0;
                for (NSMutableDictionary *tempEndMarker in _markers) {
                    NSString *originString = @"";
                    NSString *destinationString = @"";
                    NSString *waypointsString = @"";
                    NSMutableArray *waypointsStrings = [[NSMutableArray alloc] init];
                    NSMutableArray *waypoints = [[NSMutableArray alloc] init];
                    for (NSMutableDictionary *m in _markers) {
                        if ([m objectForKey:@"marker"] == start_point) {
                            originString = [NSString stringWithFormat:@"%@%@,%@", @"&origin=", [m valueForKey:@"latitude"], [m valueForKey:@"longitude"]];
                        }
                        if (m == tempEndMarker) {
                            destinationString = [NSString stringWithFormat:@"%@%@,%@", @"&destination=", [m valueForKey:@"latitude"], [m valueForKey:@"longitude"]];
                        }
                        if ([m objectForKey:@"marker"] != start_point && m != tempEndMarker) {
                            [waypointsStrings addObject:[NSString stringWithFormat:@"%@,%@",[m valueForKey:@"latitude"],[m valueForKey:@"longitude"]]];
                            [waypoints addObject:[m objectForKey:@"marker"]];
                        }
                    }
                    if ([waypointsStrings count] > 0) {
                        waypointsString = @"&waypoints=optimize:true|";
                        for (NSString *str in waypointsStrings) {
                            waypointsString = [waypointsString stringByAppendingString:str];
                            if ([waypointsStrings indexOfObject:str] != [waypointsStrings count] - 1) {
                                waypointsString = [waypointsString stringByAppendingString:@"|"];
                            }
                        }
                    }
                    NSString *URLString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?%@%@%@%@%@&key=%@", travelModeString, originString, destinationString, waypointsString, avoidString, WebServiceAPIKey];
                    NSLog(@"%@", URLString);
                    NSURL *APIURL = [NSURL URLWithString:[URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    NSURLSessionDataTask *task = [self.APISession dataTaskWithURL:APIURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *e) {
                        if(data) {
                            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                            jsonCount++;
                            //NSLog(@"%@", json);
                            NSArray *routesArray = [json objectForKey:@"routes"];
                            if ([routesArray count] > 0)
                            {
                                NSDictionary *routeDict = [routesArray objectAtIndex:0];
                                NSMutableArray *waypoint_order_array = [routeDict objectForKey:@"waypoint_order"];
                                NSDictionary *routeOverviewPolyline = [routeDict objectForKey:@"overview_polyline"];
                                NSString *points = [routeOverviewPolyline objectForKey:@"points"];
                                NSArray *legsArray = [routeDict objectForKey:@"legs"];
                                long duration = 0;
                                for (NSDictionary *leg in legsArray) {
                                    duration += [[[leg objectForKey:@"duration"] objectForKey:@"value"] longValue];
                                }
                                NSLog(@"%lu", duration);
                                if(optimizedDuration == -1 || optimizedDuration > duration) {
                                    optimizedDuration = duration;
                                    optimizedPoints = points;
                                    optimizedWaypoint_order_array = waypoint_order_array;
                                    optimizedWaypoints = waypoints;
                                    optimizedEndMarker = tempEndMarker;
                                }
                                if(jsonCount == _markers.count) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        NSLog(@"Final:%lu", optimizedDuration);
                                        for (NSNumber *i in optimizedWaypoint_order_array) {
                                            NSInteger index = [optimizedWaypoint_order_array indexOfObject:i];
                                            ((GMSMarker*)optimizedWaypoints[[i integerValue]]).icon = [self markerImageWithText:[NSString stringWithFormat:@"%lu", index + 1]];
                                        }
                                        ((GMSMarker*)[optimizedEndMarker objectForKey:@"marker"]).icon = [self markerImageWithText:[NSString stringWithFormat:@"%lu", optimizedWaypoint_order_array.count + 1]];
                                        [self showPolylineWithEncodedPolyline:optimizedPoints];
                                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                                    });
                                }
                            }
                            else {
                                UIAlertController *alert =  [UIAlertController
                                                             alertControllerWithTitle:@"Not available to optimize with current points and travel mode"
                                                             message:@"Please select another points or change travel mode, then try again"
                                                            preferredStyle:UIAlertControllerStyleAlert];
                                
                                
                                UIAlertAction *OK = [UIAlertAction
                                                    actionWithTitle:@"OK"
                                                    style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action)
                                                    {
                                                        [alert dismissViewControllerAnimated:YES completion:nil];
                                                    }];
                                [alert addAction:OK];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                                });
                                [_APISession.configuration.URLCache removeAllCachedResponses];
                                [self presentViewController:alert animated:YES completion:nil];
                            }
                        }
                        else {
                            UIAlertController *alert = [UIAlertController
                                                        alertControllerWithTitle:@"Connection Error"
                                                        message:@"Please try again"
                                                        preferredStyle:UIAlertControllerStyleAlert];
                            
                            
                            UIAlertAction *OK = [UIAlertAction
                                                 actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action)
                                                 {
                                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                                 }];
                            [alert addAction:OK];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                            });
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }];
                    [task resume];
                }
            }
        }
        else {
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:@"There is not a start point"
                                        message:@"Please select a start point"
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            
            UIAlertAction *OK = [UIAlertAction
                                 actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                 }];
            [alert addAction:OK];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Not available to optimize with one point"
                                    message:@"Please add another points"
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction *OK = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
        [alert addAction:OK];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(IBAction)btnNewAction:(id)sender {
    for(NSDictionary *m in _markers) {
        ((GMSMarker*)[m objectForKey:@"marker"]).map = nil;
    }
    start_point = nil;
    end_point = nil;
    [_markers removeAllObjects];
    _routePolyline.map = nil;
}

- (UIImage*) markerImageWithText:(NSString*)text {
    UIImageView *pinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Stop_Normal"]];
    UIView *view = [[UIView alloc] initWithFrame:pinImageView.frame];
    UILabel *label = [UILabel new];
    CGRect labelFrame = CGRectMake(pinImageView.frame.size.width * 0.1, pinImageView.frame.size.height * 0.1, pinImageView.frame.size.width * 0.8, pinImageView.frame.size.height * 0.5);
    label.frame = labelFrame;
    label.text = text;
    label.font = [UIFont systemFontOfSize:14];
    label.textAlignment = NSTextAlignmentCenter;
    
    [view addSubview:pinImageView];
    [view addSubview:label];
    UIImage *markerIcon = [self imageFromView:view];
    return markerIcon;
}

- (UIImage *)imageFromView:(UIView *) view
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(view.frame.size);
    }
    [view.layer renderInContext: UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(void)showPolylineWithEncodedPolyline:(NSString*)encodedPolyline {
    GMSPath *path = [GMSPath pathFromEncodedPath:encodedPolyline];
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeWidth = 4;
    polyline.strokeColor = [UIColor colorWithRed:255 green:0 blue:0 alpha:0.5];
    polyline.map = _mapView;
    if(_routePolyline) {
        _routePolyline.map = nil;
    }
    _routePolyline = polyline;
}

@end
