//
//  LBHTTPClient.m
//  LBTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import "LBHTTPClient.h"
#import "LBRequstSerializer.h"
#import "LBInstallation.h"
#import "LBDeviceInfoManager.h"
#import "LBLocationRecord.h"
#import "LBSenserRecord.h"
#import "LBDataCenter.h"
#import "LBLogger.h"
#import "CMMotionActivity+JSON.h"


static NSString *const  kLBHTTPClientLogFile = @"LBHTTPClientLogFile";

NSString *const LBHTTPClientErrorDemain = @"LBHTTPClient.errorDomain";
static NSString *const kLBSenzLeancloudHostURlString  = @"http://api.trysenz.com";
static NSString *const kLBSenzAuthIDString = @"5548eb2ade57fc001b000001938f317f306f4fc254cdc7becb73821a";


typedef NS_ENUM(NSInteger, HTTPClientErrorType) {
    HTTPClientErrorTypeNetworkLost = -1,
    HTTPClientErrorTypeDeviceInfoError = -2
};


NSError * ErrorWithType(HTTPClientErrorType type)
{
    
    NSError *error = nil;
    switch (type) {
        case HTTPClientErrorTypeNetworkLost: {
            error = [NSError errorWithDomain:LBHTTPClientErrorDemain code:type userInfo:@{@"reason":@"network was lost"}];
            break;
        }
        case HTTPClientErrorTypeDeviceInfoError: {
            error = [NSError errorWithDomain:LBHTTPClientErrorDemain code:type userInfo:@{@"reason":@"device info use to create installation error "}];
            break;
        }
        default: {
            break;
        }
    }
    
    return error;
}



@interface LBHTTPClient ()

@end


@implementation LBHTTPClient

+ (LBHTTPClient *)sharedClient
{
    if (![LBInstallation installationAvaliable]) {
        static LBHTTPClient *_fakeClient = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _fakeClient = [[LBHTTPClient alloc] init];
        });
        return _fakeClient;
    }
    
    return [self leancloudClientWithInstallation:[LBInstallation sharedInstance]];
}

+ (LBHTTPClient *)leancloudClientWithInstallation:(LBInstallation *)installation;
{
    static LBHTTPClient *__sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedManager = [[self alloc] initWithBaseURL:[NSURL URLWithString:kLBSenzLeancloudHostURlString]];
        __sharedManager.requestSerializer = [LBLeancloudRequestSerializer leancloudSerializerWithInstallation:installation];
    });
    return __sharedManager;
}

- (void)initializeClientWithDelegate:(id<LBHTTPClientDelegate>)delegate appID:(NSString *)appID
{
    self.delegate = delegate;
    if ([LBInstallation installationAvaliable]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate HTTPClientDidInitializedWithInfo:nil];
        });
        return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused"

    NSString *hardwareId = [[LBDeviceInfoManager sharedInstance] hardwareID];
    NSString *deviceType = @"ios";
    
    NSDictionary *param =   @{
                              @"hardwareId":hardwareId,
                              
                              @"appid":[appID copy],
                              @"deviceType":deviceType
                              };

    [self queryInstallationWithDevitionInfo:param];
#pragma clang diagnostic pop

}

#pragma mark - Create Installation ID 
/// 仅首次安装时初始化Tracker时需要, 故直接写一个请求,不做封装.
- (void)queryInstallationWithDevitionInfo:(NSDictionary *)param
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api.trysenz.com/utils/exchanger/createInstallation"]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:30.0f];
    [request setValue:kLBSenzAuthIDString forHTTPHeaderField:@"X-senz-Auth"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:NULL];
    [request setHTTPBody:data];
    
    __weak typeof(self) weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            if(!connectionError && [data length] > 0){
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
                if (!dict[@"error"] && dict[@"result"]) {
                    LBInstallation *installation = [[LBInstallation alloc] initWithDictionary:dict[@"result"]];
                    [installation saveToDisk];
                    [LBLogger logString:[NSString stringWithFormat:@"installation : %@", [installation JSONRepesentation]] toFile:@"installation"];
                    if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(HTTPClientDidInitializedWithInfo:)]) {
                        [strongSelf.delegate HTTPClientDidInitializedWithInfo:@{@"installation":installation}];
                    }
                }else{
                    if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(HTTPClientDidFailToInitializeWithError:)]) {
                        [strongSelf.delegate HTTPClientDidFailToInitializeWithError:ErrorWithType(HTTPClientErrorTypeDeviceInfoError)];
                    }
                }
            }else{
                if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(HTTPClientDidFailToInitializeWithError:)]) {
                    [strongSelf.delegate HTTPClientDidFailToInitializeWithError:ErrorWithType(HTTPClientErrorTypeNetworkLost)];
                }
            }
        }
    }];
}



