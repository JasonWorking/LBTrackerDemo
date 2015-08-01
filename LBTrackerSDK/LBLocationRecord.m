//
//  LocationRecord.m
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import "LBLocationRecord.h"
#import <CoreLocation/CoreLocation.h>

@interface LBLocationRecord ()

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@end


@implementation LBLocationRecord {
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (instancetype)initWithCLLocation:(CLLocation*)location monitoringType:(LBMonitoringType)type {
    if (self = [super init]) {
        self.timestamp = location.timestamp;
        self.type = type;
        self.latitude = location.coordinate.latitude;
        self.longitude = location.coordinate.longitude;
        self.altitude = location.altitude;
        self.horizontalAccuracy = location.horizontalAccuracy;
        _coordinate.latitude = self.latitude;
        _coordinate.longitude = self.longitude;
    }
    return self;
}

- (instancetype)initWithCLCoordinate2D:(CLLocationCoordinate2D)coordinate monitoringType:(LBMonitoringType)type {
    if (self = [super init]) {
        self.timestamp = [NSDate date];
        self.type = type;
        self.latitude = coordinate.latitude;
        self.longitude = coordinate.longitude;
        self.altitude = 0.0;
        _coordinate.latitude = self.latitude;
        _coordinate.longitude = self.longitude;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.timestamp = [decoder decodeObjectForKey:@"timestamp"];
        self.type = [decoder decodeIntegerForKey:@"type"];
        self.latitude = [decoder decodeDoubleForKey:@"latitude"];
        self.longitude = [decoder decodeDoubleForKey:@"longitude"];
        self.altitude = [decoder decodeDoubleForKey:@"altitude"];
        _coordinate.latitude = self.latitude;
        _coordinate.longitude = self.longitude;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeObject:self.timestamp forKey:@"timestamp"];
    [encoder encodeInteger:self.type forKey:@"type"];
    [encoder encodeDouble:self.latitude forKey:@"latitude"];
    [encoder encodeDouble:self.longitude forKey:@"longitude"];
    [encoder encodeDouble:self.altitude forKey:@"altitude"];
}

- (id)copyWithZone:( NSZone *)zone {
    LBLocationRecord *record = [[LBLocationRecord alloc] init];
    record.timestamp = self.timestamp;
    record.type = self.type;
    record.latitude = self.latitude;
    record.longitude = self.longitude;
    record.altitude = self.altitude;
    record->_coordinate.latitude = self.latitude;
    record->_coordinate.longitude = self.longitude;
    return record;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[Lat=%+.4f,Lng=%+.4f]", self.latitude, self.longitude];
}

- (NSString *)locationDescription {
    if (self.type == LBBackgroundMonitoring) {
        return [NSString stringWithFormat:@"%@ (SCLS)", self.description];
    } else if (self.type == LBExitRegion) {
        return [NSString stringWithFormat:@"%@ (Exit Region)", self.description];
    } else if (self.type == LBVisitedLocation) {
        return [NSString stringWithFormat:@"%@ (Visited Location)", self.description];
    } else {
        return [NSString stringWithFormat:@"%@", self.description];
    }
}

#pragma mark - JSON transfer
- (NSDictionary *)JSONRepresentation
{
    return @{@"__type":@"GeoPoint",
                           @"latitude":@(self.coordinate.latitude),
                           @"longitude":@(self.coordinate.longitude)};
}


#pragma mark - MKAnnotaion

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D result = _coordinate;
    // HuoXing Magic
    result.latitude += 0.0015;
    result.longitude += 0.00625;
    return result;
}

- (NSString *)title {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init] ;
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    return [dateFormatter stringFromDate:self.timestamp];
}

- (NSString *)subtitle {
    return self.locationDescription;
}

@end
