//
//  SurveyViewController.h
//  MyrmexTest
//
//  Created by Julien Chene on 25/09/14.
//  Copyright (c) 2014 JulienChene. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XL/Controllers/XLFormViewController.h"
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface SurveyViewController : XLFormViewController <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager     *onePointLocation;
@property (strong, nonatomic) NSMutableDictionary   *locationDictionary;

@end
