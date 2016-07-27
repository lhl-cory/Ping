//
//  UserRecord.m
//  Ping
//
//  Created by Martin Zhang on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "UserRecord.h"

@implementation UserRecord

- (instancetype)initWithUUID:(NSString *)uUID andDistance:(int)distance
{
    self = [super init];
    if (self) {
        self.uUID = uUID;
        self.totalDistance = distance;
        self.numberOfObs = 1;
    }
    return self;
}

-(void)setTotalDistance:(int)totalDistance {
    _totalDistance = abs(totalDistance);
}

@end
