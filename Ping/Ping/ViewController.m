//
//  ViewController.m
//  Ping
//
//  Created by thomas minshull on 2016-07-24.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "ViewController.h"
#import "RecordManager.h"

@interface ViewController ()

- (IBAction)runButtonPressed:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)runButtonPressed:(id)sender {
    NSDate *currentDate = [NSDate date];
    NSString *uUID = @"aufghsoguhaoifoaifhgaogiheowg";
    int proximity = 25;
    RecordManager *aRecordManager = [[RecordManager alloc] init];
    [aRecordManager storeBlueToothDataByUUID:uUID userProximity:proximity andTime:currentDate];
}
@end
