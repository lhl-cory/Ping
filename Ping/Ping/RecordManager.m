//
//  RecordManager.m
//  Ping
//
//  Created by Martin Zhang on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "RecordManager.h"

#define TIME_INTERVAL 10 *60

@interface RecordManager ()

@property (nonatomic, strong) NSOperationQueue * readQueue;
@property (nonatomic, strong) NSOperationQueue * writeQueue;

@property (nonatomic, strong) RLMRealm * readRealm;
@property (nonatomic, strong) RLMRealm * writeRealm;

@end

@implementation RecordManager

- (instancetype)init
{
    self = [super init];
    if (self) {
// No need to init RLMArray?
//        self.timePeriods = [[RLMArray alloc] init];
        self.timePeriods = [NSMutableArray array];
        
        // initialize read/write queues
        self.readQueue = [[NSOperationQueue alloc] init];
        self.writeQueue = [[NSOperationQueue alloc] init];
        
        // initialize read/write realms
        RLMRealmConfiguration *defaultConfiguration = [RLMRealmConfiguration defaultConfiguration];
        [self.readQueue addOperationWithBlock:^{
            NSError *error = nil;
            self.readRealm = [RLMRealm realmWithConfiguration:defaultConfiguration error:&error];
        }];
        
        [self.writeQueue addOperationWithBlock:^{
            NSError *error = nil;
            self.writeRealm = [RLMRealm realmWithConfiguration:defaultConfiguration error:&error];
        }];
    }
    return self;
}

// convert userProximity string into a int 

-(void)storeBlueToothDataByUUID:(NSString *)userUUID userProximity:(int)proximity andTime:(NSDate *)time {

    TimePeriod *previousTimePeriod = [self.timePeriods lastObject];
    if (previousTimePeriod == nil) {
        [self generateNewTimePeriodAndUserRecordWithUserUUID:userUUID proximity:proximity andTime:time];
    } else {
        NSDate *endTime = [previousTimePeriod.startTime dateByAddingTimeInterval:TIME_INTERVAL];
       
        if ([time timeIntervalSinceReferenceDate] > [previousTimePeriod.startTime timeIntervalSinceReferenceDate] && [time timeIntervalSinceReferenceDate] < [endTime timeIntervalSinceReferenceDate]) {
            
            BOOL foundUser = NO;
            for (UserRecord *aUser in previousTimePeriod.userRecords) {
                if ([aUser.uUID isEqualToString: userUUID]) {
                    [self increaseUserTotalDistanceAndObs:aUser userProximity:proximity];
                    foundUser = YES;
                }
            }
            
            if (foundUser == NO) {
                UserRecord *newRecord = [[UserRecord alloc] initWithUUID:userUUID andDistance:proximity];
                [previousTimePeriod.userRecords addObject:newRecord];
            }
        }
        
        else if ([time timeIntervalSinceReferenceDate] > [endTime timeIntervalSinceReferenceDate]) {
            [self generateNewTimePeriodAndUserRecordWithUserUUID:userUUID proximity:proximity andTime:time];
        }
    }
    NSLog(@"The current time period: %@. The user's UUID: %@. Total distance: %d. Number of obs: %d.", [[self.timePeriods lastObject] startTime], [[[[self.timePeriods lastObject] userRecords]lastObject]uUID], [[[[self.timePeriods lastObject] userRecords]lastObject]totalDistance], [[[[self.timePeriods lastObject] userRecords]lastObject]numberOfObs]);
    [self persistToDefaultRealm];
}

-(void)generateNewTimePeriodAndUserRecordWithUserUUID:(NSString *)uUID proximity:(int)proximity andTime:(NSDate *)time {
    TimePeriod *newTimePeriod = [[TimePeriod alloc] init];
    newTimePeriod.startTime = [self getStartTimeForTimePeriod:time];
    [self.timePeriods addObject:newTimePeriod];
    UserRecord *newUserRecord = [[UserRecord alloc] initWithUUID:uUID andDistance:proximity];
    [newTimePeriod.userRecords addObject:newUserRecord];
}

-(void)increaseUserTotalDistanceAndObs:(UserRecord *)userRecord userProximity:(int)proximity {
    userRecord.totalDistance += proximity;
    userRecord.numberOfObs ++;
}

-(NSDate *)getStartTimeForTimePeriod:(NSDate *)time{
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]; // get calander
    NSDateComponents *newDateComponenet = [[NSDateComponents alloc] init]; // create new component
    
    NSDateComponents *minComponent = [cal components:(NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitNanosecond) fromDate:time]; // get the components from time passed in
    
    // flip sign on seconds and nanoseconds (this will zero out these values)
    newDateComponenet.second = (-1)*minComponent.second;
    newDateComponenet.nanosecond = (-1)*minComponent.nanosecond;
    // round down the minutes
    newDateComponenet.minute = (-1) * (minComponent.minute %10);
    
    // apply the adjusted components to the passed in date to return the new date
    return [cal dateByAddingComponents:newDateComponenet toDate:time options:0];
    
}

-(void)persistToDefaultRealm {
    
    [self.writeQueue addOperationWithBlock:^{
//        RLMRealm *defaultRealm = [RLMRealm defaultRealm];
        [self.writeRealm beginWriteTransaction];
        [self.writeRealm addObjects:self.timePeriods];
        [self.writeRealm commitWriteTransaction];
    }];

//    [self.readQueue addOperationWithBlock:^{
//        <#code#>
//    }];
}

@end





