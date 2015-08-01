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
- (NSArray *)avaliableLocationRecords;

- (void)pushPendingLocationRecord:(LBLocationRecord *)record;
- (LBLocationRecord *)popPendingLocationRecord;
- (NSArray *)pendingLocationRecords;


// Sensor data stack
- (void)pushSensorRecord:(LBSenserRecord *)record;
- (void)pushSensorRecords:(NSArray *)records;
- (LBSenserRecord *)popSensorRecord;
- (NSArray *)popSensorRecordsForCount:(NSUInteger)count;
- (NSArray *)avaliableSensorRecords;

- (void)pushPendingSensorRecord:(LBSenserRecord *)record;
- (LBSenserRecord *)popPendingSensorRecord;
- (void)pushPendingSensorRecords:(NSArray *)records;
- (NSArray *)popPendingSensorRecordsForCount:(NSUInteger)count;
- (NSArray *)pendingSensorRecords;


@end
