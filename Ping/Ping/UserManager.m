//
//  UserManager.m
//  Ping
//
//  Created by thomas minshull on 2016-07-27.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "UserManager.h"
#import "CurrentUser.h"
#import <Parse/Parse.h>
#import "Ping-Swift.h"

@interface UserManager ()

//@property (nonatomic) BOOL temp;
@property (strong, nonatomic)NSMutableSet __block *users;
@end

@implementation UserManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp {
    
    // get user from parse
    // populate user list
    // populate uuid list
    
    PFQuery *query = [PFQuery queryWithClassName:@"User"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error retreiving users from parse ERROR: %@", error);
        } else {
            self.users = [NSMutableSet new];
            self.uuids = [NSMutableArray new];
            
            for (PFObject *user in objects) {
                [self.users addObject:(User *)user]; // is this going to work?
                [self.uuids addObject:[user objectForKey:@"UUID"]];
            }
        }
        
    }];
    
//        User *user1 = [User new];
//        user1.firstName = @"Martin";
//        user1.lastName = @"Zhang";
//        user1.headline = @"stuff";
//        user1.linkedInID = @"stuff";
//        user1.profilePicURL = @"https://media.licdn.com/mpr/mprx/0_toKw915dIk5rEJF8OU6IYKyHoARu2R5ygUeLKQodo1eD2INKgU6w41kdDkBD2Ib3YUEQ4FFWF1eS7xzKjMvBOF65C1e270r2RMvez61eW-g85dIKBHi6vtjMGQtp60bjtVAbtqut7mP";
//        
//        
//        self.uuids = [@[@"FEBAA2DD-CE1A-4125-96D0-097DFD047E83", @"0D623438-99D7-4B39-B6BB-03936A6B379B",@"C826D6CF-E64B-4159-8B6F-FCE60C18C12D",@"71C12256-AFE6-4D3D-9E5A-1B0E6ED0CB8F",@"19A86001-A1B4-44DE-879B-F9FD6B7D945F",@"84241393-5155-4307-B5F6-38C013447E02",@"FB2165CD-B0FF-4F96-87AB-C9BC6C3851BE",@"8E88F0CC-C79F-46E8-B323-C06DB3ED32E5"] mutableCopy];

 
}

- (User *)userForUUID:(NSString *)uuid {
    
    for (User *user in self.users) {
        if ([user.UUID isEqualToString:uuid]) {
            return user;
        }
    }
    return nil;
}

@end
