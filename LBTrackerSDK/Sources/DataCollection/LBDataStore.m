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
    if (![self.locationRecords isEmpty]) {
        [NSKeyedArchiver archiveRootObject:self.locationRecords toFile:self.locationDatafilePath];
    }
    
    if (![self.sensorRecords isEmpty]) {
        [NSKeyedArchiver archiveRootObject:self.sensorRecords toFile:self.sensorDatafilePath];
    }
    
}

- (void)loadDataToMemory
{
    self.locationRecords = [NSKeyedUnarchiver unarchiveObjectWithFile:self.locationDatafilePath];
    self.sensorRecords  = [NSKeyedUnarchiver unarchiveObjectWithFile:self.sensorDatafilePath];
    
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

- (NSArray *)popLocationRecordForCount:(NSUInteger)count;{
    return [self.locationRecords popForCount:count];
}

- (NSArray *)avaliableLocationRecords;
{
    return  [[self.locationRecords allRecords] copy];
}

- (void)emptyLocationRecords
{
    [self.locationRecords setEmpty];
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

- (void)emptySensorRecords
{
    [self.sensorRecords setEmpty];
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





@end
