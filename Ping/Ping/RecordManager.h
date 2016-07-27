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

//RLM_ARRAY_TYPE(TimePeriod)

@interface RecordManager : NSObject

@property (nonatomic) NSMutableArray *timePeriods;

-(void)storeBlueToothDataByUUID:(NSString *)userUUID userProximity:(int)proximity andTime:(NSDate *)time;
-(NSDate *)getStartTimeForTimePeriod:(NSDate *)time;
-(void)increaseUserTotalDistanceAndObs:(UserRecord *)userRecord userProximity:(int)proximity;
-(void)persistToDefaultRealm;

@end
