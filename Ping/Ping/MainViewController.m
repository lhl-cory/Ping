//
//  MainViewController.m
//  Ping
//
//  Created by thomas minshull on 2016-07-27.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "MainViewController.h"
#import "RecordManager.h"
#import "UserManager.h"
#import "PingUserTableViewCell.h"
#import <linkedin-sdk/LISDK.h>
#import "Ping-Swift.h"
#import "CurrentUser.h"
#import "BlueToothManager.h"

@interface MainViewController ()  <UITableViewDelegate, UITableViewDataSource>


@property (weak, nonatomic) IBOutlet UISwitch *advertisingSwitch;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray<NSString *> *orderedListOfUUIDs;

@property (strong, nonatomic) RecordManager *recordManager;
@property (strong, nonatomic) BlueToothManager *blueToothManager;
@end

@implementation MainViewController {
    UIDatePicker *datePicker;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.blueToothManager = [[BlueToothManager alloc] init];
    // CR: BlueToothManager has a singleton, but this is a different one!
    self.recordManager = [[RecordManager alloc] init];
    
    // CR: User, ParseUser, PingUser CurrentUser, and UserManager.
    // CR: That's a lot of classes, very unclear what the differences are.
    // CR: Merge some ideas, rename some ideas, etc.
    
    CurrentUser *user = [CurrentUser getCurrentUser];
    NSLog(@"%@", user);

    self.orderedListOfUUIDs = [self.recordManager UUIDsSortedAtTime:[NSDate date]];
    if (!self.orderedListOfUUIDs) {
        self.orderedListOfUUIDs = @[];
    }
    
    CGRect datePickerFrame = CGRectMake(20.0, 0.0, self.view.frame.size.width-16.0, 200.0);
    datePicker = [[UIDatePicker alloc] initWithFrame:datePickerFrame];
    
    [datePicker addTarget:self action:@selector(datePickerChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:datePicker];
    
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}


#pragma mark -TableViewDataSourceMethods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"number of rows in section %d", (int)[self.orderedListOfUUIDs count]);
    return [self.orderedListOfUUIDs count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // CR: Store identifiers as class-methods on the cell class
    PingUserTableViewCell *cell = (PingUserTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"PingUserTableViewCell" forIndexPath:indexPath];
    
//    [self.tableView dequeueReusableCellWithIdentifier:<#(nonnull NSString *)#>]
//    vs.
//    [self.tableView dequeueReusableCellWithIdentifier:<#(nonnull NSString *)#> forIndexPath:<#(nonnull NSIndexPath *)#>];
//    
//    
    if (cell == nil) {
        PingUserTableViewCell *cell = [[PingUserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PingUserTableViewCell"];
        return cell;
    }
    
    User *user = [self.userManager userForUUID:self.orderedListOfUUIDs[indexPath.row]];
    
    [cell setUpWithUser:user];
    
    return cell;
}


#pragma mark -TableViewDeletage Methods 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Segue To Linked In profile page
    [[LISDKDeeplinkHelper sharedInstance] viewOtherProfile:[self.userManager userForUUID:self.orderedListOfUUIDs[indexPath.row]].linkedInID withState:@"viewedMemberProfilePage" showGoToAppStoreDialog:NO success:nil error:nil];
}


#pragma mark -Actions 

- (IBAction)nowButtonTapped:(id)sender {
    datePicker.date = [self getStartTimeForTimePeriod:[NSDate date]];
    [self datePickerChanged:datePicker];
   // [self.userManager setUp];
}

- (void)datePickerChanged:(UIDatePicker *)sender {
    
    // change orderedListOfUsers to be the list for this new date
    self.orderedListOfUUIDs = [self.recordManager UUIDsSortedAtTime:datePicker.date];
    if (!self.orderedListOfUUIDs) {
        self.orderedListOfUUIDs = @[];
    }
    [self.tableView reloadData];
}

- (IBAction)switchChanged:(id)sender {
//    if (self.advertisingSwitch.on) {
//        [self.blueToothManager setUpBluetooth];
//    }
//    
//    else {
//        [self.blueToothManager stop];
//    }
}

#pragma mark -Helper Methodes

// ToDo refactored martin's code so we "should" be able to delete this 

// CR: move into a category on NSDate. (or delete).

-(NSDate *)getStartTimeForTimePeriod:(NSDate *)time{
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]; // get calander
    NSDateComponents *newDateComponenet = [[NSDateComponents alloc] init]; // create new component
    
    NSDateComponents *minComponent = [cal components:(NSCalendarUnitMinute|NSCalendarUnitSecond|NSCalendarUnitNanosecond) fromDate:time]; // get the components from time passed in
    
    // flip sign on seconds and nanoseconds (this will zero out these values)
    newDateComponenet.second = (-1)*minComponent.second;
    newDateComponenet.nanosecond = (-1)*minComponent.nanosecond;
    // round down the minutes
    newDateComponenet.minute = (-1) * (minComponent.minute %10);
    
    // apply the adjusted components to the passed in date to return the new date
    return [cal dateByAddingComponents:newDateComponenet toDate:time options:0];
    
}


@end