#pragma mark - Upload 


+ (void)uploadLocationRecord:(LBLocationRecord *)locationRecord
                   onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                   onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock;

{
    [[self sharedClient] uploadLocationRecord:locationRecord onSuccess:successBlock onFailure:failedBlock];
}

/*
 
 curl -X POST \
 -H "X-AVOSCloud-Application-Id: 9ra69chz8rbbl77mlplnl4l2pxyaclm612khhytztl8b1f9o" \
 -H "X-AVOSCloud-Application-Key: 1zohz2ihxp9dhqamhfpeaer8nh1ewqd9uephe9ztvkka544b" \
 -H "Content-Type: application/json" \
 -d '{"timestamp":14020304000,"installation": {"__type":"Pointer","className":"_Installation",
 "objectId":"l68QQ3Ownwra3HYgWvDJLDW7Hfje7MBh"},"type":"location","source": "baidu.location_sdk",
 "locationRadius": 60.479766845703125,"location":{"__type":"GeoPoint","latitude":1,"longitude":2}}'  \
 https://api.leancloud.cn/1.1/classes/Log

 
 */
- (void)uploadLocationRecord:(LBLocationRecord *)locationRecord
                   onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                   onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock;

{

    NSDictionary *param = @{@"timestamp":@([locationRecord.timestamp timeIntervalSince1970] * 1000),
                            @"type":@"location",
                            @"source":@"internal",
                            @"locationRadius":@(locationRecord.horizontalAccuracy),
                            @"location":[locationRecord JSONRepresentation]};
    
    [self POST:@"/data/Log"
    parameters:param
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
           NSDictionary *resp = (NSDictionary * )responseObject;
           NSString *log = [NSString stringWithFormat:@"location.success: %@ , %@", resp[@"createdAt"],resp[@"objectId"]];
           [LBLogger logString:log toFile:kLBHTTPClientLogFile];
           if (successBlock) {
               successBlock(operation, responseObject);
           }
    }
       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           NSString *log = [NSString stringWithFormat:@"location.error: %@ ", error];
           [LBLogger logString:log toFile:kLBHTTPClientLogFile];
           if (failedBlock) {
               failedBlock(operation, error);
           }
    }];
    
}



+ (void)uploadSensorRecords:(NSArray *)sensorRecords
                  onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                  onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock;
{
    [[self sharedClient] uploadSensorRecords:sensorRecords
                                   onSuccess:successBlock
                                   onFailure:failedBlock];

}


/*
 
 curl -X POST   -H "X-AVOSCloud-Application-Id: 9ra69chz8rbbl77mlplnl4l2pxyaclm612khhytztl8b1f9o"   -H "X-AVOSCloud-Application-Key: 1zohz2ihxp9dhqamhfpeaer8nh1ewqd9uephe9ztvkka544b"   -H "Content-Type: application/json"   -d '{"timestamp":14020304000,"installation":{"__type":"Pointer",
 "className":"_Installation",
 "objectId":"l68QQ3Ownwra3HYgWvDJLDW7Hfje7MBh"} ,"type":"sensor","value":{ "events": [{"timestamp":2874573193298,"accuracy": 2,"sensorName": "acc","values": [-7.8747406005859375,5.423065185546875,2.5889434814453125]}]}}'    https://api.leancloud.cn/1.1/classes/Log
 
 */
- (void)uploadSensorRecords:(NSArray *)sensorRecords
                  onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                  onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock;
{

    
    NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:[sensorRecords count]];
    [sensorRecords enumerateObjectsUsingBlock:^(LBSenserRecord* obj, NSUInteger idx, BOOL *stop) {
        [JSONArray addObject:[obj JSONRepresentation]];
    }];
    
    NSDictionary *param = @{@"timestamp":@([[NSDate date] timeIntervalSince1970] *1000),
                            @"type":@"sensor",
                            @"value":@{
                                    @"events":JSONArray
                                    }};
    
    [self POST:@"/data/Log"
    parameters:param
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
           NSDictionary *resp = (NSDictionary * )responseObject;
           NSString *log = [NSString stringWithFormat:@"senser.success: %@ , %@", resp[@"createdAt"],resp[@"objectId"]];
           [LBLogger logString:log toFile:kLBHTTPClientLogFile];
           if (successBlock) {
               successBlock(operation, responseObject);
           }
       }
       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           NSString *log = [NSString stringWithFormat:@"sensor.error: %@ ", error];
           [LBLogger logString:log toFile:kLBHTTPClientLogFile];
           if (failedBlock) {
               failedBlock(operation, error);
           }
       }];
}



