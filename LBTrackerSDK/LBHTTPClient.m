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

NSString *const LBHTTPClientErrorDemain = @"LBHTTPClient.errorDomain";
static NSString *const kLBSenzLeancloudHostURlString  = @"https://api.leancloud.cn";
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
                    NSLog(@"installation : %@", [installation JSONRepesentation]);
                    [installation saveToDisk];
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
    
    __weak typeof(self) weakSelf = self;
    [self POST:@"1.1/classes/Log"
    parameters:param
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
           NSLog(@"success ");
           NSDictionary *resp = (NSDictionary * )responseObject;
           NSString *log = [NSString stringWithFormat:@"location.success: %@ , %@", resp[@"createdAt"],resp[@"objectId"]];
           [weakSelf logStringToFile:log];

           if (successBlock) {
               successBlock(operation, responseObject);
           }
    }
       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           NSLog(@"fail");
           NSLog(@"upload location error ");
           NSString *log = [NSString stringWithFormat:@"location.error: %@ ", error];
           [weakSelf logStringToFile:log];
           if (failedBlock) {
               failedBlock(operation, error);
           }
           
//           [[LBDataCenter sharedInstance] pushPendingLocationRecord:locationRecord];
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
    
    __weak typeof(self) weakSelf = self;
    [self POST:@"1.1/classes/Log"
    parameters:param
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
           NSLog(@"success ");
           NSDictionary *resp = (NSDictionary * )responseObject;
           NSString *log = [NSString stringWithFormat:@"senser.success: %@ , %@", resp[@"createdAt"],resp[@"objectId"]];
           [weakSelf logStringToFile:log];
           if (successBlock) {
               successBlock(operation, responseObject);
           }
       }
       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           
           NSLog(@"upload sensor error ");
           NSString *log = [NSString stringWithFormat:@"sensor.error: %@ ", error];
           [weakSelf logStringToFile:log];
           if (failedBlock) {
               failedBlock(operation, error);
           }
       }];
}





- (void)logStringToFile:(NSString *)stringToLog
{
    NSLog(@"%@", stringToLog);
    
    NSString * logFileName = [NSString stringWithFormat:@"%@.log", @"LocationTracker"];
    
    NSDateFormatter * dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    }
    
    stringToLog = [NSString stringWithFormat:@"%@ --- INFO: %@\n", [dateFormatter stringFromDate:[NSDate date]], stringToLog];
    
    //Get the file path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:logFileName];
    
    //Create file if it doesn't exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileName])
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
    
    //Append text to file (you'll probably want to add a newline every write)
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    [file seekToEndOfFile];
    [file writeData:[stringToLog dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}





@end
