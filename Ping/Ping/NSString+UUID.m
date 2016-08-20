//
//  NSString+UUID.m
//  Ping
//
//  Created by thomas minshull on 2016-07-26.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

#import "NSString+UUID.h"

@implementation NSString (UUID)
// CR: [[NSUUID UUID] UUIDString];
+ (NSString*)getUUID {
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    return uuidString;
}

@end
