//
//  UserRecord.h
//  Ping
//
//  Created by Martin Zhang on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import <Realm/Realm.h>

@interface UserRecord : RLMObject

@property (nonatomic) NSString *uUID;
@property (nonatomic) int totalDistance;
@property (nonatomic) int numberOfObs;

- (instancetype)initWithUUID:(NSString *)uUID andDistance:(int)distance;

@end
