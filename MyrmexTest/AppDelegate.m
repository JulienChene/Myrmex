//
//  AppDelegate.m
//  MyrmexTest
//
//  Created by Julien Chene on 04/09/14.
//  Copyright (c) 2014 JulienChene. All rights reserved.
//

#import "AppDelegate.h"
#import "SurveyViewController.h"
#import "ViewController.h"

@implementation AppDelegate

@synthesize window;
@synthesize activityManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunching");
    // Activity Manager init
    activityManager = [[CMMotionActivityManager alloc] init];
    [activityManager startActivityUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMotionActivity *activity)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             [self motionHandlerWithActivity:activity];
         });
     }];
    
    // Location Manager init
    CLLocationManager *locationUpdateManager = [[ActivitySingleton sharedActivitySingleton] locationManager];
    [locationUpdateManager startUpdatingLocation];
    
    // Gives authorization for notifications and sound
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    // Checks if the app is opened via notification
    NSDictionary *userInfo = [launchOptions valueForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
    if (apsInfo)
    {
        NSLog(@"apsInfo");
        // Initializes surveyViewController through the storyboard
        SurveyViewController *surveyViewController = (SurveyViewController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NavigationController"];
        self.window.rootViewController = surveyViewController;
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"didReceiveLocalNotification");
    SurveyViewController *surveyViewController = (SurveyViewController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NavigationController"];
    self.window.rootViewController = surveyViewController;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
//    NSLog(@"Local Notif");
//    // Initializes surveyViewController through the storyboard
//    SurveyViewController *surveyViewController = (SurveyViewController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NavigationController"];
//    self.window.rootViewController = surveyViewController;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)motionHandlerWithActivity:(CMMotionActivity*) activity
{
    if ([activity walking])
    {
        [[ActivitySingleton sharedActivitySingleton] setUserState:@"Walking"];
//        NSLog(@"Phone State Walking");
    }
    if ([activity running])
    {
        [[ActivitySingleton sharedActivitySingleton] setUserState:@"Running"];
//        NSLog(@"Phone State Runnin");
    }
    if ([activity stationary])
    {
        [[ActivitySingleton sharedActivitySingleton] setUserState:@"Stationary"];
//        NSLog(@"Phone State Stationary");
    }
    if ([activity automotive])
    {
        [[ActivitySingleton sharedActivitySingleton] setUserState:@"Automative"];
//        NSLog(@"Phone State Automotive");
    }
    if ([activity cycling])
    {
        [[ActivitySingleton sharedActivitySingleton] setUserState:@"Cycling"];
//        NSLog(@"Phone State Cycling");
    }
    if ([activity unknown])
    {
        [[ActivitySingleton sharedActivitySingleton] setUserState:@"Unknown"];
//        NSLog(@"Phone State Unknown");
    }
    // Don't pop a survey if no action is done.
    if ([[ActivitySingleton sharedActivitySingleton] canSurveyPop] && ![[[ActivitySingleton sharedActivitySingleton] userState] isEqualToString:@"Stationary"])
    {
        [[ActivitySingleton sharedActivitySingleton] setCanSurveyPop:NO];
        [[ActivitySingleton sharedActivitySingleton] notificationPopped];
        UILocalNotification *localNotification = [[ActivitySingleton sharedActivitySingleton] setNotification];
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
}

- (void)newScreen
{
    SurveyViewController *surveyViewController = (SurveyViewController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NavigationController"];
    self.window.rootViewController = surveyViewController;
}

- (void)backToHome
{
    ViewController *homeViewController = (ViewController*)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"HomeViewController"];
    self.window.rootViewController = homeViewController;
}

@end
