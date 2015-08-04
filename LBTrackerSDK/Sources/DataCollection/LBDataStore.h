//
//  LBDataStore.h
//  BgTracker
//
//  Created by Jason on 15/7/27.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LBLocationRecord;
@class LBSenserRecord;

@interface LBDataStore : NSObject


- (void)saveDataToDisk;
- (void)loadDataToMemory;


// Location data stack
- (void)pushLocationRecord:(LBLocationRecord *)record;
- (LBLocationRecord *)popLocationRecord;
- (NSArray *)popLocationRecordForCount:(NSUInteger)count;
- (NSArray *)avaliableLocationRecords;
- (void)emptyLocationRecords;


// Sensor data stack
- (void)pushSensorRecord:(LBSenserRecord *)record;
- (void)pushSensorRecords:(NSArray *)records;
- (LBSenserRecord *)popSensorRecord;
- (NSArray *)popSensorRecordsForCount:(NSUInteger)count;
- (NSArray *)avaliableSensorRecords;
- (void)emptySensorRecords;


@end
