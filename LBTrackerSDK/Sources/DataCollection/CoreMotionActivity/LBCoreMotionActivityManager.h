//
//  LBCoreMotionActivityManager.h
//  SimpleWeather
//
//  Created by Jason on 15/8/2.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBSingleton.h"



@interface LBCoreMotionActivityManager : NSObject

DEF_SINGLETON

- (void)startQueryMotionActivity;

@end


@interface LBCoreMotionActivityManager (Network)

- (void)uploadCoreMotionActivitysToServer:(NSArray *)activities;

@end
