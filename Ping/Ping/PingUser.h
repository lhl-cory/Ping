//
//  User.h
//  Ping
//
//  Created by thomas minshull on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PingUser : NSObject

@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *headline;
@property (strong, nonatomic) NSString *linkedInID;
@property (strong, nonatomic) NSString *profilePicURL;
//@property (strong, nonatomic) NSDictionary *profileRequest;

@property (strong, nonatomic) NSString *userUUID;

// CR: why not an init method?
- (void)setPropertiesWithProfileDictionary:(NSDictionary *)dic;

@end
