//
//  NewEventViewController.m
//  Ping
//
//  Created by Martin Zhang on 2016-08-10.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "NewEventViewController.h"
#import "Event.h"
#import "CurrentUser.h"
#import "RecordManager.h"
#import "Ping-Swift.h"

@interface NewEventViewController () <UITextFieldDelegate, SendDataDelegate>

@property (weak, nonatomic) IBOutlet UIButton *completeButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITextField *eventNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *eventHostTextField;
//@property (weak, nonatomic) IBOutlet UITextField *eventLocationTextField;
@property (weak, nonatomic) IBOutlet UIButton *startTimeButton;
@property (weak, nonatomic) IBOutlet UIButton *endTimeButton;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;

@property NSString *fetchedLocation;

@property (strong) Event *event;

@end

@implementation NewEventViewController

- (void)sendData:(NSString *)text{
    self.event.eventAddress = text;
    [self.locationButton setTitle:text forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.eventNameTextField.delegate = self;
    self.eventHostTextField.delegate = self;
    //    self.eventLocationTextField.delegate = self;
    
    self.event = [[Event alloc] init];
    
    [self.locationButton setTitle:@"Add location" forState:UIControlStateNormal];
}


#pragma mark - TextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.eventNameTextField]) {
        [self.eventHostTextField becomeFirstResponder];
    }
    //    else if ([textField isEqual:self.eventHostTextField]) {
    //        [self.eventLocationTextField becomeFirstResponder];
    //    }
    else {
        [textField resignFirstResponder];
    }
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier  isEqual: @"locationSegue"]) {
        LocationViewController *locVC = [segue destinationViewController];
        locVC.delegate = self;
    }
}

#pragma mark - Actions

- (IBAction)backgroundTapped:(id)sender {
    [self.view endEditing:YES];
}


- (IBAction)eventNameChanged:(UITextField *)sender {
    self.event.eventName = sender.text;
}

- (IBAction)hostNameChanged:(UITextField *)sender {
    self.event.hostName = sender.text;
}

- (IBAction)completeButtonPressed:(id)sender {
    // CR: Do the read here, rather than on change events.
    
    if ([self validEvent]) {
        CurrentUser *currentUser = [CurrentUser getCurrentUser];
        [currentUser addEvent:self.event];
        [self performSegueWithIdentifier:@"NewEventVCToEventListVC" sender:self];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Incomplete Event"
                                                                       message:@"Please make sure you've entered a name, host, start time, and end time. Please only enter future events"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alert addAction:okButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}

- (IBAction)backButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"NewEventVCToEventListVC" sender:self];
//    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)startTimeButtonPressed:(id)sender {
    
    [self.view endEditing:YES];
    
    //set up tinted background view
    UIView *darkView = [[UIView alloc] initWithFrame:self.view.bounds];
    darkView.alpha = 0;
    darkView.backgroundColor = [UIColor clearColor];
    darkView.tag = 9;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(dismissDatePicker:)];
    [darkView addGestureRecognizer:tapGesture];
    [self.view addSubview:darkView];
    
    // CR: a lot of ui setup code for a button action.
    // CR: consider having all of this pre-built and hide/show or lazy-loaded in it's getter.
    
    //set up date picker
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 380)];
    datePicker.tag = 10;
    
    [datePicker addTarget:self action:@selector(changeStartDate:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:datePicker];
    
    
    // set up toolBar
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 44)];
    toolBar.tag = 11;
    
    UIImage *toolBarImage = [UIImage imageNamed:@"realDarkClockToolBarImage"];
    [toolBar setBackgroundImage:toolBarImage forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:nil
                                                                            action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(dismissDatePicker:)];
    [toolBar setItems:[NSArray arrayWithObjects:spacer, doneButton, nil]];
    [self.view addSubview:toolBar];
    
    
    // Make a cool enterince
    [UIView beginAnimations:@"MoveIn" context:nil];
    
    datePicker.frame = CGRectMake(0.0, self.view.bounds.size.height*4.7/10, self.view.bounds.size.width, 380);
    
    toolBar.frame = CGRectMake(0.0, self.view.bounds.size.height*4.7/10, self.view.bounds.size.width, 44);
    
    darkView.alpha = 0.5;
    
    [UIView commitAnimations];
}

