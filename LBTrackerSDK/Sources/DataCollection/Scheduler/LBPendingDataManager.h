//
//  LBPendingDataManager.h
//  SimpleWeather
//
//  Created by Jason on 15/8/2.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBSingleton.h"
#import "LBDataStore.h"

@interface LBPendingDataManager : NSObject

DEF_SINGLETON

@property (nonatomic, strong) LBDataStore *pendingData;

+ (void)pushPengdingLocation:(LBLocationRecord *)location;
+ (void)pushPengdingSensors:(NSArray *)sensors;

@end
