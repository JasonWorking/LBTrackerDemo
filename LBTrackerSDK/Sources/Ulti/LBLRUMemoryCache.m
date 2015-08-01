//
//  LBLRUMemoryCache.m
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "LBLRUMemoryCache.h"


#define CAPACITY_MIN 10
#define CAPACITY_THRESHOLD 10

@interface APLRUMemoryCacheNode : NSObject

@property (nonatomic, strong) NSString* key;
@property (nonatomic, strong) id data;
@property (nonatomic, assign) NSTimeInterval expire;
@property (nonatomic, weak) APLRUMemoryCacheNode* prev;
@property (nonatomic, weak) APLRUMemoryCacheNode* next;

@end

@implementation APLRUMemoryCacheNode

@end

#pragma mark -

@interface LBLRUMemoryCache ()
{
    NSInteger _capacity;
    
    APLRUMemoryCacheNode* _head;
    APLRUMemoryCacheNode* _tail;
    NSMutableDictionary* _hash;
    NSRecursiveLock* _hashLock;
}

@end

@implementation LBLRUMemoryCache

@synthesize capacity = _capacity;

- (id)initWithCapacity:(NSInteger)capacity
{
    if (self = [super init])
    {
        if (capacity <= 0)
            capacity = CAPACITY_MIN;
        _capacity = capacity;
        _hashLock = [[NSRecursiveLock alloc] init];
        _hash = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString*)description
{
    NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:20 * [_hash count]];
    if (desc == nil)
        return @"";
        
    APLRUMemoryCacheNode* iterator = _head;
    while (iterator != nil)
    {
        [desc appendFormat:@"%@\n", iterator.data];
        iterator = iterator.next;
    }
    return desc;
}

- (void)setHandleMemoryWarning:(BOOL)handleMemoryWarning
{
    if (_handleMemoryWarning != handleMemoryWarning)
    {
        if (handleMemoryWarning)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(removeAllObjects)
                                                         name:UIApplicationDidReceiveMemoryWarningNotification
                                                       object:nil];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
        }
        
        _handleMemoryWarning = handleMemoryWarning;
    }
}

- (void)setObject:(id)object forKey:(NSString*)key
{
    [self setObject:object forKey:key expire:0.0f];
}

- (void)setObject:(id)object forKey:(NSString*)key expire:(NSTimeInterval)expire
{
    if (key == nil)
        return;
    if (object == nil)
    {
        [self removeObjectForKey:key];
        return;
    }
    
    @try
    {
        [_hashLock lock];
        APLRUMemoryCacheNode* node = _hash[key];
        if (node == nil)
        {
            // 如果expire小于0，在lock里检测到key已经不存在了，就不要再set进去，解决多线程问题。
            if (expire < 0.0f)
                return;
            
            //缓存容器是否已经超过大小。使用CAPACITY_THRESHOLD是为了提高缓存满的状态时的效率
            if ([_hash count] >= _capacity + CAPACITY_THRESHOLD)
            {
                // 先移除过期的对象
                [self removeExpiredNodes];
                
                // 如果缓存容量仍然超过大小
                if ([_hash count] >= _capacity + CAPACITY_THRESHOLD)
                    [self removeTailNodes];
            }
            node = [[APLRUMemoryCacheNode alloc] init];
            node.key = key;
            _hash[key] = node;
        }
        if (expire < 0.0f)
            expire = 0.0f;
        node.data = object;
        node.expire = expire;
        [self moveNodeToHead:node];
    }
    @finally
    {
        [_hashLock unlock];
    }
}

- (id)objectForKey:(NSString*)key
{
    if (key == nil)
        return nil;
    
    @try
    {
        [_hashLock lock];
        APLRUMemoryCacheNode* node = _hash[key];
        if (node != nil)
        {
            id data = nil;
            if (node.expire != 0.0f && [[NSDate date] timeIntervalSince1970] > node.expire)
            {
                // 过期了
                [self removeObjectForKey:key];
            }
            else
            {
                [self moveNodeToHead:node];
                data = node.data;
            }
            return data;
        }
        return nil;
    }
    @finally
    {
        [_hashLock unlock];
    }
}

- (void)removeObjectForKey:(NSString*)key
{
    if (key == nil)
        return;
    
    @try
    {
        [_hashLock lock];
        APLRUMemoryCacheNode* node = _hash[key];
        [self removeNode:node];
    }
    @finally
    {
        [_hashLock unlock];
    }
}

- (void)removeAllObjects
{
    @try
    {
        [_hashLock lock];
        [_hash removeAllObjects];
        _head = nil;
        _tail = nil;
    }
    @finally
    {
        [_hashLock unlock];
    }
}

- (void)addObjects:(NSDictionary*)objects
{
    @try
    {
        [_hashLock lock];
        
        // 把items添加到链表头
        NSMutableArray* newNodes = [[NSMutableArray alloc] initWithCapacity:[objects count]];
        if ([_hash count] == 0)
        {
            [objects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                APLRUMemoryCacheNode* node = [[APLRUMemoryCacheNode alloc] init];
                node.key = key;
                node.data = obj;
                _hash[key] = node;
                [newNodes addObject:node];
            }];
        }
        else
        {
            [objects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                APLRUMemoryCacheNode* node = _hash[key];
                if (node)
                {
                    node.data = obj;
                    node.expire = 0.0f;
                    [self moveNodeToHead:node];
                }
                else
                {
                    node = [[APLRUMemoryCacheNode alloc] init];
                    node.key = key;
                    node.data = obj;
                    _hash[key] = node;
                    [newNodes addObject:node];
                }
            }];
        }
        
        if ([newNodes count] > 0)
        {
            // 生成新链表
            APLRUMemoryCacheNode* newHead, *newTail;
            newHead = newTail = newNodes[0];
            for (NSUInteger i = 1; i < [newNodes count]; i ++)
            {
                APLRUMemoryCacheNode* node = newNodes[i];
                newTail.next = node;
                node.prev = newTail;
                newTail = node;
            }
            
            // 接到原链表上
            if (_head)
            {
                _head.prev = newTail;
                newTail.next = _head;
                _head = newHead;
            }
            else
            {
                _head = newHead;
                _tail = newTail;
            }
            
            // 移除超出容量的
            [self removeTailNodes];
        }
    }
    @finally
    {
        [_hashLock unlock];
    }
}

