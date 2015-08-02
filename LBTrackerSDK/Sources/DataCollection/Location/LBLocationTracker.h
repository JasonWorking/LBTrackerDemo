//
//  LBLocationTracker.h
//  BgTracker
//
//  Created by Jason on 15/7/27.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LBDataCollectionScheduler.h"


///位置信息获取 上传
@interface LBLocationTracker : NSObject <CLLocationManagerDelegate>

@property (nonatomic        ) CLLocationCoordinate2D myLastLocation;
@property (nonatomic        ) CLLocationAccuracy     myLastLocationAccuracy;
@property (nonatomic, assign) NSTimeInterval         dataColletionInterval;
@property (strong,nonatomic ) LBDataCollectionScheduler    * scheduler;

@property (nonatomic        ) CLLocationCoordinate2D myLocation;
@property (nonatomic        ) CLLocationAccuracy     myLocationAccuracy;

+ (CLLocationManager *)sharedLocationManager;

- (void)startLocationTracking;
- (void)startLocationTrackingWithTimeInterval:(NSTimeInterval)time;
- (void)stopLocationTracking;


@end



@interface LBLocationTracker (Network)

- (void)uploadLocationToServer;

@end