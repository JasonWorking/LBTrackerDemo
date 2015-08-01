//
//  LBRecordStack.h
//  BgTracker
//
//  Created by Jason on 15/7/26.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LBRecordStack : NSObject<NSCoding>

- (instancetype)initWithCapacity:(NSUInteger)capacity;

- (BOOL)isEmpty;
- (void)pushRecord:(id)record;
- (id)pop;
- (NSArray *)popForCount:(NSUInteger)count;
- (NSArray *)allRecords;


@end
