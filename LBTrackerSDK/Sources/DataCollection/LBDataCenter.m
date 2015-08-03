
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
#import "LBPendingDataManager.h"
#import <CoreMotion/CMMotionActivityManager.h>
#import "CMMotionActivity+JSON.h"
#import "LBCoreMotionActivityManager.h"
#import "LocationTracker.h"

@interface LBDataCenter ()
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSTimer *dataCollectionTimer;
@property (nonatomic, strong) LocationTracker *locationTracker;
@property (nonatomic, strong) LBDeviceInfoManager *deviceInfoManager;
@property (nonatomic, strong) LBCoreMotionActivityManager *cmaManager;
@property (nonatomic, assign) NSTimeInterval interval;
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
        _locationTracker  = [[LocationTracker alloc] init];
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
    
    self.interval  = time;
    [self.cmaManager startQueryMotionActivity];
    [self.locationTracker startLocationTrackingWithInterval:MAX(time, 60)];
    [self.deviceInfoManager startCoreMotionMonitorClearData:YES];
//     Fire data upload
    self.dataCollectionTimer = [NSTimer scheduledTimerWithTimeInterval:MAX(time, 60)
                                                        target:self
                                                      selector:@selector(fireDataUpload)
                                                      userInfo:nil
                                                       repeats:NO];
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
    if (self.dataCollectionTimer) {
        [self.dataCollectionTimer invalidate];
        self.dataCollectionTimer = nil;
    }

}




@end
