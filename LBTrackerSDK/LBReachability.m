//
//  LBReachability.m
//  LBTracker
//
//  Created by Jason on 15/7/24.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import "LBReachability.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

static CTTelephonyNetworkInfo *telephonyInfo;

@interface LBReachability ()

@property(nonatomic, strong) LBNetReachability *internetReach;

@end

@implementation LBReachability

+ (LBReachability *)sharedDTReachability
{
    static dispatch_once_t once;
    static LBReachability *instance;
    dispatch_once(&once, ^
    {
        instance = self.new;

        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
        
        instance.internetReach = [LBNetReachability reachabilityForInternetConnection];
        [instance.internetReach startNotifier];
        [instance updateWithReachability: instance.internetReach];
        
        telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        
    });
    return instance;
}

- (void)reachabilityChanged:(NSNotification *)note
{
    LBNetReachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[LBNetReachability class]]);
    [self updateWithReachability:curReach];
}

- (void)updateWithReachability:(LBNetReachability *)curReach
{
    if (curReach == self.internetReach)
    {
        self.networkStatus = [curReach currentReachabilityStatus];
    }
}

- (void)refreshReachability
{
    self.networkStatus = [self.internetReach currentReachabilityStatus];
}

- (BOOL)isReachableVia3G
{
    return [self.internetReach isReachableVia3G];
}

- (BOOL)isReachableVia2G
{
    return [self.internetReach isReachableVia2G];
}

- (CTTelephonyNetworkInfo *)telephonyInfo
{
    return telephonyInfo;
}

+ (NSString *)networkName {
    
    NetworkStatus networkStatus = [LBReachability sharedDTReachability].networkStatus;
    if (networkStatus == ReachableViaWiFi) {
        return @"WIFI";
    } else if (networkStatus == ReachableViaWWAN) {
        if ([telephonyInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) { // ios7及以上
            if ([[telephonyInfo currentRadioAccessTechnology] isEqualToString:CTRadioAccessTechnologyGPRS]) {
                return @"GPRS";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyEdge]) {
                return @"EDGE";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyWCDMA]) {
                return @"WCDMA";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyHSDPA]) {
                return @"HSDPA";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyHSUPA]) {
                return @"HSUPA";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
                return @"CDMA1X";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
                return @"CDMAEVDOREV0";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
                return @"CDMAEVDOREVA";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
                return @"CDMAEVDOREVB";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyeHRPD]) {
                return @"HRPD";
            } else if ([[telephonyInfo currentRadioAccessTechnology]  isEqualToString:CTRadioAccessTechnologyLTE]) {
                return @"LTE";
            }
            return @"UNKNOWN";
        } else {// ios7以下
            return @"WWAN";
        }
    } else {
        return @"NotReachable";
    }
}

@end
