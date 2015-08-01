//
//  LBHTTPClient.h
//  LBTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>

@class LBLocationRecord;
@class LBHTTPClient;

@protocol LBHTTPClientDelegate <NSObject>

- (void)HTTPClientDidInitializedWithInfo:( __unused NSDictionary  *)info;

- (void)HTTPClientDidFailToInitializeWithError:(NSError *)error;

@end


@interface LBHTTPClient : AFHTTPRequestOperationManager

@property (nonatomic, weak) id<LBHTTPClientDelegate> delegate;

+ (LBHTTPClient *)sharedClient;

- (void)initializeClientWithDelegate:(id<LBHTTPClientDelegate>)delegate appID:(NSString *)appID;

+ (void)uploadLocationRecord:(LBLocationRecord *)locationRecord
                    onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                    onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock;


+ (void)uploadSensorRecords:(NSArray *)sensorRecords
                  onSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
                  onFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failedBlock;


@end
