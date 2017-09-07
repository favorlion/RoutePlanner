//
//  ViewController.h
//  RoutePlanner
//
//  Created by Favor on 16/8/16.
//  Copyright © 2016 Favor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>

extern int mapType;
extern bool enableGeocoder;
extern int travelMode;
extern NSMutableArray *avoids;

@interface MainViewController : UIViewController<GMSMapViewDelegate>

@property(strong, nonatomic) NSMutableArray *markers;
@property(strong, nonatomic) GMSPolyline *routePolyline;
@property(strong, nonatomic) GMSMapView* mapView;
@property(strong, nonatomic) CLLocationManager *locationManager;
@property(strong, nonatomic) NSURLSession *APISession;
@property(strong, nonatomic) IBOutlet UIView *centerView;
@property(strong, nonatomic) IBOutlet UIView *bottomView;

@end

