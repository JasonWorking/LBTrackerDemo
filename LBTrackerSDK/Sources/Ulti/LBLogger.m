//
//  LBLogger.m
//  SimpleWeather
//
//  Created by Jason on 15/8/2.
//  Copyright (c) 2015年 Ryan Nystrom. All rights reserved.
//

#import "LBLogger.h"

@interface LBLogger  ()

@property (nonatomic,strong)NSDateFormatter *dateFormatter;

@end


@implementation LBLogger

IMP_SINGLETON

- (instancetype)init
{
    if (self = [super init]) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    }
    
    return self;
}


+ (void)logString:(NSString *)log toFile:(NSString *)fileName
{
    [[self sharedInstance] logString:log toFile:fileName];
}

- (void)logString:(NSString *)log toFile:(NSString *)fileName{
    
        NSLog(@"%@", log);
        
        NSString * logFileName = [NSString stringWithFormat:@"%@.log", fileName];
    
        log = [NSString stringWithFormat:@"%@ --- INFO: %@\n", [self.dateFormatter stringFromDate:[NSDate date]], log];
        
        //Get the file path
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:logFileName];
        
        //Create file if it doesn't exist
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        
        //Append text to file (you'll probably want to add a newline every write)
        NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        [file seekToEndOfFile];
        [file writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
        [file closeFile];
}

@end
