//
//  LBTrackerInterface.m
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import "LBTrackerInterface.h"
#import "LBHTTPClient.h"
#import "LBDataCenter.h"


///该类管理HTTPClient和DataCenter的生命周期
@interface LBTrackerInterface () <LBHTTPClientDelegate,LBDataCenterDelegate>
@property (nonatomic,assign ) BOOL started;
@property (nonatomic,assign ) BOOL clientReady;
@property (nonatomic,assign ) BOOL dataCenterReady;
@end


@implementation LBTrackerInterface

+ (LBTrackerInterface *)sharedInterface
{
    static LBTrackerInterface *_sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedTracker = [[LBTrackerInterface alloc] init];
    });
    return _sharedTracker;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)initalizeTrackerWithDelegate:(id<LBTrackerDelegate>)delegate appID:(NSString *)appID;
{
    [[self sharedInterface] initalizeTrackerWithDelegate:delegate appID:appID];

}

- (void)initalizeTrackerWithDelegate:(id<LBTrackerDelegate>)delegate appID:(NSString *)appID
{
    self.delegate = delegate;
    [LBDataCenter initializeDataCenterWithDelegate:self];
    [[LBHTTPClient sharedClient] initializeClientWithDelegate:self appID:appID];
}



+ (void)initalizeTrackerWithDelegate:(id<LBTrackerDelegate>)delegate retryCount:(NSUInteger)count
{
    // TODO :
}

/*启动Tracker,工作方式:
 1. 开启一次定位数据采集,和传感器数据采集.采集到数据后停掉定位和传感器.等待定时器唤起下一次数据采集.
 2. 每3分钟启动一次定位请求,同时启动一次连续10次的传感器数据采集.并启动数据上传
 */
+ (BOOL)startTracker
{
    return [self startTrackerWithUploadTimeInterval:1*60];

}

+ (BOOL)startTrackerWithUploadTimeInterval:(NSTimeInterval)time
{
    return [[self sharedInterface] startTrackerWithUploadTimeInterval:time];
}


- (BOOL)startTrackerWithUploadTimeInterval:(NSTimeInterval)time
{
    if (self.started) {
        [self stopTracker];
    }
    
    [[LBDataCenter sharedInstance] startDataColletionWithTimeInterval:time];
    
    self.started = YES;
    return YES;
    
}


+ (void)stopTracker
{
    [[self sharedInterface] stopTracker];
}

- (void)stopTracker
{
    [[LBDataCenter sharedInstance] stopDataCollection];
    self.started = NO;
}



#pragma mark - LBHTTPClientDelegate

- (void)HTTPClientDidInitializedWithInfo:(NSDictionary *)info;
{
    self.clientReady = YES;
    if (self.dataCenterReady) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(trackerDidInitialized)]) {
            [self.delegate trackerDidInitialized];
        }
    }
}

- (void)HTTPClientDidFailToInitializeWithError:(NSError *)error;
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(trackerDidFaileToInitializeWithError:)]) {
        [self.delegate trackerDidFaileToInitializeWithError:error];
    }
}

#pragma mark - LBDataCenterDelegate

- (void)dataCenterDidInitialized;
{
    self.dataCenterReady = YES;
    if (self.clientReady) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(trackerDidFaileToInitializeWithError:)]) {
            [self.delegate trackerDidInitialized];
        }
    }
}
- (void)dataCenterDidFailToInitializeWithError:(NSError *)error;
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(trackerDidFaileToInitializeWithError:)]) {
        [self.delegate trackerDidFaileToInitializeWithError:error];
    }
    
}





@end
