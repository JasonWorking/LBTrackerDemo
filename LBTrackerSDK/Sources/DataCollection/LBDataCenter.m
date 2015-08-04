
//
//  LBDataCenter.m
//  LBTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 LB. All rights reserved.
//


// Custom
#import "LBDataCenter.h"
#import "LBDeviceInfoManager.h"
#import "LBPendingDataManager.h"
#import "LBCoreMotionActivityManager.h"
#import "LBLocationTracker.h"

// System
#import <CoreMotion/CMMotionActivityManager.h>

@interface LBDataCenter ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *dataCollectionTimer;
@property (nonatomic, strong) LBLocationTracker *locationTracker;
@property (nonatomic, strong) LBDeviceInfoManager *deviceInfoManager;
@property (nonatomic, strong) LBCoreMotionActivityManager *cmaManager;
@property (nonatomic, assign) NSTimeInterval interval;
@end

@implementation LBDataCenter

#pragma mark - Life Cycle


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
        _cmaManager        = [[LBCoreMotionActivityManager alloc] init];
        _locationTracker   = [[LBLocationTracker alloc] init];
        _deviceInfoManager = [[LBDeviceInfoManager alloc] init];
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
    
    self.interval  = time;
    [self.cmaManager startQueryMotionActivity];
    [self.locationTracker startLocationTrackingWithInterval:MAX(time, 60)];
    [self.deviceInfoManager startCoreMotionMonitorClearData:YES];
//     Fire device info data upload, device Info manager auto stoped when 10 sensor records is collected.
    self.dataCollectionTimer = [NSTimer scheduledTimerWithTimeInterval:20
                                                        target:self
                                                      selector:@selector(fireDataUpload)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)stopDataCollection
{
    [self.dataCollectionTimer invalidate];
    [self.locationTracker stopLocationTracking];
    [self.deviceInfoManager stopCoreMotionMonitorClearData:YES];
}


- (void)fireDataUpload
{
    [self.deviceInfoManager uploadDeviveInfoToServer];
    [self.deviceInfoManager startCoreMotionMonitorClearData:NO];

}




@end
