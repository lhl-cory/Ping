//
//  RecordManager.h
//  Ping
//
//  Created by Martin Zhang on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimePeriod.h"
#import "UserRecord.h"
#import "Event.h"

@interface RecordManager : NSObject

@property (strong, nonatomic) dispatch_queue_t backgroundQueue;

- (void)storeBlueToothDataByUUID:(NSString *)userUUID userProximity:(int)proximity andTime:(NSDate *)time;
- (NSArray<NSString *> *)UUIDsSortedAtTime:(NSDate *)date;
- (NSDate *)getStartTimeForTimePeriod:(NSDate *)time; // CR: in general, get sucks as a prefix for method names. This method could be called startTimeForTimePeriod.
- (void)backUpUsers:(NSMutableArray *)users; // CR: unless you're using mutability, don't pass arrays around as mutable. can change to NSArray without pain.
- (NSArray *)uuidList;
- (void)deleteEvent:(Event *)event;

@end
