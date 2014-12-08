//
//  Survey.m
//  MyrmexTest
//
//  Created by Julien Chene on 25/09/14.
//  Copyright (c) 2014 JulienChene. All rights reserved.
//

#import "Survey.h"

@implementation Survey

@synthesize interuptability;
@synthesize currentState;
@synthesize availability;
@synthesize taskSelected;
@synthesize taskTime;

- (id)init
{
    self = [super init];
    if (self)
    {
        interuptability = 0;
        currentState = @"";
        availability = @"";
        taskSelected = @"";
        taskTime = @"";
    }
    
    return self;
}

@end
