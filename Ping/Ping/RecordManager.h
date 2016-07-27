//
//  RecordManager.h
//  Ping
//
//  Created by Martin Zhang on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimePeriod.h"

@interface RecordManager : NSObject

@property (nonatomic) NSMutableArray *timePeriods;

-(void)storeBlueToothDataByUUID:(NSString *)userUUID userProximity:(NSString *)proximity andTime:(NSString *)time;

@end
