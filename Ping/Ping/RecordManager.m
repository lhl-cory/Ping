//
//  RecordManager.m
//  Ping
//
//  Created by Martin Zhang on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "RecordManager.h"
#import "AverageUUidDuple.h"
#import "User.h"
#import "CurrentUser.h"

#define TIME_INTERVAL 10 * 60

@interface RecordManager ()

@property (strong) RLMArray<User *><User> *users;

@end

@implementation RecordManager

- (dispatch_queue_t)backgroundQueue {
    static dispatch_once_t queueCreationGuard;
    static dispatch_queue_t queue;
    dispatch_once(&queueCreationGuard, ^{
        queue = dispatch_queue_create("com.tomm.Ping.backgroundQueue", 0);
    });
    return queue;
}


#pragma mark - BlueTooth Montioring Methods

// convert userProximity string into a int
// CR: perisistUUID:proximity:andTime:
// CR: the record manager should probably not contain the word "bluetooth" anywhere
-(void)storeBlueToothDataByUUID:(NSString *)userUUID userProximity:(int)proximity andTime:(NSDate *)time {
    dispatch_queue_t queue = self.backgroundQueue;
    dispatch_async(queue, ^{
        @synchronized (self) {
            RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
            [backgroundRealm transactionWithBlock:^{
                
                RLMResults<Event *> *currentEvents = [Event objectsWhere:@"startTime <= %@ AND endTime >= %@", time, time];
                
                // If we are in the current surroundings screen and don't have an event, we better create one
                if ([currentEvents count] == 0 ) {
                    Event *rightNow = [[Event alloc] init];
                    rightNow.startTime = [self getStartTimeForTimePeriod:[NSDate date]];
                    NSTimeInterval oneHour = 60 * 60;
                    
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
                    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
                    
                    rightNow.endTime = [rightNow.startTime dateByAddingTimeInterval:oneHour];
                    rightNow.eventName = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:rightNow.startTime]];
                    rightNow.hostName = @"";
                    
                    [[CurrentUser getCurrentUser].events addObject:rightNow];
                    
                }
                // CR: This method is too long. simplify or break into separate private methods.
                
                // add records to each current event
                for (Event *currentEvent in currentEvents) {
                    
                    RLMResults<TimePeriod *> *timePeriods = [currentEvent.timePeriods objectsWhere:@"startTime == %@", [self getStartTimeForTimePeriod:time]];
                    
                    if ([timePeriods count] == 0) { // Didn't find a time Period for this time, lets make one!
                        TimePeriod *newTimePeriod = [[TimePeriod alloc] init];
                        UserRecord *newUserRecord = [[UserRecord alloc] initWithUUID:userUUID andDistance:proximity];
                        
                        newTimePeriod.startTime = [self getStartTimeForTimePeriod:time];
                        [newTimePeriod.userRecords addObject:newUserRecord];
                        [currentEvent.timePeriods addObject:newTimePeriod];
                        
                    } else {
                        // Otherwise add this record to the current time period
                        RLMResults<TimePeriod *> *possibletimePeriods = [timePeriods objectsWhere:@"startTime >= %@", [time dateByAddingTimeInterval:-TIME_INTERVAL]]; //effectively if time >endTime
                        
                        if ([possibletimePeriods count] >= 1) { // we found our timePeriod, Horray!!
                            TimePeriod *previousTimePeriod = [timePeriods firstObject];
                            
                            BOOL foundUser = NO;
                            
                            for (int i = 0; i < previousTimePeriod.userRecords.count; i++) { // find the reccord for this user and add
                                UserRecord *aUserRec = previousTimePeriod.userRecords[i];
                                
                                if ([aUserRec.UUID isEqualToString:userUUID]) {
                                    aUserRec.totalDistance += proximity;
                                    aUserRec.numberOfObs ++;
                                    foundUser = YES;
                                }
                            }
                            
                            
                            if (foundUser == NO) {
                                UserRecord *newRecord = [[UserRecord alloc] initWithUUID:userUUID andDistance:proximity];
                                [previousTimePeriod.userRecords addObject:newRecord];
                            }
                        } else  { // Wow, we are passed the end time for this time interval, beter create a new one
                            TimePeriod *newTimePeriod = [[TimePeriod alloc] init];
                            UserRecord *newUserRecord = [[UserRecord alloc] initWithUUID:userUUID andDistance:proximity];
                            
                            newTimePeriod.startTime = [self getStartTimeForTimePeriod:time];
                            [newTimePeriod.userRecords addObject:newUserRecord];
                            [currentEvent.timePeriods addObject:newTimePeriod];
                        }
                    }
                }
                
            }];
            
        }
    });
}

- (NSDate *)getStartTimeForTimePeriod:(NSDate *)time{
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

- (NSArray<NSString *> *)UUIDsSortedAtTime:(NSDate *)date; {
    
    date = [self getStartTimeForTimePeriod:date]; // rounds down to correct start date
    
    for (TimePeriod *tp in [TimePeriod allObjects]) {
        if ([date compare:tp.startTime] == NSOrderedSame) { // This is the time period you are looking for
            NSMutableArray *userRecordsArrayInTimePeriod = [[NSMutableArray alloc] init];
            
            for (UserRecord *aUserRecord in tp.userRecords) {
                AverageUUidDuple *duple = [AverageUUidDuple new];
                duple.userAverage = aUserRecord.totalDistance / aUserRecord.numberOfObs;
                duple.UUID = aUserRecord.UUID;
                [userRecordsArrayInTimePeriod addObject:duple];
            }
            
            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"userAverage" ascending:NO];
            userRecordsArrayInTimePeriod = [[userRecordsArrayInTimePeriod sortedArrayUsingDescriptors:@[descriptor]] mutableCopy];
            
            NSMutableArray *uuidArray = [NSMutableArray new];
            for (AverageUUidDuple *dup in userRecordsArrayInTimePeriod) {
                [uuidArray addObject:dup.UUID];
            }
            
            return [uuidArray copy];
        }
    }
    return nil;
}

- (void)backUpUsers:(NSMutableArray *)users {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    for (User *user in users) {
        
        [realm beginWriteTransaction];
        [realm addObject:user];
        [realm commitWriteTransaction];
    }
}

- (NSArray *)uuidList {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    RLMResults<User *> *users = [User allObjects];
    for (User *user in users) {
        NSString *uuidString = user.UUID;
        [array addObject:uuidString];
    }
    return [array copy];
}

- (void)deleteEvent:(Event *)event {
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm transactionWithBlock:^{
        
        // ToDo add checking mechanism to check if realm already contains event
        
        [realm deleteObject:event];
        
    }];
}

@end