+ (void)batchLocationRecords:(NSArray *)locations
                  onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                   onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock
{
    [[self sharedClient] batchLocationRecords:locations onSuccess:successBlock onFailure:failedBlock];
}



/*
 curl -X POST  -H "X-senz-Auth:5548eb2ade57fc001b0000010be762a58ac542706a8b817428d9766e" -H "Content-Type:application/json"  -d '{
 "requests": [
 {
 "method": "POST",
 "path": "/1.1/classes/Log",
 "body": {
 "OneObjectKey":"value1"
 }
 },
 {
 "method": "POST",
 "path": "/1.1/classes/Log",
 "body": {
 "AnotherObjectKey":"value2"
 }
 }
 ]
 }' http://api.trysenz.com/log/batch
 */

- (void)batchLocationRecords:(NSArray *)locations
                   onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                   onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api.trysenz.com/log/batch"]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:15.0f];
    [request setValue:@"5548eb2ade57fc001b0000010be762a58ac542706a8b817428d9766e" forHTTPHeaderField:@"X-senz-Auth"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableArray *bodys = [NSMutableArray array];
    [locations enumerateObjectsUsingBlock:^(LBLocationRecord* locationRecord, NSUInteger idx, BOOL *stop) {
        if ([locationRecord isKindOfClass:[LBLocationRecord class]]) {
            NSDictionary *param = @{
                                    @"method": @"POST",
                                    @"path":@"/1.1/classes/Log",
                                    @"body":@{
                                        @"timestamp":@([locationRecord.timestamp timeIntervalSince1970] * 1000),
                                        @"type":@"location",
                                        @"source":@"internal",
                                        @"locationRadius":@(locationRecord.horizontalAccuracy),
                                        @"location":[locationRecord JSONRepresentation],
                                        @"installation":[[LBInstallation sharedInstance] JSONRepesentation]
                                    }};
            [bodys addObject:param];
        }
    }];
    
    NSDictionary *finalParam = @{@"requests":bodys};
    NSData *data = [NSJSONSerialization dataWithJSONObject:finalParam options:NSJSONWritingPrettyPrinted error:NULL];
    [request setHTTPBody:data];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            if(!connectionError && [data length] > 0){
                NSArray *resultArray = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
                if ([resultArray count]) {
                    [LBLogger logString:@"send pending locations success." toFile:kLBHTTPClientLogFile];
                    if (successBlock) {
                        successBlock(nil,nil);
                    }
                }else{
                    [LBLogger logString:@"send pending locations error " toFile:kLBHTTPClientLogFile];
                    if (failedBlock) {
                        failedBlock(nil,nil);
                    }
                }
            }else{
                [LBLogger logString:@"send pending locations error " toFile:kLBHTTPClientLogFile];
                if (failedBlock) {
                    failedBlock(nil,nil);
                }
            }
        }
    }];
}



+ (void)uploadCMActivityRecords:(NSArray *)activitys
                      onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                      onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock
{
    [[self sharedClient] uploadCMActivityRecords:activitys onSuccess:successBlock onFailure:failedBlock];
}

- (void)uploadCMActivityRecords:(NSArray *)activitys
                  onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                  onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock
{
    
    NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:[activitys count]];
    [activitys enumerateObjectsUsingBlock:^(CMMotionActivity* obj, NSUInteger idx, BOOL *stop) {
        [JSONArray addObject:[obj JSONRepresentation]];
    }];
    
    NSDictionary *param = @{@"timestamp":@([[NSDate date] timeIntervalSince1970] *1000),
                            @"type":@"cmActivitys",
                            @"value":@{
                                    @"activitys":JSONArray
                                    }};
    
    [self POST:@"/data/Log"
    parameters:param
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
           NSDictionary *resp = (NSDictionary * )responseObject;
           NSString *log = [NSString stringWithFormat:@"upload coremotion activitys success: %@ , %@", resp[@"createdAt"],resp[@"objectId"]];
           [LBLogger logString:log toFile:kLBHTTPClientLogFile];
           if (successBlock) {
               successBlock(operation, responseObject);
           }
       }
       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           NSString *log = [NSString stringWithFormat:@"upload coremotion activitys error : %@ ", error];
           [LBLogger logString:log toFile:kLBHTTPClientLogFile];
           if (failedBlock) {
               failedBlock(operation, error);
           }
       }];

}







@end
