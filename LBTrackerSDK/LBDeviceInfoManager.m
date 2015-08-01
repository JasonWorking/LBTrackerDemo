//
//  LBDeviceInfoManager.h
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import "LBDeviceInfoManager.h"

#import <CoreMotion/CoreMotion.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "LBReachability.h"
#import <sys/utsname.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <UIKit/UIKit.h>
#import "LBHTTPClient.h"
#import "LBSenserRecord.h"

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

#define kLBTackerUUIDKey     @"kLBTackerUUIDKey"
/**重力*/
#define GravityKey           @"Gravity"

/**加速度*/
#define AccelerometerKey     @"Accelerometer"

/**陀螺仪*/
#define GyroscopeKey         @"Gyroscope"

/**磁场*/
#define MagnetometerKey      @"Magnetometer"

/**最多的次数*/
#define MAX_NUMBER           10

/**间隔秒数*/
#define UPDATE_INTERVAL      3

static LBDeviceInfoManager *s_deviceInfo = nil;
NSString *const LBDeviceInfoManagerCoreMotionDataReadyNotification =  @"LBDeviceInfoManagerCoreMotionDataReadyNotification";

NSString *const LBDeviceInfoManagerSensorValueKey = @"LBDeviceInfoManagerSensorValueKey";

@interface LBDeviceInfoManager() {
    NSString *_cachedApdid;
    dispatch_queue_t _apdidUpdateQueue;
    
    NSCondition *_condition;
    
    NSString *_initedUmidToken;
    BOOL _isUmidTokenInitGettingFinished;
    BOOL _isPerformingUmidTokenInit;
}

@property(nonatomic,strong) CMMotionManager *motionManager;
@property(nonatomic,strong) CTTelephonyNetworkInfo *networkInfo;
@property(nonatomic,assign) BOOL accReady;
@property(nonatomic,assign) BOOL gyroReady;
@property(nonatomic,assign) BOOL gravReady;
@property(nonatomic,assign) BOOL magReady;

@end

@implementation LBDeviceInfoManager
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_deviceInfo = [[LBDeviceInfoManager alloc] init];
    });
    
    return s_deviceInfo;
}

- (id)init {
    if (self=[super init]) {
        
        
        self.motionManager = [[CMMotionManager alloc] init];
        self.networkInfo = [[CTTelephonyNetworkInfo alloc] init];
        
        _apdidUpdateQueue = dispatch_queue_create(NULL, NULL);
        _condition = [[NSCondition alloc] init];
        _scheduler = [LBDataCollectionScheduler sharedInstance];
        _isUmidTokenInitGettingFinished = NO;
        _isPerformingUmidTokenInit = NO;
        
    }
    return self;
}

- (NSString *)screenWidth {
    if (!_screenWidth) {
        _screenWidth = [NSString stringWithFormat:@"%.0f",[UIScreen mainScreen].bounds.size.width];
    }
    return _screenWidth;
}

- (NSString *)screenHigh {
    return [NSString stringWithFormat:@"%.0f",[UIScreen mainScreen].bounds.size.height];
}

- (NSString *)hardwareID
{
    return [self uuid];
}

-( NSString *)bundleID
{
    if (!_bundleID) {
        _bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    }
    return _bundleID;
}


- (NSString *)uuid{
    
    if (!_uuid) {
        NSString *uuid = [[NSUserDefaults  standardUserDefaults] objectForKey:kLBTackerUUIDKey];
        if (uuid && [uuid length] > 0) {
            _uuid = uuid;
        }else {
            uuid = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults  standardUserDefaults] setObject:uuid forKey:kLBTackerUUIDKey];
            [[NSUserDefaults  standardUserDefaults] synchronize];
//            uuid = [APMD5 calculateDigestFromString:uuid];
            _uuid = uuid;
        }
    }
    return _uuid;
}

- (NSString *)mobileBrand {
    return @"Apple";
}

- (NSString *)systemType {
    return @"IOS";
}

