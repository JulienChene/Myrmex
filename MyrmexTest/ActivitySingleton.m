//
//  ActivitySingleton.m
//  MyrmexTest
//
//  Created by Julien Chene on 09/09/14.
//  Copyright (c) 2014 JulienChene. All rights reserved.
//

#import "ActivitySingleton.h"

#define kUserToken  @"UserToken"
#define kTriggerTime 10//(60 * 45) // 45 minutes
#define kLocationTimer (60 * 9) // Update the location every 8 minutes to avoid app extinction (after 10 minutes)

@implementation ActivitySingleton

@synthesize locationManager;
@synthesize locationReminder;
@synthesize session;
@synthesize userToken;
@synthesize userState;
@synthesize canSurveyPop;
@synthesize locationTimer;
@synthesize locationUpdateTimer;
@synthesize delayTimer;
@synthesize isLocationReminderRunning;

static ActivitySingleton* _sharedActivitySingleton = nil;


+ (ActivitySingleton*)sharedActivitySingleton
{
    if (_sharedActivitySingleton == nil)
    {
        _sharedActivitySingleton = [[super alloc] init];
    }
    
    return _sharedActivitySingleton;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        locationManager = [[CLLocationManager alloc] init];
        // Check if the device is iOS 8
        if(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
            [locationManager requestAlwaysAuthorization];
        [locationManager setDelegate:self];
        [locationManager setDistanceFilter:5];
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        
        [locationManager startUpdatingLocation];
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPAdditionalHeaders = @{@"Content-Type":@"application/json"};
        session = [NSURLSession sessionWithConfiguration:config
                                                delegate:self
                                           delegateQueue:nil];
        
        canSurveyPop = NO;
        [self notificationPopped];
        userState = @"Idle";
        userToken = @"UNDEFINED";
        
        locationTimer = [NSTimer scheduledTimerWithTimeInterval:kLocationTimer
                                                         target:self
                                                       selector:@selector(updateLocation)
                                                       userInfo:nil
                                                        repeats:YES];
        isLocationReminderRunning = NO;
        
        locationUpdateTimer = [[NSTimer alloc] init];
        delayTimer = [[NSTimer alloc] init];
        
        locationReminder = [[CLLocationManager alloc] init];
    }
    
    return self;
}

- (void)updateLocation
{
    NSLog(@"\tupdateLocation");
    [locationReminder setDelegate:self];
    [locationReminder setDistanceFilter:5];
    locationReminder.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationReminder startUpdatingLocation];
    isLocationReminderRunning = YES;
}

- (void)restartLocationReminderTimer
{
    NSLog(@"\tLocationTimer reset");
    [locationTimer invalidate];
    locationTimer = [NSTimer scheduledTimerWithTimeInterval:kLocationTimer
                                                     target:self
                                                   selector:@selector(updateLocation)
                                                   userInfo:nil
                                                    repeats:YES];
}

- (void)notificationPopped
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kTriggerTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        canSurveyPop = YES;
        NSLog(@"Survey can now pop");
    });
}

- (UILocalNotification*)setNotification
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    [localNotification setAlertBody:@"Do you want to take the survey?"];
    [localNotification setSoundName:UILocalNotificationDefaultSoundName];
    
    return localNotification;
}

- (NSURL *)getServerAddressWithString:(NSString*) service
{
    NSURL *result = nil;
    NSMutableString *address = [[NSMutableString alloc] initWithString:NSLocalizedString(@"SERVER_ADDRESS", nil)];
    
    if ([service isEqualToString:@"DeviceToken"])
        [address appendString:NSLocalizedString(@"DEVICE_TOKEN", nil)];
    
    result = [NSURL URLWithString:address];
    return result;
}

#pragma mark CLLocation Delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
//    NSLog(@"Activity Location Manager called");
    
    CLLocation *currentLocation = [locations objectAtIndex:[locations count] - 1];
    NSDate *timestamp = [currentLocation timestamp];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]];
    float longitude = [currentLocation coordinate].longitude;
    float latitude = [currentLocation coordinate].latitude;
    
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:userToken, @"userToken",
                          [[NSNumber numberWithFloat:latitude] stringValue], @"latitude",
                          [[NSNumber numberWithFloat:longitude] stringValue], @"longitude",
                          userState, @"userState",
                          [dateFormatter stringFromDate:timestamp], @"timestamp",
                          nil];
    
    // create addLocation URL
    NSString *URL = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"SERVER_ADDRESS", nil), NSLocalizedString(@"LOCATION_URL", nil)];
    [self delayNetworkTransmissionWithURL:URL andDict:dict];
    
    if (isLocationReminderRunning)
    {
        isLocationReminderRunning = NO;
        //[locationReminder stopUpdatingLocation];
        // Turns off GPS
        [locationReminder setDistanceFilter:9999];
        locationReminder.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        
        [self restartLocationReminderTimer];
        NSLog(@"Location Reminder triggered");
    }
}

- (void)delayNetworkTransmissionWithURL:(NSString*)URL andDict:(NSDictionary*)dict
{
    [delayTimer invalidate];
    delayTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                  target:self
                                                selector:@selector(sendUploadToVC:)
                                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:URL, @"URL", dict, @"dict", nil]
                                                 repeats:NO];
}

- (void)sendUploadToVC:(NSTimer*)timer
{
    [[ActivitySingleton sharedActivitySingleton] uploadToServerWithURL:[[timer userInfo] objectForKey:@"URL"] andDict:[[timer userInfo] objectForKey:@"dict"]];
}

#pragma mark Networking
- (void)uploadToServerWithURL:(NSString*)URL andDict:(NSDictionary*)dict
{
    // Transforms dict into JSON
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSLog(jsonString);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]];
    request.HTTPMethod = @"POST";
    
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:jsonData
                                                      completionHandler:^(NSData *data,
                                                                          NSURLResponse *response,
                                                                          NSError *error){
                                                          NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                                                          
                                                          if (!error && httpResp.statusCode == 200)
                                                              NSLog(@"Response code : 200");
                                                      }];

    [uploadTask resume];
}

#pragma mark Saving data for future use.

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:userToken forKey:kUserToken];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    userToken = [aDecoder decodeObjectForKey:kUserToken];
    
    return [self init];
}

@end
