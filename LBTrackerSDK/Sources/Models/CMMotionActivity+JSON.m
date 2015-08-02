//
//  CMMotionActivity+JSON.m
//  
//
//  Created by Jason Kaer on 15/8/2.
//
//

#import "CMMotionActivity+JSON.h"

@implementation CMMotionActivity (JSON)


- (NSDictionary *)JSONRepresentation
{
    return @{
             @"timestamp":@([self.startDate timeIntervalSince1970] * 1000),
             @"confidence":@(self.confidence),
             @"unknown":@(self.unknown),
             @"stationary":@(self.stationary),
             @"walking":@(self.walking),
             @"running":@(self.running),
             @"automotive":@(self.automotive),
             @"cycling":@(self.cycling),
             };
}


@end
