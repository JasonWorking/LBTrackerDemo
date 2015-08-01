//
//  LBTrackerInterface.h
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LBTrackerDelegate <NSObject>
- (void)trackerDidInitialized;
- (void)trackerDidFaileToInitializeWithError:(NSError *)error;
@end

///对外接口类
@interface LBTrackerInterface : NSObject

+ (LBTrackerInterface *)sharedInterface;

@property (nonatomic, weak) id<LBTrackerDelegate> delegate;

+ (void)initalizeTrackerWithDelegate:(id<LBTrackerDelegate>)delegate appID:(NSString *)appID;

/// Use default upload time interval = 10*60
+ (BOOL)startTracker;

+ (BOOL)startTrackerWithUploadTimeInterval:(NSTimeInterval)time;

+ (void)stopTracker;


// TODO: support retry
+ (void)initalizeTrackerWithDelegate:(id<LBTrackerDelegate>)delegate retryCount:(NSUInteger)count;
@end
