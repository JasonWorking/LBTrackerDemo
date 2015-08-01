//
//  LBLocationShareModel.h
//  BgTracker
//
//  Created by Jason on 15/7/27.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "LBBackgroundTaskManager.h"
#import <CoreLocation/CoreLocation.h>
#import "LBSingleton.h"

@interface LBDataCollectionScheduler : NSObject

DEF_SINGLETON

@property (nonatomic, strong) NSTimer        *locationTimer;
@property (nonatomic, strong) NSTimer        * delay10Seconds;
@property (nonatomic, strong) NSMutableArray *myLocationArray;
@property (nonatomic, strong) LBBackgroundTaskManager * bgTask;


@end
