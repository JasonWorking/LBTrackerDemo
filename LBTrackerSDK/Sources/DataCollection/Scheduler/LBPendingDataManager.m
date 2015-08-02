//
//  LBPendingDataManager.m
//  SimpleWeather
//
//  Created by Jason on 15/8/2.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import "LBPendingDataManager.h"
#import "LBHTTPClient.h"
#import "LBNetReachability.h"

@implementation LBPendingDataManager

IMP_SINGLETON

- (instancetype)init
{
    if (self = [super init]) {
        _pendingData = [[LBDataStore alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)pushPengdingLocation:(LBLocationRecord *)location;
{
    if (!location) {
        return;
    }
    [[[self sharedInstance] pendingData] pushLocationRecord:location];
}

+ (void)pushPengdingSensors:(NSArray *)sensors;{
    if (!sensors || ![sensors count]) {
        return;
    }
    [[[self sharedInstance] pendingData] pushSensorRecords:sensors];
}


#pragma mark - 

- (void)onAppBecomeActive:(NSNotification *)note
{
    if ([[self.pendingData avaliableLocationRecords]  count]&& [[self.pendingData avaliableSensorRecords] count] && [LBNetReachability reachabilityForInternetConnection]) {
        // 上传位置信息
        NSLog(@"pending locations : %@" ,[self.pendingData avaliableLocationRecords]);
        [LBHTTPClient batchLocationRecords:[self.pendingData avaliableLocationRecords]  onSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.pendingData emptyLocationRecords];
        } onFailure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"upload pengding location records failed.");
        }];
        
        // 上传传感器信息
        [LBHTTPClient uploadSensorRecords:[self.pendingData avaliableSensorRecords] onSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.pendingData emptySensorRecords];
        } onFailure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"upload pengding sensor rescords failed. error : %@", error);
        }];
    }
    
    
}






@end
