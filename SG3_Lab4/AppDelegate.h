//
//  AppDelegate.h
//  SG3_Lab4
//
//  Created by Jeff Lanning on 6/24/15.
//  Copyright (c) 2015 Jeff Lanning. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

// Add location manager property to app delegate.
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) CMMotionManager *motionManager;

- (CMMotionManager*)sharedMotionManager;

@end

