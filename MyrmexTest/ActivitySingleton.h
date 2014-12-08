//
//  ActivitySingleton.h
//  MyrmexTest
//
//  Created by Julien Chene on 09/09/14.
//  Copyright (c) 2014 JulienChene. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CMMotionActivityManager.h>
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface ActivitySingleton : NSObject<CLLocationManagerDelegate, NSURLSessionDelegate, NSCoding>

@property (strong, nonatomic) CLLocationManager     *locationManager;
@property (strong, nonatomic) CLLocationManager     *locationReminder;
@property (strong, nonatomic) NSURLSession          *session;
@property (strong, nonatomic) NSString              *userState;
@property (strong, nonatomic) NSString              *userToken;
@property (strong, nonatomic) NSTimer               *locationTimer;
@property (strong, nonatomic) NSTimer               *locationUpdateTimer;
@property (strong, nonatomic) NSTimer               *delayTimer;

@property (assign) Boolean                          canSurveyPop;
@property (assign) Boolean                          isLocationReminderRunning;

+ (ActivitySingleton*)sharedActivitySingleton;
- (void)uploadToServerWithURL:(NSString*)URL andDict:(NSDictionary*)dict;
- (UILocalNotification*)setNotification;
- (void)notificationPopped;
- (void)restartLocationReminderTimer;

@end
