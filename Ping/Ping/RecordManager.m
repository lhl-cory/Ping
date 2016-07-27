//
//  RecordManager.m
//  Ping
//
//  Created by Martin Zhang on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "RecordManager.h"

#define TIME_INTERVAL 30

@implementation RecordManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timePeriods = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)storeBlueToothDataByUUID:(NSString *)userUUID userProximity:(NSString *)proximity andTime:(NSString *)time {

    TimePeriod *previousTimePeriod = [self.timePeriods lastObject];
    if (previousTimePeriod == nil /* Or the time parameter is not in the prvious time period */) {
        
    }
    
}


@end
