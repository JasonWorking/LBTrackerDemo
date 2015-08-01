//
//  LBDeviceInfoManager.h
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBDataCollectionScheduler.h"

extern NSString *const LBDeviceInfoManagerCoreMotionDataReadyNotification;
extern NSString *const LBDeviceInfoManagerSensorValueKey;


typedef void(^getDeviceIdCallback)(NSString *deviceId, NSError* err);

@interface LBDeviceInfoManager : NSObject

+ (instancetype)sharedInstance;


@property (nonatomic, strong) LBDataCollectionScheduler *scheduler;

@property (nonatomic, strong ) NSString *uuid;
@property (nonatomic, strong ) NSString *hardwareID;
@property (nonatomic, strong ) NSString *bundleID;
@property (nonatomic, strong ) NSString *deviceType;/// iOS


@property (nonatomic, strong) NSString *screenWidth;

@property (nonatomic,strong ) NSString *screenHigh;

/**屏幕分辨率*/
@property (nonatomic,strong ) NSString *screenPX;

/**IOS设备主机名称*/
@property(nonatomic,strong) NSString *host;

@property(nonatomic,strong) NSString *mobileBrand;


/**联通，移动之类的*/
@property(nonatomic,strong) NSString *mobileModel;

@property(nonatomic,strong) NSString *machine;

@property(nonatomic,strong) NSString *clientPostion;

@property(nonatomic,strong) NSString *systemType;

@property(nonatomic,strong) NSString *systemVersion;

/**国家代码*/
@property (nonatomic,strong) NSString *mcc;

/**网络代码*/
@property (nonatomic,strong) NSString *mnc;

/**wifi的名字*/
@property (nonatomic,strong) NSString *wifiNoteName;

/**是否有wifi*/
@property (nonatomic,strong) NSString *wifiActive;


@property (nonatomic,strong) NSString *batteryLevel;

@property(nonatomic,strong) NSMutableDictionary *coreMotionData;

/**开始传感器的监测*/
- (void)startCoreMotionMonitorClearData:(BOOL)clear;

/**关闭传感器的监测*/
- (void)stopCoreMotionMonitorClearData:(BOOL)clear;

/**陀螺仪*/
- (BOOL)isGyroscopeAvailable;
/**重力*/
- (BOOL)isGravityAvailable;
/**加速计*/
- (BOOL)isAccelerometerAvailable;
/**磁力计*/
- (BOOL)isMagnetAvailable;
/**距离感应器*/
- (BOOL)isProximityAvailable;


@end





@interface LBDeviceInfoManager (Network)

- (void)uploadDeviveInfoToServer;

@end


