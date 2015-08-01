//
//  WeakList.h
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBWeakList : NSObject

- (instancetype)init;
- (void)addObject:(id)object;
- (void)removeObject:(id)object;
- (void)forEach:(void (^)(id object))consumer;

@end
