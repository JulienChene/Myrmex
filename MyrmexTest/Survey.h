//
//  Survey.h
//  MyrmexTest
//
//  Created by Julien Chene on 25/09/14.
//  Copyright (c) 2014 JulienChene. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Survey : NSObject

@property (assign) int                  interuptability;
@property (strong, nonatomic) NSString  *currentState;
@property (strong, nonatomic) NSString  *availability;
@property (strong, nonatomic) NSString  *taskSelected;
@property (strong, nonatomic) NSString  *taskTime;

@end
