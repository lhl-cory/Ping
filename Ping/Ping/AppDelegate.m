//
//  AppDelegate.m
//  Ping
//
//  Created by thomas minshull on 2016-07-24.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "AppDelegate.h"
#import "Ping-Bridging-Header.h"
#import "UserManager.h"
#import "Ping-Swift.h"
#import "BlueToothManager.h"
#import "NewEventViewController.h"
#import "LoginViewController.h"
#import "LoginManager.h"

#import <linkedin-sdk/LISDK.h>
//CR: api keys in git. *finger wag*
#import <Parse/Parse.h>
#define Parse_APP_ID @"QaDwdtxkrP8gd42kZrvn1aHv64PKRNLxuuHY964v"
#define Parse_Client_Key @"AZ8btrgurhLG306dVeWjKjx9nSszPI5sAoqwcZ6F"

@import GooglePlaces;
#define GOOGLE_KEY @"AIzaSyAUSze3iQQHpyNSQhmZCpaMKCu8ZrRV22c"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    UIMutableUserNotificationAction *noBTAction = [[UIMutableUserNotificationAction alloc] init];
    noBTAction.identifier = @"NO_BLUETOOTH"; // CR: define constants for identifiers
    noBTAction.title = @"Turn off BlueTooth";
    noBTAction.activationMode = UIUserNotificationActivationModeBackground;
    noBTAction.authenticationRequired = false;
    noBTAction.destructive = true;
    
    UIMutableUserNotificationAction *turnOnBTAction = [[UIMutableUserNotificationAction alloc] init];
    turnOnBTAction.identifier = @"YES_BLUETOOTH";
    turnOnBTAction.title = @"Turn on BlueTooth";
    turnOnBTAction.activationMode = UIUserNotificationActivationModeForeground;
    turnOnBTAction.authenticationRequired = false;
    turnOnBTAction.destructive = false;
    
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = @"BT_CATEGORY";
    [category setActions:@[noBTAction, turnOnBTAction] forContext: UIUserNotificationActionContextDefault];
    [category setActions:@[noBTAction, turnOnBTAction] forContext: UIUserNotificationActionContextMinimal];
    
    
    // Ask for notification permission.
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:[NSSet setWithObject: category]]];
        
        [application registerForRemoteNotifications];
    }
    
    // Initialize Parse.
    [Parse setApplicationId:Parse_APP_ID clientKey:Parse_Client_Key];
    
    // Initialize Google Map API
    [GMSPlacesClient provideAPIKey:GOOGLE_KEY];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    WelcomeScrollingViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    // CR: why this and not storyboard only?
    UINavigationController *navCtrlr = [[UINavigationController alloc]initWithRootViewController:loginVC];
    [self.window setRootViewController:navCtrlr];
    navCtrlr.navigationBarHidden = YES;
    
    return YES;
}    

- (void)applicationWillTerminate:(UIApplication *)application {
    //IntegrationManager *iM = [IntegrationManager sharedIntegrationManager];
    //   [iM.blueToothManager stop];
}

#pragma mark -LinkedIn SDK

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([LISDKCallbackHandler shouldHandleUrl:url]) {
        return [LISDKCallbackHandler application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    return YES;
}

#pragma mark - Action upon notification

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler{
    int caseNum = 0;
    
    BlueToothManager *btm = [BlueToothManager sharedBluetoothManager];
    
    if ([identifier isEqualToString: @"YES_BLUETOOTH"]){
        caseNum = 0;
    }else if ([identifier isEqualToString: @"NO_BLUETOOTH"]){
        caseNum = 1;
    }
    // CR: redundant... if/else THEN a switch?
    NSLog(@"Action identifier is %@", identifier);
    
    switch (caseNum) {
        case 0:
            [btm setUpBluetooth];
            NSLog(@"bluetooth is on!");
            break;
        case 1:
            [btm stop];
            NSLog(@"bluetooth is off!");
            break;
    }
    completionHandler();
}

#pragma mark -3D Touch

// CR: Can we get back from these?
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    
    NSLog(@"%@ item pressed.", shortcutItem.localizedTitle);
    
    LoginManager *loginManager = [[LoginManager alloc] init];
    // CR: Good candidate for an early return (guard-let in swift)
    if (![loginManager isLoggedIn]) {
        [self launchLogInScreen];
        return;
    }
    
    // CR: Constants
    if ([shortcutItem.type isEqualToString:@"com.Ping.createEvent"]) {
        [self launchNewEventViewController];
        //            self.userShouldBeDirectedToNewEventViewController = YES;
    }
    
    if ([shortcutItem.type isEqualToString:@"com.Ping.surroundings"]) {
        [self launchSurroundingsViewController];
    }
    
    if ([shortcutItem.type isEqualToString:@"com.Ping.browseEvents"]) {
        [self launchEventCalenderViewController];
        //            self.userShouldBeDirectedToCurrentSurroundingsViewController = YES;
    }
}

- (void)launchNewEventViewController {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
//    NewEventViewController *newEventVC = [storyboard instantiateViewControllerWithIdentifier:@"NewEventViewController"];
    EventListViewController *eventListVC = [storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
    
    eventListVC.userManager = [[UserManager alloc] init];
    [eventListVC.userManager fetchUsersWthCompletion:^(NSArray *users) {}];
    
    self.window.rootViewController = eventListVC;
    [self.window makeKeyAndVisible];
    
    eventListVC.userManager = [[UserManager alloc] init];
    [eventListVC.userManager fetchUsersWthCompletion:^(NSArray *users) {}];
    
    [eventListVC performSegueWithIdentifier:@"showNewEventViewSegueNoAnimation" sender:nil];

    
}

- (void)launchEventCalenderViewController {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    EventListViewController *eventListVC = [storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
    
    eventListVC.userManager = [[UserManager alloc] init];
    [eventListVC.userManager fetchUsersWthCompletion:^(NSArray *users) {}];
    
    self.window.rootViewController = eventListVC;
    [self.window makeKeyAndVisible];
    
}

- (void)launchSurroundingsViewController {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    EventListViewController *eventListVC = [storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
    
    eventListVC.userManager = [[UserManager alloc] init];
    [eventListVC.userManager fetchUsersWthCompletion:^(NSArray *users) {}];
    
    self.window.rootViewController = eventListVC;
    [self.window makeKeyAndVisible];
    
    [eventListVC performSegueWithIdentifier:@"showCurrentSurroundingsNoAnimation" sender:nil];
    
}

- (void)launchLogInScreen {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    
    self.window.rootViewController = loginVC;
    [self.window makeKeyAndVisible];
}

@end

