//
//  LBSenserRecord.h
//  BgTracker
//
//  Created by Jason on 15/7/26.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMDeviceMotion;
@class CMGyroData;
@class CMMagnetometerData;

@interface LBSenserRecord : NSObject<NSCoding>

- (instancetype)init;
- (NSDictionary *)JSONRepresentation;

@property (nonatomic, assign) NSTimeInterval timestamp;  // in ms
@property (nonatomic, copy  ) NSString *senserName;
@property (nonatomic, strong) NSNumber *accuracy;
@property (nonatomic, strong) NSArray  *values;

@end


@interface LBAccelerateRecord : LBSenserRecord

- (instancetype)initWithDeviceMotion:(CMDeviceMotion *)motion;

@end


@interface LBGravityRecord : LBSenserRecord

- (instancetype)initWithDeviceMotion:(CMDeviceMotion *)motion;

@end


@interface LBGyroRecord : LBSenserRecord

- (instancetype)initWithCMGyroData:(CMGyroData *)gyroData;

@end



@interface LBMagnetometerRecord : LBSenserRecord

- (instancetype)initWithMagnatometerData:(CMMagnetometerData *)data;

@end
