//
//  SurveyViewController.m
//  MyrmexTest
//
//  Created by Julien Chene on 25/09/14.
//  Copyright (c) 2014 JulienChene. All rights reserved.
//

#import "ActivitySingleton.h"
#import "SurveyViewController.h"
#import "Survey.h"
#import "XL/XLForm.h"
#import "AppDelegate.h"

NSString *const kInteruptability = @"InteruptabilityLevel";
NSString *const kActivity = @"CurrentActivity";
NSString *const kTaskAcceptance = @"TaskAcceptance";
NSString *const kTaskChoice = @"TaskChoice";
NSString *const kTime = @"TimeToProceed";

@implementation SurveyViewController

@synthesize onePointLocation;
@synthesize locationDictionary;

- (id)init
{
    self = [super init];

    if (self) {
        locationDictionary = [[NSMutableDictionary alloc] init];
        
        [self initializeForm];
        [self initLocationManager];
        [onePointLocation startUpdatingLocation];
        [[ActivitySingleton sharedActivitySingleton] notificationPopped];
        
        [[ActivitySingleton sharedActivitySingleton] setCanSurveyPop:NO];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self){
        locationDictionary = [[NSMutableDictionary alloc] init];
        
        [self initializeForm];
        [self initLocationManager];
        [onePointLocation startUpdatingLocation];
        [[ActivitySingleton sharedActivitySingleton] notificationPopped];
        
        [[ActivitySingleton sharedActivitySingleton] setCanSurveyPop:NO];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        
        locationDictionary = [[NSMutableDictionary alloc] init];
        
        [self initializeForm];
        [self initLocationManager];
        [onePointLocation startUpdatingLocation];
        [[ActivitySingleton sharedActivitySingleton] notificationPopped];
        
        [[ActivitySingleton sharedActivitySingleton] setCanSurveyPop:NO];
    }
    return self;
}

- (void)initLocationManager
{
    NSLog(@"location init");
    onePointLocation = [[CLLocationManager alloc] init];
    
    // Check if the device is iOS 8
    if(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
        [onePointLocation requestAlwaysAuthorization];
    
    [onePointLocation setDelegate:self];
    [onePointLocation setDistanceFilter:5];
    onePointLocation.desiredAccuracy = kCLLocationAccuracyBest;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [onePointLocation stopUpdatingLocation];
}

#pragma mark - Form initialization

- (void)initializeForm
{
    XLFormDescriptor *form;
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:@"Survey"];
    
    // First section
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // Interuptability
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kInteruptability rowType:XLFormRowDescriptorTypeSlider title:@"Interuptability level"];
    row.value = @(5);
    [row.cellConfigAtConfigure setObject:@(10) forKey:@"slider.maximumValue"];
    [row.cellConfigAtConfigure setObject:@(0) forKey:@"slider.minimumValue"];
    [row.cellConfigAtConfigure setObject:@(0) forKey:@"steps"];
    [section addFormRow:row];
    
    // Activity
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kActivity rowType:XLFormRowDescriptorTypeSelectorSegmentedControl title:@"What's your current state?"];
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(-1) displayText:@"None"];
    row.selectorTitle = @"What's your current state?";
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(0) displayText:@"Driving"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:@"Biking"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:@"Walking"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(3) displayText:@"Working"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(4) displayText:@"Bored"],
                            ];
    [section addFormRow:row];
    
    // Second section
    section = [XLFormSectionDescriptor formSectionWithTitle:@" "];
    [form addFormSection:section];
    
    // Task Acceptance
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kTaskAcceptance rowType:XLFormRowDescriptorTypeBooleanSwitch title:@"Take a task?"];
    
    [section addFormRow:row];
    
    // Task
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kTaskChoice rowType:XLFormRowDescriptorTypeSelectorAlertView title:@"What task?"];
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(0) displayText:@"Pick up mail/package"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:@"Send mail/package"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:@"Groceries"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(3) displayText:@"Offer a lift"],
                            ];
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(-1) displayText:@"Choose"];
    [section addFormRow:row];
    
    // Time
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kTime rowType:XLFormRowDescriptorTypeSelectorAlertView title:@"How long?"];
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(0) displayText:@"0 min"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:@"15 min"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:@"30 min"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(3) displayText:@"45 min"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(4) displayText:@"1 hour"],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(5) displayText:@"More"],
                            ];
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(-1) displayText:@"Choose"];
    [section addFormRow:row];
    
    self.form = form;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(sendSurvey:)];
}

