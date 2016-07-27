//
//  TimePeriod.h
//  Ping
//
//  Created by Martin Zhang on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import <Realm/Realm.h>
#import "UserRecord.h"

RLM_ARRAY_TYPE(UserRecord)

@interface TimePeriod : RLMObject

@property (nonatomic) NSDate *startTime;
@property (nonatomic) RLMArray<UserRecord *><UserRecord> *userRecords;

@end
