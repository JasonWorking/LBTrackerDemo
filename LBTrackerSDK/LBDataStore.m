//
//  LBDataStore.m
//  BgTracker
//
//  Created by Jason on 15/7/27.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import "LBDataStore.h"
#import "LBSenserRecord.h"
#import "LBLocationRecord.h"
#import "LBRecordStack.h"


#define kLocationRecordCountMAX  100
#define kSensorRecordCountMAX  1000

@interface LBDataStore ()

@property (nonatomic, strong) LBRecordStack *locationRecords;
@property (nonatomic, strong) LBRecordStack *sensorRecords;

@property (nonatomic, strong) LBRecordStack *pendingLocations;
@property (nonatomic, strong) LBRecordStack *pendingSensors;

@property (nonatomic, strong) NSString *locationDatafilePath;
@property (nonatomic, strong) NSString *sensorDatafilePath;

@end

@implementation LBDataStore


- (instancetype)init
{
    if (self = [super init]) {
        [self loadDataToMemory];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)saveDataToDisk
{
    if (![self.pendingLocations isEmpty]) {
        [NSKeyedArchiver archiveRootObject:self.pendingLocations toFile:self.locationDatafilePath];
    }
    
    if (![self.pendingSensors isEmpty]) {
        [NSKeyedArchiver archiveRootObject:self.pendingSensors toFile:self.sensorDatafilePath];
    }
    
}

- (void)loadDataToMemory
{
    self.pendingLocations = [NSKeyedUnarchiver unarchiveObjectWithFile:self.locationDatafilePath];
    self.pendingSensors  = [NSKeyedUnarchiver unarchiveObjectWithFile:self.sensorDatafilePath];
    
}


- (void)appWillTerminate:(NSNotification *)note
{
    [self saveDataToDisk];
}


#pragma mark - Location records

- (void)pushLocationRecord:(LBLocationRecord *)record
{
    [self.locationRecords pushRecord:record];
}

- (LBLocationRecord *)popLocationRecord
{
    return [self.locationRecords pop];
}

- (NSArray *)avaliableLocationRecords;
{
    return  [[self.locationRecords allRecords] copy];
}


- (void)pushPendingLocationRecord:(LBLocationRecord *)record
{
    [self.pendingLocations pushRecord:record];
}

- (LBLocationRecord *)popPendingLocationRecord
{
    return [self.pendingLocations pop];
}

- (NSArray *)pendingLocationRecords
{
    return [[self.pendingLocations allRecords] copy];
}


#pragma mark - Sensor records

- (void)pushSensorRecord:(LBSenserRecord *)record;
{
    [self.sensorRecords pushRecord:record];
}

- (void)pushSensorRecords:(NSArray *)records;
{
    for (LBSenserRecord *record in records) {
        [self pushSensorRecord:record];
    }
}


- (LBSenserRecord *)popSensorRecord
{
    return [self.sensorRecords pop];
}

- (NSArray *)popSensorRecordsForCount:(NSUInteger)count
{
    return [self.sensorRecords popForCount:count];
}

- (NSArray *)avaliableSensorRecords;
{
    return  [[self.sensorRecords allRecords] copy];;
}


- (void)pushPendingSensorRecord:(LBSenserRecord *)record
{
    [self.pendingSensors pushRecord:record];
}
- (void)pushPendingSensorRecords:(NSArray *)records;
{
    for (LBSenserRecord *record in records) {
        [self pushPendingSensorRecord:record];
    }
}


- (LBSenserRecord *)popPendingSensorRecord
{
    return [self.pendingSensors pop];
}

- (NSArray *)popPendingSensorRecordsForCount:(NSUInteger)count
{
    return [self.pendingSensors popForCount:count];
}

- (NSArray *)pendingSensorRecords
{
    return [[self.pendingSensors allRecords] copy];
}

#pragma mark - Getter

- (NSString*)locationDatafilePath {
    if (_locationDatafilePath == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _locationDatafilePath = [documentsDirectory stringByAppendingPathComponent:@"location_data"];
    }
    return _locationDatafilePath;
}

- (NSString *)sensorDatafilePath
{
    if (_sensorDatafilePath == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _sensorDatafilePath = [documentsDirectory stringByAppendingPathComponent:@"sensor_data"];
    }
    return _sensorDatafilePath;

}


- (LBRecordStack *)locationRecords
{
    if (!_locationRecords) {
        _locationRecords = [[LBRecordStack alloc] initWithCapacity:kLocationRecordCountMAX];
    }
    return _locationRecords;
}

- (LBRecordStack *)sensorRecords
{
    if (!_sensorRecords) {
        _sensorRecords = [[LBRecordStack alloc] initWithCapacity:kSensorRecordCountMAX];
    }
    
    return _sensorRecords;
}


- (LBRecordStack *)pendingLocations
{
    if (!_pendingLocations) {
        _pendingLocations = [[LBRecordStack alloc] initWithCapacity:kLocationRecordCountMAX];
    }
    return _pendingLocations;
}


- (LBRecordStack *)pendingSensors
{
    if (!_pendingSensors) {
        _pendingSensors = [[LBRecordStack alloc] initWithCapacity:kSensorRecordCountMAX];
    }
    return _pendingSensors;
}




@end