- (NSString *)ipAddress
{
    NSArray *searchArray = @[ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}


- (NSString *)machine {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}

- (NSString *)systemVersion {
    return [UIDevice currentDevice].systemVersion;
}

- (NSString *)mobileModel {
    return self.networkInfo.subscriberCellularProvider.carrierName;
}

- (NSString *)mcc {
    return self.networkInfo.subscriberCellularProvider.mobileCountryCode;
}

- (NSString *)mnc {
    return self.networkInfo.subscriberCellularProvider.mobileNetworkCode;
}

- (NSString *)host {
    return [UIDevice currentDevice].name;
}


#pragma mark -

- (NSString *)screenPX {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    NSString *result = [NSString stringWithFormat:@"%.0f*%.0f", width*scale, height*scale];
    return result;
}

- (NSString *)wifiActive {
    return ([[LBNetReachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable) ? @"1" : @"0";
}

- (NSString *)batteryLevel
{
    return [NSString stringWithFormat:@"%f", [[UIDevice currentDevice] batteryLevel]];
}

- (NSString *)wifiNoteName {
    NSString *ssid = nil;
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        CFRelease(myArray);
        
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            
            //wifi的名字
            ssid = [dict valueForKey:(NSString *)kCNNetworkInfoKeySSID];
            if (ssid) {
                return [[NSString alloc] initWithFormat:@"%@", ssid];
            }
        }
    }
    return nil;
}

- (void)startCoreMotionMonitorClearData:(BOOL)clear {
    
    
    if (([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)) {
        [self.scheduler.bgTask beginNewBackgroundTask];
    }
    
    if (clear) {
        self.coreMotionData = [NSMutableDictionary dictionary];
        
        [self.coreMotionData setObject:[NSMutableArray array] forKey:GravityKey];
        
        [self.coreMotionData setObject:[NSMutableArray array] forKey:AccelerometerKey];
        
        [self.coreMotionData setObject:[NSMutableArray array] forKey:GyroscopeKey];
        
        [self.coreMotionData setObject:[NSMutableArray array] forKey:MagnetometerKey];
    }
    
    /**重力和线性加速度*/
    [self startDeviceMotionUpdate];
    
    [self startGyroscopeUpdate];
    
    [self startMagnetometerUpdate];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appResignActiveAction:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appTerminateAction:) name:UIApplicationWillTerminateNotification object:nil];
}


- (void)appEnterBackground:(NSNotification *)notify
{
    [self startCoreMotionMonitorClearData:NO];
}

- (void)appResignActiveAction:(NSNotification *)notify {
    [self stopCoreMotionMonitorClearData:NO];
}

- (void)appTerminateAction:(NSNotification *)notify {
    [self stopCoreMotionMonitorClearData:YES];
}

- (void) startDeviceMotionUpdate {
    if (!self.motionManager.deviceMotionAvailable) {
        return;
    }
    self.motionManager.deviceMotionUpdateInterval = UPDATE_INTERVAL;
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        if (error == nil) {
            if ([[self.coreMotionData objectForKey:AccelerometerKey] count] < MAX_NUMBER) {
                NSLog(@"acc: %@",@{@"x":[NSNumber numberWithDouble:motion.userAcceleration.x],@"y":[NSNumber numberWithDouble:motion.userAcceleration.y],@"z":[NSNumber numberWithDouble:motion.userAcceleration.z]});
                [[self.coreMotionData objectForKey:AccelerometerKey] addObject:motion];
            }
            
            if ([[self.coreMotionData objectForKey:GravityKey] count] < MAX_NUMBER) {
                NSLog(@"grav: %@",@{@"x":[NSNumber numberWithDouble:motion.gravity.x],@"y":[NSNumber numberWithDouble:motion.gravity.y],@"z":[NSNumber numberWithDouble:motion.gravity.z]});
                [[self.coreMotionData objectForKey:GravityKey] addObject:motion];
            }
            
        }
        if ([[self.coreMotionData objectForKey:AccelerometerKey] count] >= MAX_NUMBER && [[self.coreMotionData objectForKey:GravityKey] count] >= MAX_NUMBER) {
            [self notifySensorRecordsAvaliable:[self.coreMotionData objectForKey:GravityKey]];
            self.accReady = YES;
            self.gravReady = YES;
            [self.motionManager stopDeviceMotionUpdates];
        }
    }];
}

- (void) startGyroscopeUpdate {
    if (!self.motionManager.gyroAvailable) {
        return;
    }
    self.motionManager.gyroUpdateInterval = UPDATE_INTERVAL;
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
        if (error == nil) {
            if ([[self.coreMotionData objectForKey:GyroscopeKey] count] < MAX_NUMBER) {
                NSLog(@"gyro: %@",@{@"x":[NSNumber numberWithDouble:gyroData.rotationRate.x],@"y":[NSNumber numberWithDouble:gyroData.rotationRate.y],@"z":[NSNumber numberWithDouble:gyroData.rotationRate.z]});
                [[self.coreMotionData objectForKey:GyroscopeKey] addObject:gyroData];
            }
        }
        
        if ([[self.coreMotionData objectForKey:GyroscopeKey] count] >= MAX_NUMBER) {
            [self notifySensorRecordsAvaliable:[self.coreMotionData objectForKey:GyroscopeKey]];
            self.gyroReady  = YES;
            [self.motionManager stopGyroUpdates];
        }
    }];
}