- (IBAction)endTimeButtonPressed:(id)sender {
    
    [self.view endEditing:YES];
    
    UIView *darkView = [[UIView alloc] initWithFrame:self.view.bounds];
    darkView.alpha = 0;
    darkView.backgroundColor = [UIColor clearColor
                                ];
    darkView.tag = 9;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDatePicker:)];
    [darkView addGestureRecognizer:tapGesture];
    [self.view addSubview:darkView];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 380)];
    datePicker.tag = 10;
    [datePicker addTarget:self action:@selector(changeEndDate:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:datePicker];
    
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 44)];
    toolBar.tag = 11;
    UIImage *toolBarImage = [UIImage imageNamed:@"realToolBarImage"];
    [toolBar setBackgroundImage:toolBarImage forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [
                                   [UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissDatePicker:)];
    [toolBar setItems:[NSArray arrayWithObjects:spacer, doneButton, nil]];
    [self.view addSubview:toolBar];
    
    [UIView beginAnimations:@"MoveIn" context:nil];
    datePicker.frame = CGRectMake(0.0, self.view.bounds.size.height*4.7/10, self.view.bounds.size.width, 380);
    
    toolBar.frame = CGRectMake(0.0, self.view.bounds.size.height*4.7/10, self.view.bounds.size.width, 44);
    darkView.alpha = 0.5;
    
    [UIView commitAnimations];
}

- (void)changeStartDate:(UIDatePicker *)sender {
    NSLog(@"New Date: %@", sender.date);
    RecordManager *recMan = [[RecordManager alloc] init];
    NSDate *eventStartDate = [recMan getStartTimeForTimePeriod:sender.date];
    self.event.startTime = eventStartDate;
}

- (void)changeEndDate:(UIDatePicker *)sender {
    NSLog(@"New Date: %@", sender.date);
    RecordManager *recMan = [[RecordManager alloc] init];
    NSDate *eventEndDate = [recMan getStartTimeForTimePeriod:sender.date];
    self.event.endTime = eventEndDate;
}


#pragma mark -custom methods

- (void)dueDateChanged:(UIDatePicker *)sender {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    NSLog(@"Picked the date %@", [dateFormatter stringFromDate:[sender date]]);
}

- (void)removeViews:(id)object {
    [[self.view viewWithTag:9] removeFromSuperview];
    [[self.view viewWithTag:10] removeFromSuperview];
    [[self.view viewWithTag:11] removeFromSuperview];
}

- (void)dismissDatePicker:(id)sender {
    CGRect toolbarTargetFrame = CGRectMake(0, self.view.bounds.size.height, 320, 44);
    CGRect datePickerTargetFrame = CGRectMake(0, self.view.bounds.size.height+44, 320, 216);
    [UIView beginAnimations:@"MoveOut" context:nil];
    [self.view viewWithTag:9].alpha = 0;
    [self.view viewWithTag:10].frame = datePickerTargetFrame;
    [self.view viewWithTag:11].frame = toolbarTargetFrame;
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(removeViews:)];
    [UIView commitAnimations];
    
}

- (bool)validEvent {
    if (!(self.event.eventName.length > 0) || !(self.event.hostName.length > 0) || !self.event.startTime || !self.event.endTime || !self.event.eventAddress) {
        return false;
    } else if ([self.event.startTime compare:self.event.endTime] != NSOrderedAscending) {
        return false;
    } else if ([[NSDate date] compare:self.event.startTime ] != NSOrderedAscending) {
        return false;
    } else {
        return true;
    }
}

#pragma mark - Navigation

- (IBAction)unwindToNewEventViewController:(UIStoryboardSegue*)sender {
}


@end
