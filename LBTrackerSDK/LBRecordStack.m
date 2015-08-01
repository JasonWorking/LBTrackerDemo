//
//  LBRecordStack.m
//  BgTracker
//
//  Created by Jason on 15/7/26.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import "LBRecordStack.h"


@interface LBRecordStack ()

@property (nonatomic ,strong) NSMutableArray *array;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, assign) NSUInteger capacity;
@end

@implementation LBRecordStack

- (instancetype)initWithCapacity:(NSUInteger)capacity
{
    if (self = [super init]) {
        _capacity = capacity;
        _array = [NSMutableArray arrayWithCapacity:capacity];
        _lock  = [NSRecursiveLock new];
    }
    
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    [aCoder encodeObject:@(self.capacity) forKey:@"capacity"];
    [aCoder encodeObject:self.array forKey:@"array"];
}


- (id)initWithCoder:(NSCoder *)aDecoder;
{
    if (self = [super init]) {
        self.capacity = [[aDecoder decodeObjectForKey:@"capacity"] integerValue];
        self.array = [aDecoder decodeObjectForKey:@"array"];
        _lock = [NSRecursiveLock new];
    }
    
    return self;
}


- (BOOL)isEmpty
{
    BOOL isEmpaty = YES;
    [self.lock lock];
    if ([self.array count]) {
        isEmpaty = NO;
    }
    [self.lock unlock];
    return isEmpaty;
}


- (void)pushRecord:(id)record
{
    [self.lock lock];
    if ([self.array count] + 1  >=  self.capacity) {
        [self.array removeLastObject];
    }
    [self.array insertObject:record atIndex:0];
    [self.lock lock];

}

- (id)pop
{
    id record = nil;
    
    [self.lock lock];
    
    if ([self.array count]) {
        record = self.array[0];
        [self.array removeObjectAtIndex:0];
    }
    [self.lock unlock];
    
    return record;
}

- (NSArray *)popForCount:(NSUInteger)count
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    [self.lock lock];
    for (NSUInteger i = 0; i < count && i < [self.array count]; i++) {
        [result addObject:self.array[i]];
        [self.array removeObjectAtIndex:i];
    }
    
    [self.lock unlock];
    return result;
}

- (NSArray *)allRecords;
{
    return  [self.array copy];;
}


@end
