//
//  LocationRecord.h
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


typedef NS_ENUM(NSInteger, LBMonitoringType) {
    LBNotMonitoring = 0,
    LBForegroundMonitoring = 1,
    LBBackgroundMonitoring = 2,
    LBExitRegion = 3,
    LBVisitedLocation = 4
};


@class CLLocation;

@interface LBLocationRecord : NSObject <NSCoding, NSCopying, MKAnnotation>

- (instancetype)init;
- (instancetype)initWithCLLocation:(CLLocation*)location monitoringType:(LBMonitoringType)type;
- (instancetype)initWithCLCoordinate2D:(CLLocationCoordinate2D)coordinate monitoringType:(LBMonitoringType)type;

@property (strong) NSDate *timestamp;
@property (assign) double horizontalAccuracy;
@property (assign) LBMonitoringType type;
@property (assign) double latitude;
@property (assign) double longitude;
@property (assign) double altitude;
@property (copy, readonly) NSString *locationDescription;

- (NSDictionary *)JSONRepresentation;

@end
