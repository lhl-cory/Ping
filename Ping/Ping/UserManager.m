//
//  UserManager.m
//  Ping
//
//  Created by thomas minshull on 2016-07-27.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "UserManager.h"
#import "CurrentUser.h"
#import "ParseUser.h"
#import <Parse/Parse.h>
#import "Ping-Swift.h"
#import "RecordManager.h"

@interface UserManager ()

@property (strong, nonatomic) NSMutableSet *parseUsers;

@end

@implementation UserManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.parseUsers = [NSMutableSet new];
    }
    return self;
}

- (void)fetchUsersWthCompletion:(void(^)(NSArray *users))completion {
    
    PFQuery *query = [PFQuery queryWithClassName:@"ParseUser"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        RecordManager *recMan = [RecordManager new];
        if (error) {
            NSLog(@"error retreiving users from parse ERROR: %@", error);
        } else {
            NSMutableArray *users = [NSMutableArray new];
            
            for (PFObject *parseUser in objects) {
                [self.parseUsers addObject:parseUser];
                
                User *user = [self userFrom:parseUser];
                [users addObject:user];
            }
            [recMan backUpUsers:[users copy]];
            
        }
        NSArray *uuidList = [recMan uuidList];
        completion(uuidList);
    }];
}

- ( User * _Nullable )userForUUID:(NSString *)uuid {
    // CR: PFObject??
    for (PFObject *parseUser in self.parseUsers) {
        if ([parseUser[@"UUID"] isEqualToString:uuid]) {
            User *user =[self userFrom:parseUser];
            return user;
        }
    }
    return nil;
}

- (User *)userFrom:(PFObject *)parseUser {
    // CR: PFObject??
    // copy parse user as regular user
    User *user = [[User alloc] init];
    user.firstName = parseUser[@"firstName"]; // ToDo these parse getters will return nil if the there is an error wrap them in nil checks and replace with empty strings 
    user.lastName = parseUser[@"lastName"];
    user.headline = parseUser[@"headline"];
    user.linkedInID = parseUser[@"linkedInID"];
    user.UUID = parseUser[@"UUID"];
    user.profilePicURL = parseUser[@"profilePicURL"];
    return user;
}

- (void)addProfilePic:(NSString *)profilePicURL {
    if (profilePicURL) {
        PFQuery *query = [PFQuery queryWithClassName:@"ParseUser"];
        [query whereKey:@"UUID" equalTo:[CurrentUser getCurrentUser].UUID];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFObject *currentParseUser = [objects firstObject];
                currentParseUser[@"profilePicURL"] = profilePicURL;
                [currentParseUser saveInBackground];
            } else {
                NSLog(@"Error when saving profile pic to parse: %@", error);
            }
        }];
    }
}


@end
