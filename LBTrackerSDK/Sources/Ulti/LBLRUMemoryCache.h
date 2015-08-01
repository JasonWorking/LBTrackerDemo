//
//  LBLRUMemoryCache.h
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface LBLRUMemoryCache : NSObject

@property (nonatomic, assign) BOOL handleMemoryWarning; // default NO
@property (nonatomic, assign, readonly) NSInteger capacity;

- (id)initWithCapacity:(NSInteger)capacity;

- (void)setObject:(id)object forKey:(NSString*)key;

- (void)setObject:(id)object forKey:(NSString*)key expire:(NSTimeInterval)expire;

- (id)objectForKey:(NSString*)key;

- (void)removeObjectForKey:(NSString*)key;

- (void)removeAllObjects;

- (void)addObjects:(NSDictionary*)objects;

- (void)removeObjectsWithRegex:(NSString*)regex;

- (void)removeObjectsWithPrefix:(NSString*)prefix;

- (void)removeObjectsWithSuffix:(NSString*)suffix;

- (void)removeObjectsWithKeys:(NSSet*)keys;

/**
 *  将缓存对象读取到一个数组里，但不做LRU缓存策略处理。fromHead为YES时，从头开始遍历，否则对尾开始遍历。
 */
- (NSArray*)peekObjects:(NSInteger)count fromHead:(BOOL)fromHead;

/**
 *  快速判断某个key的对象是否存在
 */
- (BOOL)objectExistsForKey:(NSString*)key;

/**
 *  更新容量，如果新容量比原先的小，会删除部分缓存
 */
- (void)resetCapacity:(NSInteger)capacity;

/**
 *  判断一个对象是否在缓存的前面（前5位），如果是的话，认为已经位于很靠前的位置。
 */
- (id)findObjectAtTopSequenceForKey:(NSString*)key atTop:(BOOL*)atTop;

@end
