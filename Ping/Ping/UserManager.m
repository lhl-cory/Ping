//
//  UserManager.m
//  Ping
//
//  Created by thomas minshull on 2016-07-27.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "UserManager.h"
#import <linkedin-sdk/LISDK.h>
#import "PingUser.h"
#import "CurrentUser.h"
#import "Backendless.h"
#import "PingUserRealm.h"

#import "AppDelegate.h"

#define LINKEDIN_USER_URL @"https://api.linkedin.com/v1/people/~"
#define LINKEDIN_ADDITIONAL_INFO_URL @"https://api.linkedin.com/v1/people/~:(id,num-connections,picture-url)?format=json"

@interface UserManager ()

@property (nonatomic) BOOL temp;
@property (nonatomic) RLMRealm *currentRealmUser;

@end


@implementation UserManager

+ (instancetype)sharedUserManager {
    static UserManager *sharedUserManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedUserManager = [[UserManager alloc] init];
        sharedUserManager.userList = [NSMutableSet new];
        // CR: this line probably belongs in init, esp if multiple initial values set
        
//        sharedUserManager.currentUser = [PingUser new];
//        sharedUserManager.temp = false;
    });
    
//    [sharedUserManager updateUserList];
    
    return sharedUserManager;
}

- (void)setUp {
    // get latest userList
    id<IDataStore> dataStore = [backendless.persistenceService of:[PingUser class]];
    
    @try {
        BackendlessCollection *backendlessUserListCollection = [dataStore find];
        // set page size to include the whole list of objects because backendless's pagination sucks!
        // ToDo fix pagination so it works properly
        [backendlessUserListCollection pageSize:[[backendlessUserListCollection getTotalObjects] integerValue]];
        
        NSArray *backendlessUserList = [backendlessUserListCollection getCurrentPage];
        
        NSMutableArray *uuidList = [NSMutableArray new];
        for (PingUser *u in backendlessUserList) {
            [self.userList addObject:u];
            [uuidList addObject:u.userUUID];
        }
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        self.blueToothManager = [BlueToothManager sharedrecordManager:[uuidList copy] andCurrentUUID:app.currentUser.userUUID];
//        self.blueToothManager = [BlueToothManager sharedrecordManager:@[@"E20A39F4-73F5-4BC4-A12F-17D1AD07A961", @"1C6AAE1E-E4D1-42CB-A642-0856C315A75F", @"F124015B-5AF2-4969-A7A0-38BF2759600F"] andCurrentUUID:@"1C6AAE1E-E4D1-42CB-A642-0856C315A75F"];
    } @catch (Fault *fault) {
        NSLog(@"Server reported an error: %@", fault);
    }
}

- (PingUser *)userForUUID:(NSString *)uuid {
    
    for (PingUser *user in self.userList) {
        if ([user.userUUID isEqualToString:uuid]) {
            return user;
        }
    }
    return nil;
}

- (void)updateProfilePicForUser:(PingUser *)user {
    [self setProfilePicForUser:user WithCompletion:nil];
    
}


#pragma  mark -Loggin Methods 

