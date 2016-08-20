//
//  LoginViewController.m
//  Ping
//
//  Created by thomas minshull on 2016-07-25.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "LoginViewController.h"
#import <linkedin-sdk/LISDK.h>
#import <Parse/Parse.h>

#import "AppDelegate.h"

#import "UserManager.h"
#import "MainViewController.h"
#import "Ping-Swift.h"
#import "LoginManager.h"
#import "CurrentUser.h"

#import "Ping-Swift.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *linkedInLoginButton;

@property LoadingView *loadingView;

@property (strong, nonatomic) LoginManager __block *loginManager;
@property (strong, nonatomic) UserManager *userManager;
@property UIView *extensionView;

typedef void(^myCompletion)(BOOL); // CR: Not used.


@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loginManager = [[LoginManager alloc] init];
    self.userManager = [[UserManager alloc] init];
    
    self.loadingView = [[LoadingView alloc] initWithFrame:CGRectZero];
    self.loadingView.backgroundColor = [UIColor colorWithRed:0.85 green:0.98 blue:0.67 alpha:1.0];
    
    self.view.userInteractionEnabled = YES; // CR: ??
    self.loadingView.userInteractionEnabled = YES;
    
    [self.userManager fetchUsersWthCompletion:^(NSArray *users) {
        NSLog(@"User List Fetched");
    }];
    
    UITapGestureRecognizer *stopAnimateTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stopAnimateTap:)];
    [self.view addGestureRecognizer:stopAnimateTap];
    
    self.extensionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.extensionView.backgroundColor = [UIColor colorWithRed:0.85 green:0.98 blue:0.67 alpha:1.0];
    [self.view addSubview:self.extensionView];
    
    CGFloat boxSize = 320;
    self.loadingView = [[LoadingView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - boxSize / 2, 0, self.view.frame.size.width + 100, self.view.frame.size.height)];
    self.loadingView.backgroundColor = [UIColor colorWithRed:0.85 green:0.98 blue:0.67 alpha:1.0];
    
    [self.view addSubview:self.loadingView];
    
    // Highlight button when selected
    UIImage *signInWithLinkedInButtonHoveredImage = [UIImage imageNamed:@"Sign-In-Large---Hover"];
    [self.linkedInLoginButton setImage:signInWithLinkedInButtonHoveredImage forState:UIControlStateHighlighted];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    __weak LoginViewController *weakSelf = self;
    [self.loadingView addLoadingAnimationGroupAnimationCompletionBlock:^(BOOL finished) {
        [weakSelf.extensionView removeFromSuperview];
        [weakSelf.loadingView removeFromSuperview];
        
        NSLog(@"Done Animating!");
        
        if (weakSelf.loginManager.isFirstTimeUser) {
            // ToDo display Onboarding else continue
            
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
            {
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                
                WelcomeScrollingViewController *welcomeVC = [storyboard instantiateViewControllerWithIdentifier:@"welcomeVC"];
                
                [weakSelf.navigationController pushViewController:welcomeVC animated:YES];
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            NSLog(@"First time user");
        } else if ([weakSelf.loginManager isLoggedIn]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf performSegueWithIdentifier:@"EventListViewController" sender:nil];
            });
        }
    }];
}

#pragma mark -Actions

- (IBAction)linkedInLoginButtonTapped:(id)sender {
    
    if (![CurrentUser getCurrentUser]) { // Just being careful
        [self.loginManager createNewUserAndLoginWithCompletion:^(BOOL success) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSegueWithIdentifier:@"EventListViewController" sender:self];
                });
            } else {
                // Display Error
            }
        }];
    } else { // Better not create another user
        [self.loginManager attemptToLoginWithCompletion:^(BOOL success) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSegueWithIdentifier:@"EventListViewController" sender:self];
                });
            } else {
                //Display Error
            }
        }];
    }
    
}

#pragma mark -Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender{
    if ([[segue identifier] isEqualToString:@"EventListViewController"]) {
        EventListViewController *vc = [segue destinationViewController];
        vc.userManager = self.userManager;
    } else if ([[segue identifier] isEqualToString:@"showOnboardingSlides"]) {
        WelcomeScrollingViewController *welcomeVC = [segue destinationViewController];
        [welcomeVC startButtonPressed:self];
    }
}

- (IBAction)unwindToLoginViewController:(UIStoryboardSegue*)sender {
}


#pragma - Touch to stop the animation

- (void)stopAnimateTap:(UITapGestureRecognizer *)recognizer {
    [self.extensionView removeFromSuperview];
    [self.loadingView removeFromSuperview];
    NSLog(@"Touch gesture recognized. Stopping the Animation");
}

@end
