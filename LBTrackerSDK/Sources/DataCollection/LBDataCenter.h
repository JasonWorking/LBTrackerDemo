//
//  LBDataCenter.h
//  LBTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBSingleton.h"


@protocol LBDataCenterDelegate <NSObject>

- (void)dataCenterDidInitialized;
- (void)dataCenterDidFailToInitializeWithError:(NSError *)error;

@end


@interface LBDataCenter : NSObject

DEF_SINGLETON;

@property (nonatomic, weak) id<LBDataCenterDelegate>delegate;

+ (void)initializeDataCenterWithDelegate:(id<LBDataCenterDelegate>)delegate;

- (void)startDataColletionWithTimeInterval:(NSTimeInterval)time;

- (void)stopDataCollection;

@end