- (void) startMagnetometerUpdate {
    if (!self.motionManager.magnetometerAvailable) {
        return;
    }
    self.motionManager.magnetometerUpdateInterval = UPDATE_INTERVAL;
    [self.motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
        if (error == nil) {
            if ([[self.coreMotionData objectForKey:MagnetometerKey] count] < MAX_NUMBER) {
                NSLog(@"magnet: %@",@{@"x":[NSNumber numberWithDouble:magnetometerData.magneticField.x],@"y":[NSNumber numberWithDouble:magnetometerData.magneticField.y],@"z":[NSNumber numberWithDouble:magnetometerData.magneticField.z]});
                [[self.coreMotionData objectForKey:MagnetometerKey] addObject:magnetometerData];
            }
        }
        
        if ([[self.coreMotionData objectForKey:MagnetometerKey] count] >= MAX_NUMBER) {
            [self notifySensorRecordsAvaliable:[self.coreMotionData objectForKey:MagnetometerKey]];
            self.magReady = YES;
            [self.motionManager stopMagnetometerUpdates];
        }
    }];
}

- (void)stopCoreMotionMonitorClearData:(BOOL)clear {
    
    if (self.motionManager.deviceMotionActive) {
        [self.motionManager stopDeviceMotionUpdates];
    }
    if (self.motionManager.gyroActive) {
        [self.motionManager stopGyroUpdates];
    }
    if (self.motionManager.magnetometerActive) {
        [self.motionManager stopMagnetometerUpdates];
    }
    
    if (clear) {
        self.coreMotionData = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
}

/**陀螺仪*/
- (BOOL)isGyroscopeAvailable  {
    return self.motionManager.isGyroAvailable;
}

/**重力*/
- (BOOL)isGravityAvailable {
    return self.motionManager.isAccelerometerAvailable;
}

/**加速计*/
- (BOOL)isAccelerometerAvailable {
    return self.motionManager.isAccelerometerAvailable;
}

/**磁力计*/
- (BOOL)isMagnetAvailable {
    return self.motionManager.isMagnetometerAvailable;
}

/**距离感应器*/
- (BOOL)isProximityAvailable {
    BOOL haveOne = NO;
    
    BOOL oldValue = [UIDevice currentDevice].isProximityMonitoringEnabled;
    //检测感应器是否存在
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    haveOne = [UIDevice currentDevice].proximityMonitoringEnabled;
    
    //恢复老的值
    [UIDevice currentDevice].proximityMonitoringEnabled = oldValue;
    
    return haveOne;
}

#pragma mark - 

- (void)notifySensorRecordsAvaliable:(NSArray *)records
{
    [[NSNotificationCenter defaultCenter] postNotificationName:LBDeviceInfoManagerCoreMotionDataReadyNotification
                                                        object:self
                                                      userInfo:@{LBDeviceInfoManagerSensorValueKey:records}];
}
#pragma mark - utils
- (void)wait {
    [_condition lock];
    [_condition wait];
    [_condition unlock];
}

- (void)signalWaitCondition {
    [_condition lock];
    [_condition signal];
    [_condition unlock];
}

@end




@implementation LBDeviceInfoManager (Network)


- (void)uploadDeviveInfoToServer
{
    NSLog(@"upload device info to server ");
    
    NSMutableArray *sensorRecordsToUpload = [NSMutableArray array];
    
    [self.coreMotionData enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSArray* obj, BOOL *stop) {
        
        
        if ([key isEqualToString:AccelerometerKey]) {
            for (CMDeviceMotion *motion  in obj) {
                LBAccelerateRecord *acc = [[LBAccelerateRecord alloc] initWithDeviceMotion:motion];
                [sensorRecordsToUpload addObject:acc];
            }
        }
        
        if ([key isEqualToString:GravityKey]) {
            for (CMDeviceMotion *motion  in obj) {
                LBGravityRecord *grav = [[LBGravityRecord alloc] initWithDeviceMotion:motion];
                [sensorRecordsToUpload addObject:grav];
            }
        }
        
        if ([key isEqualToString:GyroscopeKey]) {
            for (CMGyroData *data  in obj) {
                LBGyroRecord *gyro = [[LBGyroRecord alloc] initWithCMGyroData:data];
                [sensorRecordsToUpload addObject:gyro];
            }
        }
        
        
        if ([key isEqualToString:MagnetometerKey]) {
            for (CMMagnetometerData *data  in obj) {
                LBMagnetometerRecord *mag = [[LBMagnetometerRecord alloc] initWithMagnatometerData:data];
                [sensorRecordsToUpload addObject:mag];
            }
        }

        
    }];
    
    
    [LBHTTPClient uploadSensorRecords:sensorRecordsToUpload
                            onSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"upload sensor success ");
    }
                            onFailure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"upload sensor failed ");
    }];
    
}


@end


