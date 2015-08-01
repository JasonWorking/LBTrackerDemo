//
//  LBSingleton.h
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#ifndef BgTracker_LBSingleton_h
#define BgTracker_LBSingleton_h

#define DEF_SINGLETON + (instancetype)sharedInstance;

#if __has_feature(objc_arc)

#define IMP_SINGLETON \
+ (instancetype)sharedInstance { \
static id sharedObject = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
sharedObject = [[self alloc] init]; \
}); \
return sharedObject; \
}\
- (id)copyWithZone:(NSZone*)zone{\
return self;\
}

#else

#define IMP_SINGLETON \
+ (instancetype)sharedInstance { \
static id sharedObject = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
sharedObject = [[self alloc] init]; \
}); \
return sharedObject; \
}\
- (id)copyWithZone:(NSZone*)zone{\
return self;\
}\
- (id)retain{\
return self;\
}\
- (NSUInteger)retainCount{\
return NSUIntegerMax;\
}\
- (oneway void)release{\
}\
- (id)autorelease{\
return self;\
}

#endif
#endif