- (void)removeObjectsWithConditionBlock:(BOOL(^)(APLRUMemoryCacheNode* node))block
{
    @try
    {
        [_hashLock lock];
        APLRUMemoryCacheNode* iterator = _head;
        while (iterator != nil)
        {
            if (block(iterator))
                [self removeNode:iterator];
            iterator = iterator.next;
        }
    }
    @finally
    {
        [_hashLock unlock];
    }
}

- (void)removeObjectsWithRegex:(NSString*)regex
{
    if (regex == nil)
        return;
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    [self removeObjectsWithConditionBlock:^BOOL(APLRUMemoryCacheNode *node) {
        return [predicate evaluateWithObject:node.key];
    }];
}

- (void)removeObjectsWithPrefix:(NSString*)prefix
{
    if (prefix == nil)
        return;
    
    [self removeObjectsWithConditionBlock:^BOOL(APLRUMemoryCacheNode *node) {
        return [node.key hasPrefix:prefix];
    }];
}

- (void)removeObjectsWithSuffix:(NSString*)suffix
{
    if (suffix == nil)
        return;
    
    [self removeObjectsWithConditionBlock:^BOOL(APLRUMemoryCacheNode *node) {
        return [node.key hasSuffix:suffix];
    }];
}

- (void)removeObjectsWithKeys:(NSSet*)keys
{
    if (keys == nil)
        return;
    
    [self removeObjectsWithConditionBlock:^BOOL(APLRUMemoryCacheNode *node) {
        return [keys containsObject:node.key];
    }];
}

- (NSArray*)peekObjects:(NSInteger)count fromHead:(BOOL)fromHead
{
    NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:count];
    if (count > 0)
    {
        @try
        {
            [_hashLock lock];
            if (fromHead)
            {
                APLRUMemoryCacheNode* node = _head;
                while (count > 0 && node != nil)
                {
                    [result addObject:node.data];
                    node = node.next;
                    count --;
                }
            }
            else
            {
                APLRUMemoryCacheNode* node = _tail;
                while (count > 0 && node != nil)
                {
                    [result addObject:node.data];
                    node = node.prev;
                    count --;
                }
            }
        }
        @finally
        {
            [_hashLock unlock];
        }
    }
    return result;
}

- (BOOL)objectExistsForKey:(NSString*)key
{
    @try
    {
        [_hashLock lock];
        return _hash[key] != nil;
    }
    @finally
    {
        [_hashLock unlock];
    }
}

- (void)resetCapacity:(NSInteger)capacity
{
    if (capacity <= 0)
        capacity = CAPACITY_MIN;
    
    if (capacity >= _capacity)
    {
        _capacity = capacity;
        return;
    }
    
    _capacity = capacity;
    @try
    {
        [_hashLock lock];
        [self removeTailNodes];
    }
    @finally
    {
        [_hashLock unlock];
    }
}

- (id)findObjectAtTopSequenceForKey:(NSString*)key atTop:(BOOL*)atTop
{
    @try
    {
        [_hashLock lock];
        APLRUMemoryCacheNode* node = _hash[key];
        if (node == nil) // 不在内存缓存里
            return nil;
        
        // 判断是不是在前面
        *atTop = NO;
        NSInteger index = 0;
        APLRUMemoryCacheNode* iterator = _head;
        while (iterator != nil && index < 5)
        {
            if (node == iterator)
            {
                *atTop = YES;
                break;
            }
                
            iterator = iterator.next;
            index ++;
        }
        
        //应用一下LRU规则
        [self moveNodeToHead:node];
        
        // 返回数据
        return node.data;
    }
    @finally
    {
        [_hashLock unlock];
    }
}

#pragma mark - private

- (void)removeNode:(APLRUMemoryCacheNode*)node
{
    if (node != nil)
    {
        if (node.prev != nil)
            node.prev.next = node.next;
        if (node.next != nil)
            node.next.prev = node.prev;
        if (_tail == node)
            _tail = node.prev;
        if (_head == node)
            _head = node.next;
        [_hash removeObjectForKey:node.key];
    }
}

- (void)removeExpiredNodes
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    [self removeObjectsWithConditionBlock:^BOOL(APLRUMemoryCacheNode *node) {
        return (node.expire != 0.0f && now > node.expire);
    }];
}

- (void)moveNodeToHead:(APLRUMemoryCacheNode*)node
{
    if (node == _head)
        return;
    if (node.prev != nil)
        node.prev.next = node.next;
    if (node.next != nil)
        node.next.prev = node.prev;
    if (_tail == node)
        _tail = node.prev;
    if (_head != nil) {
        node.next = _head;
        _head.prev = node;
    }
    _head = node;
    node.prev = nil;
    if (_tail == nil)
        _tail = _head;
}

- (void)removeTailNodes
{
    // 删除尾部结点，直到[_hash count] == _capacity - 1
    while (_tail != nil && [_hash count] >= _capacity)
        [self removeNode:_tail];
}

@end
