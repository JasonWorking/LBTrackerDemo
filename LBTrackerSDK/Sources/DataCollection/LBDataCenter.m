
//
//  LBDataCenter.m
//  LBTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import "LBDataCenter.h"
#import "LBDeviceInfoManager.h"
#import "LBDataStore.h"
#import "LBLocationTracker.h"
#import "LBPendingDataManager.h"
#import <CoreMotion/CMMotionActivityManager.h>
#import "CMMotionActivity+JSON.h"
#import "LBCoreMotionActivityManager.h"

@interface LBDataCenter ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *dataCollectionTimer;
@property (nonatomic, strong) LBLocationTracker *locationTracker;
@property (nonatomic, strong) LBDeviceInfoManager *deviceInfoManager;
@property (nonatomic, strong) LBCoreMotionActivityManager *cmaManager;
@end

@implementation LBDataCenter

#pragma mark - Init 


IMP_SINGLETON;

+ (void)initializeDataCenterWithDelegate:(id<LBDataCenterDelegate>)delegate
{
    LBDataCenter *dc = [LBDataCenter sharedInstance];
    dc.delegate = delegate;
    [LBPendingDataManager sharedInstance];
    [dc.delegate dataCenterDidInitialized];
}

- (instancetype) init
{
    if (self = [super init]) {
        _cmaManager = [[LBCoreMotionActivityManager alloc] init];
        _locationTracker = [[LBLocationTracker alloc] init];
        _deviceInfoManager = [LBDeviceInfoManager sharedInstance];
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 4;
    }
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Data collection

- (void)startDataColletionWithTimeInterval:(NSTimeInterval)time
{
    if (self.dataCollectionTimer) {
        [self.dataCollectionTimer invalidate];
        self.dataCollectionTimer = nil;
    }
    
    [self.cmaManager startQueryMotionActivity];
    [self.locationTracker startLocationTrackingWithTimeInterval:MAX(time, 60)];
//    [self.deviceInfoManager startCoreMotionMonitorClearData:YES];
    // Fire data upload
    self.dataCollectionTimer = [NSTimer scheduledTimerWithTimeInterval:MAX(time, 60)
                                                        target:self
                                                      selector:@selector(fireDataUpload)
                                                      userInfo:nil
                                                       repeats:YES];
    
}

- (void)stopDataCollection
{
    [self.dataCollectionTimer invalidate];
    [self.locationTracker stopLocationTracking];
//    [self.deviceInfoManager stopCoreMotionMonitorClearData:YES];
}


- (void)fireDataUpload
{
    [self.locationTracker uploadLocationToServer];
//    [self.deviceInfoManager uploadDeviveInfoToServer];
    
//    if ([CMMotionActivityManager isActivityAvailable]) {
//        [self.cmaManager queryActivityStartingFromDate:[NSDate dateWithTimeInterval:-(60) sinceDate:[NSDate date]]
//                                                toDate:[NSDate date]
//                                               toQueue:self.queue
//                                           withHandler:^(NSArray *activities, NSError *error) {
//                                               
//                                               [activities enumerateObjectsUsingBlock:^(CMMotionActivity* obj, NSUInteger idx, BOOL *stop) {
//                                                   [obj logToFilePath:nil];
//                                               }];
//                                               NSLog(@"activeties : %@", activities);
//        }];
//    }
    
    
//    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
//        [self.deviceInfoManager startCoreMotionMonitorClearData:YES];
//    }
 
}

- (void)onDataReadyForUpload
{
    [[LBDeviceInfoManager sharedInstance] stopCoreMotionMonitorClearData:YES];
    NSLog(@"data ready to upload . ");
}





@end