- (IBAction)sendSurvey:(id)sender
{
    Survey *survey = [[Survey alloc] init];
    Boolean isUserAvailable = NO;
    
    // Check sections
    for (XLFormSectionDescriptor * section in self.form.formSections) {
        if (!section.isMultivaluedSection){
            // Check rows in section
            for (XLFormRowDescriptor * row in section.formRows) {
                if (row.tag && ![row.tag isEqualToString:@""]){
                    if (![[row.value valueData] isEqualToNumber:@(-1)])
                    {
                        if ([[row tag] isEqualToString:kInteruptability])
                            [survey setInteruptability:(int)[[row.value valueData] integerValue]];
                        else
                        if ([[row tag] isEqualToString:kActivity])
                        {
                            // Check each option in selector
                            for (XLFormOptionsObject *item in row.selectorOptions)
                                if ([item valueData] == [row.value valueData])
                                {
                                    [survey setCurrentState:[[row value] displayText]];
                                    break;
                                }
                        }
                        else
                        if ([[row tag] isEqualToString:kTaskAcceptance])
                        {
                            if ([[row.value valueData] boolValue] == YES)
                            {
                                [survey setAvailability:@"True"];
                                isUserAvailable = YES;
                            }
                            else
                            {
                                [survey setAvailability:@"False"];
                                isUserAvailable = NO;
                            }
                        }
                        else
                        if ([[row tag] isEqualToString:kTaskChoice])
                        {
                            for (XLFormOptionsObject *item in row.selectorOptions)
                                if ([item valueData] == [row.value valueData])
                                    [survey setTaskSelected:[[row value] displayText]];
                        }
                        else
                        if ([[row tag] isEqualToString:kTime])
                        {
                            for (XLFormOptionsObject *item in row.selectorOptions)
                                if ([item valueData] == [row.value valueData])
                                    [survey setTaskTime:[[row value] displayText]];
                        }
                    }
                    // Check if one of the selector is untouched
                    else
                    {
                        if ([[row tag] isEqualToString:kActivity])
                        {
                            [self uncompleteSurveyAlertWithMessage:@"Please fill in your current activity."];
                            return;
                        }
                        else
                        if ([[row tag] isEqualToString:kTaskChoice])
                        {
                            if (isUserAvailable)
                            {
                                [self uncompleteSurveyAlertWithMessage:@"Please provide an activity."];
                                return;
                            }
                            else
                                continue;
                        }
                        else
                        if ([[row tag] isEqualToString:kTime])
                        {
                            if (isUserAvailable)
                            {
                                [self uncompleteSurveyAlertWithMessage:@"Please provide a duration."];
                                return;
                            }
                            else
                                continue;
                        }
                    }
                }
            }
        }
    }
    
    NSLog(@"Survey task : %@", [survey taskSelected]);
    NSLog(@"Creating URL");
    NSString *URL = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"SERVER_ADDRESS", nil), NSLocalizedString(@"SURVEY_URL", nil)];
    
    NSDictionary *resultDict = [[NSDictionary alloc] initWithObjectsAndKeys:[self fillDictionaryWithSurvey:survey], @"survey",
                                                                            locationDictionary, @"location", nil];
    
    [[ActivitySingleton sharedActivitySingleton] uploadToServerWithURL:URL andDict:resultDict];
    
    // Reset LocationReminder timer
    [[ActivitySingleton sharedActivitySingleton]restartLocationReminderTimer];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate backToHome];
    
    // Puts application in background
    UIApplication *app = [UIApplication sharedApplication];
    [app performSelector:@selector(suspend)];
}

// Fills a dict with survey's parameters
- (NSDictionary *)fillDictionaryWithSurvey:(Survey*)survey
{
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[[ActivitySingleton sharedActivitySingleton] userToken], @"userToken",
                          [NSString stringWithFormat:@"%d", [survey interuptability]], @"interuptability",
                          [survey currentState], @"currentState",
                          [survey availability], @"availability",
                          [survey taskSelected], @"taskSelected",
                          [survey taskTime], @"taskTime",
                          [locationDictionary objectForKey:@"timestamp"], @"timestamp",
                          nil];

    return dict;
}

// Shows Alert View with custom message
- (void)uncompleteSurveyAlertWithMessage:(NSString*)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incomplete survey"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *currentLocation = [locations objectAtIndex:[locations count] - 1];
    NSDate *timestamp = [currentLocation timestamp];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]];
    float longitude = [currentLocation coordinate].longitude;
    float latitude = [currentLocation coordinate].latitude;
    
    [locationDictionary setObject:[[ActivitySingleton sharedActivitySingleton] userToken] forKey:@"userToken"];
    [locationDictionary setObject:[[NSNumber numberWithFloat:latitude] stringValue] forKey:@"latitude"];
    [locationDictionary setObject:[[NSNumber numberWithFloat:longitude] stringValue] forKey:@"longitude"];
    [locationDictionary setObject:[[ActivitySingleton sharedActivitySingleton] userState] forKey:@"userState"];
    [locationDictionary setObject:[dateFormatter stringFromDate:timestamp] forKey:@"timestamp"];
}

@end
