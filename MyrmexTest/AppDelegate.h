//
//  AppDelegate.h
//  MyrmexTest
//
//  Created by Julien Chene on 04/09/14.
//  Copyright (c) 2014 JulienChene. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivitySingleton.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CMMotionActivityManager  *activityManager;

- (void)newScreen;
- (void)backToHome;

@end