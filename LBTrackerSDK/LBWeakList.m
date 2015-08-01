//
//  WeakList.m
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import "LBWeakList.h"

@interface LBWeakRef : NSObject
- (instancetype)initWithObject:(id)object;
@property (weak, readonly) id object;
@end

@implementation LBWeakRef

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) {
        _object = object;
    }
    return self;
}

@end

@implementation LBWeakList {
    NSMutableArray *_array;
}

- (instancetype)init {
    if (self = [super init]) {
        _array = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addObject:(id)object {
    LBWeakRef *ref = [[LBWeakRef alloc] initWithObject:object];
    [_array addObject:ref];
}

- (void)removeObject:(id)object {
    NSUInteger i = 0;
    while (i < _array.count) {
        LBWeakRef *ref = _array[i];
        id refObj = ref.object;
        if (refObj != nil) {
            if ([refObj isEqual:object]) {
                [_array removeObjectAtIndex:i];
                continue;
            }
        } else if (refObj == nil) {
            [_array removeObjectAtIndex:i];
            continue;
        }
        i++;
    }
}

- (void)forEach:(void (^)(id object))consumer {
    NSUInteger i = 0;
    while (i < _array.count) {
        LBWeakRef *ref = _array[i];
        id refObj = ref.object;
        if (refObj != nil) {
            consumer(refObj);
        } else if (refObj == nil) {
            [_array removeObjectAtIndex:i];
            continue;
        }
        i++;
    }
}

@end
