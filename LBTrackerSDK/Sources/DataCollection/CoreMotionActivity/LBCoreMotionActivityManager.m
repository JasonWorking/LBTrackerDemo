//
//  LBCoreMotionActivityManager.m
//  SimpleWeather
//
//  Created by Jason on 15/8/2.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import "LBCoreMotionActivityManager.h"
#import <CoreMotion/CoreMotion.h>
#import "LBHTTPClient.h"

static NSString *const kCoreMotionLastUploadTimeKey  = @"kCoreMotionLastUploadTimeKey";

static const NSTimeInterval kDefaultQueryTimeInterval = 7 * 24 * 60 * 60; // 1 week.
static const NSTimeInterval kMinQueryInterval = 5 * 60 ;//  5 minutes
@interface LBCoreMotionActivityManager ()
@property (nonatomic, strong) CMMotionActivityManager *manager;
@property (nonatomic, strong) NSDate           *lastUploadDate;
@property (nonatomic, assign) NSTimeInterval   minQueryInterval;
@property (nonatomic, strong) NSMutableArray   *motionActivitys;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, weak  ) NSOperation      *uploadOperation;
@property (nonatomic, assign) BOOL             querying;
@property (nonatomic, assign) BOOL             started;
@end

@implementation LBCoreMotionActivityManager

@synthesize lastUploadDate = _lastUploadDate;

IMP_SINGLETON


- (instancetype)init
{
    if (self = [super init]) {
        _manager = [[CMMotionActivityManager alloc] init];
        _minQueryInterval = kMinQueryInterval;
        _querying = NO;
        _started = NO;
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount  = 1;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)startQueryMotionActivity
{
   
    if (![CMMotionActivityManager isActivityAvailable]) {
        return;
    }
    self.started = YES;
    
    // 仅获取一个星期以内的数据  且取数据间隔不小于5分钟.
    if(fabsf([[self lastUploadDate] timeIntervalSinceNow]) > self.minQueryInterval){
        NSDate *last = nil;
        if ([[self lastUploadDate] isEqualToDate:[NSDate distantPast]]) {
            // First time
                last = [NSDate dateWithTimeIntervalSinceNow:(-kDefaultQueryTimeInterval)];
        }else{
            if (fabsf([[self lastUploadDate] timeIntervalSinceNow]) > kDefaultQueryTimeInterval) {
                last = [NSDate dateWithTimeIntervalSinceNow:(-kDefaultQueryTimeInterval)];
            }else{
                last = [self lastUploadDate];
            }
        }
        [self queryFrom:last toDate:[NSDate date]];
    }
    
}


- (void)queryFrom:(NSDate *)last toDate:(NSDate *)now
{
    
    __weak typeof(self) weakSelf = self;
    self.querying = YES;
    [self.manager queryActivityStartingFromDate:last
                                         toDate:now
                                        toQueue:self.queue
                                    withHandler:^(NSArray *activities, NSError *error) {
                                        __strong typeof(weakSelf) strongSelf = weakSelf;
                                        if (!error && [activities count]) {
                                            [strongSelf uploadCoreMotionActivitysToServer:activities];
                                        }else {
                                            NSLog(@"query activity error : %@", error);
                                        }
                                        strongSelf.querying = NO;
    }];

}

#pragma mark - Notification

- (void)appEnterForeground:(NSNotification *)note
{
    if (!self.querying && self.started) {
        [self startQueryMotionActivity];
    }
}

- (void)appEnterBackground:(NSNotification *)note
{
    if (self.uploadOperation) {
        [self.uploadOperation  cancel];
        self.uploadOperation = nil;
        self.querying = NO;
    }
}

#pragma mark - Getter
- (NSDate *)lastUploadDate
{
    if (!_lastUploadDate) {
        NSDate *storedDate = [[NSUserDefaults standardUserDefaults] objectForKey:kCoreMotionLastUploadTimeKey];
        if (storedDate) {
            _lastUploadDate = storedDate;
        }else {
            _lastUploadDate = [NSDate distantPast];
        }
    }
    return _lastUploadDate;
}

#pragma mark - Setter

- (void)setLastUploadDate:(NSDate *)lastUploadDate
{
    _lastUploadDate = lastUploadDate;
    [[NSUserDefaults standardUserDefaults] setValue:lastUploadDate forKey:kCoreMotionLastUploadTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Helper
- (BOOL)isApplicationInBackgroundMode
{
    return
    ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) ||
    ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive);
}


- (void)logStringToFile:(NSString *)stringToLog
{
    NSLog(@"%@", stringToLog);
    
    NSString * logFileName = [NSString stringWithFormat:@"%@.log", @"LocationTracker"];
    
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



@end



@implementation LBCoreMotionActivityManager (Network)

- (void)uploadCoreMotionActivitysToServer:(NSArray *)activities
{
    UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    }];
    
    NSString * logMessage = [NSString stringWithFormat:@"begin background task with id %lu", (unsigned long)bgTask];
    [self logStringToFile:logMessage];
    

    __weak typeof(self) weakSelf = self;
    self.uploadOperation = [LBHTTPClient uploadCMActivityRecords:activities onSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"cm activity success");
        weakSelf.lastUploadDate = [NSDate date];
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        
    } onFailure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"cm activity error ");
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    }];
}

@end


