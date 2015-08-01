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
             @"confidence":@(self.confidence),
             @"unknown":@(self.unknown),
             @"stationary":@(self.stationary),
             @"walking":@(self.walking),
             @"running":@(self.running),
             @"automotive":@(self.automotive),
             @"cycling":@(self.cycling),
             @"timestamp":@(self.timestamp * 1000)
             };
}


- (void)logToFilePath:(NSString *)path
{
    NSString *log = [NSString stringWithFormat:@"CMActivity: confidence = %ld, unknown = %d,stationary = %d, walking = %d , running = %d,automotive = %d, cycling = %d,timestamp = %f",(long)self.confidence, self.unknown, self.stationary,self.walking,self.running, self.automotive, self.cycling, self.timestamp * 1000];
    [self logString:log toFile:nil];
}



- (void)logString:(NSString *)stringToLog toFile:(NSString *)filePath
{
    NSLog(@"%@", stringToLog);
    
    NSString * logFileName = [NSString stringWithFormat:@"%@.log", @"CMActivity"];
    
    NSDateFormatter * dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    }
    
    stringToLog = [NSString stringWithFormat:@"%@ --- INFO: %@\n", [dateFormatter stringFromDate:[NSDate date]], stringToLog];
    
    //Get the file path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:logFileName];
    
    //Create file if it doesn't exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileName])
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
    
    //Append text to file (you'll probably want to add a newline every write)
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    [file seekToEndOfFile];
    [file writeData:[stringToLog dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}




//
///**
// @property(readonly, nonatomic) NSDate *startDate;
// 
// /*
// *  unknown
// *
// *  Discussion:
// *    True if there is no estimate of the current state.  This can happen if
// *    the device was turned off.
// */
//@property(readonly, nonatomic) BOOL unknown;
//
///*
// *  stationary
// *
// *  Discussion:
// *    True if the device is not moving.
// */
//@property(readonly, nonatomic) BOOL stationary;
//
///*
// *  walking
// *
// *  Discussion:
// *    True if the device is on a walking person.
// */
//@property(readonly, nonatomic) BOOL walking;
//
///*
// *  running
// *
// *  Discussion:
// *    True if the device is on a running person.
// */
//@property(readonly, nonatomic) BOOL running;
//
///*
// *  automotive
// *
// *  Discussion:
// *    True if the device is in a vehicle.
// */
//@property(readonly, nonatomic) BOOL automotive;
//
///*
// *  cycling
// *
// *  Discussion:
// *    True if the device is on a bicycle.
// */
//@property(readonly, nonatomic) BOOL cycling NS_AVAILABLE(NA, 8_0);
//
//  <#Description#>
// */

@end