- (BOOL)previouslyLoggedIn {
    //query keychain
    
    NSMutableDictionary *query = [@{
                                    (__bridge id)kSecReturnAttributes : (__bridge id)kCFBooleanTrue,
                                    (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitAll,
                                    (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                    (__bridge id)kSecReturnData : (__bridge  id)kCFBooleanTrue
                                    } mutableCopy];
    
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    NSLog(@"%@", (__bridge id)result);
    
    if (result != NULL) { // We found the key, maybe we should check it
        return YES; // Nahh never mind :P
        
//              [self createNewSessionWithoutNewUsers];
    }
    return NO;
    
    /* ToDo Unfinished Code used to validate the key and create new session 
     NSArray *resultArray = (__bridge_transfer NSArray *)result;
     NSDictionary *resultDict = [resultArray firstObject];
     NSData *pswd = resultDict[(__bridge id)kSecValueData];
     NSString *password = [[NSString alloc] initWithData:pswd encoding:NSUTF16StringEncoding];
     
     NSLog(@"serialized token: %@", password);
     //CFRelease(result);
     
     
     [LISDKSessionManager createSessionWithAccessToken:[LISDKAccessToken LISDKAccessTokenWithSerializedString:password]];
     
     [self createNewSession];
     
     NSLog(@"ACcess tokens %@ ::::: %@",[[LISDKSessionManager sharedInstance].session.accessToken serializedString], password);
     */
}


- (void)createNewSessionWithoutNewUsersWithCompletion:(void(^)())completion {
    [LISDKSessionManager createSessionWithAuth:@[LISDK_BASIC_PROFILE_PERMISSION] state:@"login with button" showGoToAppStoreDialog:YES successBlock:^(NSString *state) {
        NSLog(@"Success Segue to new screen");
        completion();
    } errorBlock:^(NSError *error) {
        NSLog(@"Error when logging in with LinkedIn %@", error);
        //ToDo display error message to user
        
    }];
}


- (void)createUserWithCompletion:(void(^)())completion {

        [[LISDKAPIHelper sharedInstance] getRequest:LINKEDIN_USER_URL
                                            success:^(LISDKAPIResponse *response) {
                                                NSLog(@"got user profile: %@", response.data);
                                                
                                                PingUser *selfUser = [self createUserWithResponseString:response.data];
                                                NSLog(@"self user uuid: %@", selfUser.userUUID);
                                                
                                                AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                                
                                                app.currentUser = selfUser;
                                                
                                                // Add Profile Pic
                                                
                                                __weak UserManager *weakSelf = self;
                                                [self setProfilePicForUser:selfUser WithCompletion:^{
                                                    
                                                    [weakSelf saveBackendlessUser:selfUser];
                                                    // save to realm as current user
                                                    [weakSelf persistCurrentUserToRealm:selfUser];
                                                }];
                                                
                                                completion();
                                            }
                                              error:^(LISDKAPIError *apiError) {
                                                  // do something with error
                                                  NSLog(@"Failed to get user profile: %@", apiError);
                                                  
                                                  //ToDo display error
                                              }];
}

- (PingUser *)createUserWithResponseString:(NSString *)response {
    NSData *responseData = [response dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *jsonError;
    
    NSDictionary *myProfile = [NSJSONSerialization JSONObjectWithData:responseData
                                                              options:NSJSONReadingMutableContainers
                                                                error:&jsonError];
    
    PingUser *selfUser = [[PingUser alloc] init];
    [selfUser setPropertiesWithProfileDictionary:myProfile];
    
    return selfUser;
}

- (void)setProfilePicForUser:(PingUser *)user WithCompletion:(void(^)())completion {
    [[LISDKAPIHelper sharedInstance] getRequest:LINKEDIN_ADDITIONAL_INFO_URL success:^(LISDKAPIResponse *response) {
        NSLog(@"successfully retrieved profile pic with response: %@", response.data);
        
        NSData *profilePicResponse = [response.data dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *picError;
        NSDictionary *myPic = [NSJSONSerialization JSONObjectWithData:profilePicResponse
                                                              options:NSJSONReadingMutableContainers
                                                                error:&picError];
        NSString *picURl = myPic[@"pictureUrl"];
        
        user.profilePicURL = picURl;
        
        completion();
    
    } error:^(LISDKAPIError *error) {
        NSLog(@"Error when loading profile Pic: %@", error);
        completion();
    }];
}

#pragma mark - Backendless Methods

- (void)saveBackendlessUser:(PingUser *)user {
    id<IDataStore> dataStore = [backendless.persistenceService of:[PingUser class]];
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [dataStore save:user];
             });
    
    Fault *fault;
    BackendlessCollection *collection = [dataStore findFault:&fault];
    NSLog(@"log global list of users: %@", collection);
}

- (void)loginAndCreateNewUserWithCompletion:(void(^)())completion {
    [LISDKSessionManager createSessionWithAuth:@[LISDK_BASIC_PROFILE_PERMISSION] state:@"login with button" showGoToAppStoreDialog:YES successBlock:^(NSString *state) {
        NSLog(@"Success Segue to new screen");
        
        // ToDo am I a new user? check realm for currentUser
        
        
        // if currentUser does not exist in realm
        [self createUserWithCompletion:completion];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"Error when logging in with LinkedIn %@", error);
        
        //ToDo display error message to user
        
    }];
}


- (void)persistCurrentUserToRealm:(PingUser *)currentUser {
    // wrap in queue ?
    self.currentRealmUser = [RLMRealm defaultRealm];
    PingUserRealm *pingUserForRealm = [[PingUserRealm alloc] initWithPingUserValue:currentUser];
    [self.currentRealmUser beginWriteTransaction];
    [self.currentRealmUser deleteAllObjects];
    [self.currentRealmUser addObject:pingUserForRealm];
    [self.currentRealmUser commitWriteTransaction];
}

- (PingUser *)fetchCurrentUserFromRealm {
    if (![self.currentRealmUser isEmpty]) {
        RLMResults<PingUserRealm *> *userResult = [PingUserRealm allObjects];
        PingUserRealm *userFromRealm = [userResult firstObject];
        PingUser *user = [[PingUser alloc] init];
        user.firstName = userFromRealm.firstName;
        user.lastName = userFromRealm.lastName;
        user.headline = userFromRealm.headline;
        user.linkedInID = userFromRealm.linkedInID;
        user.profilePicURL = userFromRealm.profilePicURL;
        user.userUUID = userFromRealm.userUUID;
        return user;
    }
    return nil;
}



#pragma mark -Convience Methods

- (void)realmUserFromBackendlessUser:(PingUser *)backendlessUser {
    
}

//- (BOOL)isUserListUpToDate {
//    return true;
//}

//- (BOOL)profilePicExistesForUser:(PingUser *)user {
//    return NO;
//}

- (void)stopScanning {
    [self.blueToothManager stop];
}

@end
