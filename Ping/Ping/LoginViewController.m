//
//  LoginViewController.m
//  Ping
//
//  Created by thomas minshull on 2016-07-25.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "LoginViewController.h"
#import <linkedin-sdk/LISDK.h>
#import "PingUser.h"
#import "Backendless.h"

#import "AppDelegate.h"

#import "MainViewController.h"

#import "UserManager.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *linkedInLoginButton;
@property (strong, nonatomic) UserManager *userManager;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userManager = [UserManager sharedUserManager];
}

- (void)viewDidAppear:(BOOL)animated {
    
    PingUser *previouslyLoggedInUser = [self.userManager fetchCurrentUserFromRealm];
    
    if (previouslyLoggedInUser && previouslyLoggedInUser.userUUID) {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        app.currentUser = previouslyLoggedInUser;
        
        // login with but don't create new user
        [self.userManager createNewSessionWithoutNewUsersWithCompletion:^{
            [self performSegueWithIdentifier:NSStringFromClass([MainViewController class]) sender:self];
        }];
    }
}


#pragma mark -Actions

- (IBAction)linkedInLoginButtonTapped:(id)sender {
    // do I have a account already
 
    PingUser *previouslyLoggedInUser = [self.userManager fetchCurrentUserFromRealm];
    
    if (previouslyLoggedInUser && previouslyLoggedInUser.userUUID) { //Yup
        // CR: Gross:
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        app.currentUser = previouslyLoggedInUser;
        
        // login with but don't create new user
        [self.userManager createNewSessionWithoutNewUsersWithCompletion:^{
            [self performSegueWithIdentifier:NSStringFromClass([MainViewController class]) sender:self];
        }];
    } else { // NOPE
        [self.userManager loginAndCreateNewUserWithCompletion:^{
            [self performSegueWithIdentifier:NSStringFromClass([MainViewController class]) sender:self];
        }];
    }
}

@end
