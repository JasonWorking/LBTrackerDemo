//
//  LBLogger.h
//  SimpleWeather
//
//  Created by Jason on 15/8/2.
//  Copyright (c) 2015年 Ryan Nystrom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBSingleton.h"


@interface LBLogger : NSObject

DEF_SINGLETON

+ (void)logString:(NSString *)log toFile:(NSString *)fileName;


@end
